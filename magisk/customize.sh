SKIPUNZIP=0
KREL=$(uname -r)
case "$KREL" in
  6.1.*-android14-*) ui_print "- Kernel $KREL: android14-6.1 GKI" ;;
  *) abort "! This build is for android14-6.1 GKI kernels only (found $KREL)" ;;
esac
DEV=$(getprop ro.product.device)
if [ "$DEV" = "PocketFIT" ]; then
  ui_print "- Device: AYANEO Pocket FIT"
else
  ui_print "! Built for the AYANEO Pocket FIT (G3 Gen 3), this is '$DEV'."
  ui_print "! The driver will only load if the kernel KMI matches."
fi
set_perm "$MODPATH/ntsync.ko" 0 0 0644
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
