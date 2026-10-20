SKIPUNZIP=0
KREL=$(uname -r)
case "$KREL" in
  6.1.75-android14-11*) ui_print "- Kernel $KREL" ;;
  *) abort "! This build is for the Pocket FIT kernel 6.1.75-android14-11 only (found $KREL)" ;;
esac
DEV=$(getprop ro.product.device)
if [ "$DEV" = "PocketFIT" ]; then
  ui_print "- Device: AYANEO Pocket FIT"
else
  ui_print "! Built for the AYANEO Pocket FIT (G3 Gen 3), this is '$DEV'."
fi
ui_print "- The driver loads after boot has finished, never during boot."
ui_print "- If a load ever fails, the module turns itself off."
rm -f "$MODPATH/loading"
set_perm "$MODPATH/ntsync.ko" 0 0 0644
set_perm "$MODPATH/service.sh" 0 0 0755
