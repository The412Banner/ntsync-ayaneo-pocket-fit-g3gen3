#!/system/bin/sh
# Loads ntsync only after Android has finished booting. Nothing in this module
# runs during early boot, so a failed load can never stop the device from booting.
MODDIR=${0%/*}
LOG=$MODDIR/ntsync.log
GUARD=$MODDIR/loading
KREL_WANT=6.1.75-android14-11

until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 2; done
# Let the boot be marked successful before touching the kernel.
sleep 15

{
  echo "== $(date) kernel $(uname -r)"

  # The last load attempt never finished (the device crashed or rebooted during
  # insmod). Turn the module off instead of trying again.
  if [ -e "$GUARD" ]; then
    echo "previous load did not finish; disabling module"
    rm -f "$GUARD"
    touch "$MODDIR/disable"
    exit 0
  fi

  case "$(uname -r)" in
    "$KREL_WANT"*) ;;
    *) echo "kernel is not $KREL_WANT*; not loading"; exit 0 ;;
  esac

  if [ ! -e /dev/ntsync ]; then
    touch "$GUARD"
    sync
    insmod "$MODDIR/ntsync.ko" && echo "insmod ok" || echo "insmod failed: $?"
  fi

  i=0
  while [ ! -e /dev/ntsync ] && [ $i -lt 20 ]; do sleep 0.1; i=$((i + 1)); done
  if [ ! -e /dev/ntsync ]; then
    echo "/dev/ntsync missing"
    rm -f "$GUARD"
    exit 0
  fi
  chmod 0666 /dev/ntsync

  # Enforcing SELinux only: add the app rules to the running policy. These are
  # not saved anywhere and are gone after a reboot.
  if [ "$(getenforce)" = Enforcing ]; then
    magiskpolicy --live \
      "type ntsync_device" \
      "typeattribute ntsync_device dev_type" \
      "typeattribute ntsync_device mlstrustedobject" \
      "allow appdomain ntsync_device chr_file { getattr open read write ioctl }" \
      && chcon u:object_r:ntsync_device:s0 /dev/ntsync
  fi
  ls -lZ /dev/ntsync

  # A crash in the first minute after loading also counts as a failed load.
  if [ -e "$GUARD" ]; then
    sleep 60
    rm -f "$GUARD"
    sync
    echo "stable for 60s"
  fi
} >> "$LOG" 2>&1
