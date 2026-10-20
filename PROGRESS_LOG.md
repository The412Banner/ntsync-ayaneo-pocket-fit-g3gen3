# Progress log

## Resume point
Branch `fix/post-boot-load`: Magisk module rebuilt to load only after boot. CI-green pending; NOT device-tested. Next: device test with the user's go (manual run of service.sh first, then install + reboot only if the user agrees).

## 2026-10-20 — Load only after boot (fix/post-boot-load, NOT device-tested)
**Why:** installing v1.0 via Magisk and rebooting left the Pocket FIT stuck in the bootloader FastBoot menu on every boot; the user had to factory reset. The driver had worked before when loaded by hand after boot.
**Findings:**
- Driver unchanged since Oct 12: `src/` and the Magisk scripts are identical between 6197e08 and 767e015; the Oct 12 CI build (run 38285662206) and the v1.0 `ntsync.ko` have byte-identical code/data sections.
- Live device: `/proc/config.gz` identical to `device.config`; all 35 imports exported by the running kernel; `sepolicy.rule` applies cleanly offline with magiskpolicy.
- So the new part on the day of the bootloop was the Magisk boot path: `sepolicy.rule` (merged at early init) and `insmod` in `post-fs-data.sh`. Which of the two failed is unproven; boot logs were lost in the wipe.
**Change:**
- Removed `magisk/sepolicy.rule` and `magisk/post-fs-data.sh`.
- `magisk/service.sh` waits for `sys.boot_completed` + 15 s, checks the kernel is `6.1.75-android14-11*`, writes a `loading` guard, insmods, and removes the guard after 60 s stable. A leftover guard on the next boot disables the module instead of loading.
- SELinux rules only applied live (`magiskpolicy --live`) and only when Enforcing; nothing persistent.
- `customize.sh` aborts on any other kernel release.
**Device test:** guard logic tested on the device with a fake insmod (leftover guard → `disable` created; normal run → guard cleared). Real load NOT tested yet.
**Recovery without wipe:** stock init_boot rebuilt from Magisk's backup at `/sdcard/Download/pocketfit-backup/stock_init_boot_a.img`; `fastboot boot` it to start without Magisk.

## Lessons learned (don't repeat these)
- v1.0 was released before the Magisk install path was ever tested on the device. Never release a boot-time module before it is device-proven.
- Nothing that can crash may run during early boot without a way to switch itself off.
