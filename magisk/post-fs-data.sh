#!/system/bin/sh
MODDIR=${0%/*}
LOG=$MODDIR/ntsync.log
{
  echo "== $(date) kernel $(uname -r)"
  if [ ! -e /dev/ntsync ]; then
    insmod "$MODDIR/ntsync.ko" && echo "insmod ok" || echo "insmod failed: $?"
  fi
  i=0
  while [ ! -e /dev/ntsync ] && [ $i -lt 20 ]; do sleep 0.1; i=$((i + 1)); done
  if [ -e /dev/ntsync ]; then
    chmod 0666 /dev/ntsync
    chcon u:object_r:ntsync_device:s0 /dev/ntsync 2>/dev/null || true
    ls -lZ /dev/ntsync
  else
    echo "/dev/ntsync missing"
  fi
} >> "$LOG" 2>&1
