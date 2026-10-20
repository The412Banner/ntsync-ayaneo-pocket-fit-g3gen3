#!/system/bin/sh
# Load ntsync on the AYANEO (KONKR) Pocket FIT (Snapdragon G3 Gen 3) without Magisk.
# Run it with System Settings > Root Script. Keep ntsync.ko next to this script.
# The driver stays loaded until the next reboot.

DIR=$(cd "$(dirname "$0")" && pwd)
KO="$DIR/ntsync.ko"
KREL=$(uname -r)

echo "ntsync loader for AYANEO Pocket FIT (G3 Gen 3)"
echo "device: $(getprop ro.product.device), kernel: $KREL"

case "$KREL" in
  6.1.*-android14-*) ;;
  *) echo "FAILED: needs the stock Android 14 kernel (6.1 GKI)"; exit 1 ;;
esac
[ "$(getprop ro.product.device)" = "PocketFIT" ] || \
  echo "warning: built for the Pocket FIT; it only loads if the kernel matches"

if [ "$(id -u)" != 0 ]; then
  echo "FAILED: run this as root (System Settings > Root Script)"
  exit 1
fi

if [ -e /dev/ntsync ]; then
  echo "ntsync already loaded"
else
  if [ ! -f "$KO" ]; then
    echo "FAILED: ntsync.ko not found next to this script ($DIR)"
    exit 1
  fi
  insmod "$KO" || { echo "FAILED: insmod returned $?"; exit 1; }
  i=0
  while [ ! -e /dev/ntsync ] && [ $i -lt 20 ]; do sleep 0.1; i=$((i + 1)); done
fi

if [ ! -e /dev/ntsync ]; then
  echo "FAILED: /dev/ntsync did not appear"
  exit 1
fi

chmod 0666 /dev/ntsync
echo "OK: /dev/ntsync is ready for apps (until the next reboot)"
ls -l /dev/ntsync
