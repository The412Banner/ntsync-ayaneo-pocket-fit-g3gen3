# ntsync for the AYANEO (KONKR) Pocket FIT — Snapdragon G3 Gen 3

Adds the Linux `ntsync` driver (backported from Linux 6.17) to the Pocket FIT's stock Android 14 kernel. Wine/Proton apps can then use `/dev/ntsync` for faster Windows-style synchronization.

**Only for:** AYANEO (KONKR) Pocket FIT, Snapdragon G3 Gen 3, stock Android 14 (kernel `6.1.75-android14-11`). On anything else the driver simply won't load.

## Option 1: Magisk (loads automatically on every boot)

1. Download `ntsync-pocket-fit-g3gen3-<version>.zip` from [Releases](../../releases).
2. Magisk → Modules → Install from storage → pick the zip → reboot.

Remove: Magisk → Modules → ntsync → Remove → reboot.

## Option 2: No Magisk (AYANEO Root Script)

1. Download `ntsync-pocket-fit-g3gen3-rootscript-<version>.zip` from [Releases](../../releases) and extract it. Keep both files in the same folder.
2. System Settings → Root Script → **+** → pick `ntsync-load.sh` → **Run**.
3. The result should end with `OK: /dev/ntsync is ready for apps`.

Run it again after every reboot. Remove: just reboot.

## Check

`/dev/ntsync` exists with mode `crw-rw-rw-`.

## Notes

- Built in CI against Android common kernel `android14-6.1-2024-05_r1` with the Pocket FIT's own kernel config; every imported symbol is checked against the device. `test/ntsync_test.py` tests the driver.
- Only change to the upstream driver: GKI 6.1 doesn't export `schedule_hrtimeout_range_clock()`, so it uses its own hrtimer.
- License: GPL-2.0-only (upstream driver © 2024 Elizabeth Figura).
