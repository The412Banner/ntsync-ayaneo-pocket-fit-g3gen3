import ctypes, fcntl, os, struct, threading, time, errno, sys

def IOC(d, t, nr, size): return (d << 30) | (size << 16) | (ord(t) << 8) | nr
W, R, WR = 1, 2, 3
CREATE_SEM   = IOC(W,  'N', 0x80, 8)
SEM_RELEASE  = IOC(WR, 'N', 0x81, 4)
WAIT_ANY     = IOC(WR, 'N', 0x82, 40)
WAIT_ALL     = IOC(WR, 'N', 0x83, 40)
CREATE_MUTEX = IOC(W,  'N', 0x84, 8)
MUTEX_UNLOCK = IOC(WR, 'N', 0x85, 8)
CREATE_EVENT = IOC(W,  'N', 0x87, 8)
EVENT_SET    = IOC(R,  'N', 0x88, 4)
SEM_READ     = IOC(R,  'N', 0x8b, 8)
MUTEX_READ   = IOC(R,  'N', 0x8c, 8)

libc = ctypes.CDLL(None, use_errno=True)
def ioctl(fd, req, buf):
    r = libc.ioctl(fd, ctypes.c_ulong(req), buf)
    return r if r >= 0 else -ctypes.get_errno()

def create(dev, req, a, b):
    buf = ctypes.create_string_buffer(struct.pack('<II', a, b), 8)
    return ioctl(dev, req, buf)

def wait(dev, req, fds, timeout_ns, owner=0, realtime=False):
    arr = (ctypes.c_uint32 * len(fds))(*fds)
    buf = ctypes.create_string_buffer(struct.pack('<QQIIIIII', timeout_ns, ctypes.addressof(arr), len(fds), 0xffffffff, 1 if realtime else 0, owner, 0, 0), 40)
    r = ioctl(dev, req, buf)
    return r, struct.unpack_from('<I', buf.raw, 20)[0]

mono = lambda: time.clock_gettime_ns(time.CLOCK_MONOTONIC)
real = lambda: time.clock_gettime_ns(time.CLOCK_REALTIME)
fails = 0
def check(name, ok, info=''):
    global fails
    fails += not ok
    print(('PASS ' if ok else 'FAIL ') + name + (' ' + info if info else ''))

dev = os.open('/dev/ntsync', os.O_RDWR | os.O_CLOEXEC)
check('open /dev/ntsync', dev >= 0)

sem = create(dev, CREATE_SEM, 0, 2)
check('create semaphore', sem >= 0, f'fd={sem}')

t0 = mono(); r, _ = wait(dev, WAIT_ANY, [sem], t0 + 100_000_000); dt = (mono() - t0) / 1e6
check('timeout (monotonic, 100 ms)', r == -errno.ETIMEDOUT and 95 <= dt < 300, f'ret={r} {dt:.1f} ms')

t0 = real(); m0 = mono(); r, _ = wait(dev, WAIT_ANY, [sem], t0 + 80_000_000, realtime=True); dt = (mono() - m0) / 1e6
check('timeout (realtime, 80 ms)', r == -errno.ETIMEDOUT and 75 <= dt < 300, f'ret={r} {dt:.1f} ms')

r, _ = wait(dev, WAIT_ANY, [sem], 0)
check('zero timeout returns at once', r == -errno.ETIMEDOUT, f'ret={r}')

def release_later():
    time.sleep(0.05)
    ioctl(sem, SEM_RELEASE, ctypes.byref(ctypes.c_uint32(1)))
threading.Thread(target=release_later).start()
t0 = mono(); r, idx = wait(dev, WAIT_ANY, [sem], t0 + 2_000_000_000); dt = (mono() - t0) / 1e6
check('woken by another thread', r == 0 and idx == 0 and dt < 500, f'ret={r} index={idx} {dt:.1f} ms')

buf = ctypes.create_string_buffer(8); ioctl(sem, SEM_READ, buf)
check('semaphore count back to 0', struct.unpack('<II', buf.raw) == (0, 2), str(struct.unpack('<II', buf.raw)))

ev = create(dev, CREATE_EVENT, 1, 0)
ioctl(sem, SEM_RELEASE, ctypes.byref(ctypes.c_uint32(1)))
r, _ = wait(dev, WAIT_ALL, [sem, ev], mono() + 50_000_000)
check('wait-all blocks while event unset', r == -errno.ETIMEDOUT, f'ret={r}')
ioctl(ev, EVENT_SET, ctypes.byref(ctypes.c_uint32()))
r, _ = wait(dev, WAIT_ALL, [sem, ev], mono() + 50_000_000)
check('wait-all succeeds when both signaled', r == 0, f'ret={r}')

mtx = create(dev, CREATE_MUTEX, 0, 0)
r, _ = wait(dev, WAIT_ANY, [mtx], mono() + 50_000_000, owner=123)
r2, _ = wait(dev, WAIT_ANY, [mtx], mono() + 50_000_000, owner=123)
buf = ctypes.create_string_buffer(8); ioctl(mtx, MUTEX_READ, buf)
check('mutex recursive acquire', r == 0 and r2 == 0 and struct.unpack('<II', buf.raw) == (123, 2), str(struct.unpack('<II', buf.raw)))
r3, _ = wait(dev, WAIT_ANY, [mtx], mono() + 30_000_000, owner=456)
check('mutex blocks other owner', r3 == -errno.ETIMEDOUT, f'ret={r3}')

# Signal interrupts a wait cleanly.
import signal
signal.signal(signal.SIGUSR1, lambda *a: None)
tid = threading.get_native_id()
threading.Timer(0.05, lambda: signal.pthread_kill(threading.main_thread().ident, signal.SIGUSR1)).start()
t0 = mono(); r, _ = wait(dev, WAIT_ANY, [sem, ev] if False else [mtx], mono() + 1_000_000_000, owner=789); dt = (mono() - t0) / 1e6
check('wait interrupted by signal', r in (-errno.EINTR, -errno.ETIMEDOUT) , f'ret={r} {dt:.1f} ms')

for fd in (sem, ev, mtx): os.close(fd)
os.close(dev)
print('RESULT', 'ALL PASS' if not fails else f'{fails} FAILED', 'uid', os.getuid())
sys.exit(1 if fails else 0)
