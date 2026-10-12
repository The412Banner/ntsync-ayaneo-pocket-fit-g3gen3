# ntsync-android

The Linux `ntsync` driver (from Linux 6.17), backported as a loadable module for Android 14 GKI 6.1 kernels, packaged as a Magisk module.

Built against `android14-6.1-2024-05_r1` (6.1.75) using the AYANEO Pocket FIT's own `/proc/config.gz`. Symbol CRCs are taken from the device's vendor modules, so it only loads on kernels with the same KMI.

The only source change: GKI 6.1 doesn't export `schedule_hrtimeout_range_clock()`, so the module sleeps on its own hrtimer.

The Magisk module loads the driver at boot, makes `/dev/ntsync` readable and writable by apps, and adds an SELinux rule for app access.
