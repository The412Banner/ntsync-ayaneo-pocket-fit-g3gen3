#!/system/bin/sh
# ueventd may recreate the node with default permissions; fix it again once boot settles.
MODDIR=${0%/*}
until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 2; done
if [ -e /dev/ntsync ]; then
  chmod 0666 /dev/ntsync
  chcon u:object_r:ntsync_device:s0 /dev/ntsync 2>/dev/null || true
fi
