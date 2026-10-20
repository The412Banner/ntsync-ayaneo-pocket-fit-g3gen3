# ntsync for the AYANEO (KONKR) Pocket FIT — Snapdragon G3 Gen 3

Adds the Linux `ntsync` driver (backported from Linux 6.17) to the Pocket FIT's stock Android 14 kernel. Wine/Proton apps can then use `/dev/ntsync` for faster Windows-style synchronization.

**Only for:** AYANEO (KONKR) Pocket FIT, Snapdragon G3 Gen 3, stock Android 14 (kernel `6.1.75-android14-11`). The installer refuses any other kernel.

## Option 1: Magisk (loads automatically after every boot)

1. Download `ntsync-pocket-fit-g3gen3-<version>.zip` from [Releases](../../releases).
2. Magisk → Modules → Install from storage → pick the zip → reboot.

The driver is loaded about 15 seconds after Android has finished booting, never during boot. If a load ever crashes or reboots the device, the next boot skips it and the module turns itself off (it shows as disabled in Magisk). The log is at `/data/adb/modules/ntsync/ntsync.log`.

Remove: Magisk → Modules → ntsync → Remove → reboot.

**Device-tested:** v1.1 installed through Magisk 30.7 on a Pocket FIT G3 Gen 3 (kernel `6.1.75-android14-11`) and rebooted (2026-10-20). Android booted normally, the driver loaded after boot, the 60 s guard cleared, `test/ntsync_test.py` passed every check, and the kernel log showed no errors.

## Option 2: No Magisk (AYANEO Root Script)

1. Download `ntsync-pocket-fit-g3gen3-rootscript-<version>.zip` from [Releases](../../releases) and extract it. Keep both files in the same folder.
2. System Settings → Root Script → **+** → pick `ntsync-load.sh` → **Run**.
3. The result should end with `OK: /dev/ntsync is ready for apps`.

Run it again after every reboot. Remove: just reboot.

## Check

`/dev/ntsync` exists with mode `crw-rw-rw-`.

## Notes

- Built in CI against Android common kernel `android14-6.1-2024-05_r1` with the Pocket FIT's own kernel config; every imported symbol is checked against the device. `test/ntsync_test.py` tests the driver.
- Nothing runs during early boot and the module does not change the saved SELinux policy. With SELinux Enforcing, `service.sh` adds the app rules to the running policy only.
- Only change to the upstream driver: GKI 6.1 doesn't export `schedule_hrtimeout_range_clock()`, so it uses its own hrtimer.
- License: GPL-2.0-only (upstream driver © 2024 Elizabeth Figura).
