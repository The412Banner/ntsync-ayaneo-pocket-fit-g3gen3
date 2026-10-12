SKIPUNZIP=0
KREL=$(uname -r)
case "$KREL" in
  6.1.*-android14-*) ui_print "- Kernel $KREL: android14-6.1 GKI" ;;
  *) abort "! This build is for android14-6.1 GKI kernels only (found $KREL)" ;;
esac
set_perm "$MODPATH/ntsync.ko" 0 0 0644
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
