# ntsync for the AYANEO (KONKR) Pocket FIT — Snapdragon G3 Gen 3

> [!WARNING]
> **Use at your own risk.** This loads a third-party kernel driver into your device's kernel. A bad kernel module can crash the device, stop it from booting, or force a factory reset with loss of all data. Back up your data first. This software comes with **no warranty** (GPL-2.0). By installing it, you accept that **all responsibility for any damage, data loss or other consequences lies entirely with you**. Not affiliated with or endorsed by AYANEO or KONKR.

**Test status on our device** (Pocket FIT G3 Gen 3, kernel `6.1.75-android14-11`, Magisk 30.7, SELinux Permissive):

| Release | Status |
|---|---|
| `v1.1` (Magisk) | **Tested, works** (2026-10-20): installs and reboots normally, driver loads after boot, driver tests pass, DiRT Showdown in Bannerlator runs on it. |
| `rootscript-v1.1` (Root Script) | **Not tested** as a script on our device. It contains the same driver code as v1.1. |

Other devices, kernels and SELinux Enforcing setups are not tested.

Adds the Linux `ntsync` driver (backported from Linux 6.17) to the Pocket FIT's stock Android 14 kernel. Wine/Proton apps can then use `/dev/ntsync` for faster Windows-style synchronization.

**Only for:** AYANEO (KONKR) Pocket FIT, Snapdragon G3 Gen 3, stock Android 14 (kernel `6.1.75-android14-11`). The Magisk installer refuses any other kernel; the Root Script only checks for a 6.1 Android 14 kernel.

## Option 1: Magisk (loads automatically after every boot)

1. Download `ntsync-pocket-fit-g3gen3-<version>.zip` from [Releases](../../releases).
2. Magisk → Modules → Install from storage → pick the zip → reboot.

The driver is loaded about 15 seconds after Android has finished booting, never during boot. If a load ever crashes or reboots the device, the next boot skips it and the module turns itself off (it shows as disabled in Magisk). The log is at `/data/adb/modules/ntsync/ntsync.log`.

Remove: Magisk → Modules → ntsync → Remove → reboot.


## Option 2: No Magisk (AYANEO Root Script)

1. Download `ntsync-pocket-fit-g3gen3-rootscript-<version>.zip` from [Releases](../../releases) and extract it. Keep both files in the same folder.
2. System Settings → Root Script → **+** → pick `ntsync-load.sh` → **Run**.
3. The result should show `OK: /dev/ntsync is ready for apps`.

Run it again after every reboot. Remove: just reboot.

## Check

`/dev/ntsync` exists with mode `crw-rw-rw-`.

## Using it with Wine/Proton

The Wine build has to support ntsync and be told to use it. The Proton 10 layers in proton-wine have no ntsync support and keep using esync.

- **Bannerlator:** use one of the v14 Proton 11 compatibility layers from [proton-wine](https://github.com/The412Banner/proton-wine/releases) and set **Sync** to **ntsync** (container or per game). The layer uses `/dev/ntsync` when it works and otherwise falls back to the userspace ntsync by Joshua Tam ([GameNative/ntsync-android](https://github.com/GameNative/ntsync-android)).
- **Other Wine builds:** set `WINENTSYNC=1` if the build needs it. In the Wine log, `ntsync: WINENTSYNC set, using kernel /dev/ntsync.` means the driver is in use.

## Tested

On a Pocket FIT G3 Gen 3 (kernel `6.1.75-android14-11`, Magisk 30.7, SELinux Permissive), 2026-10-20:

- v1.1 installed through Magisk and rebooted: Android booted normally, the driver loaded after boot, the 60 s guard cleared, `test/ntsync_test.py` passed every check, no kernel errors.
- DiRT Showdown in Bannerlator (DroidDeck-Proton 11.0-9.1 v14 layer, Sync = ntsync): Wine used the kernel driver (about 600 ntsync objects in the game, 2,600 in the wineserver, no esync), no crashes.

Not tested: a device with SELinux Enforcing (on the test device, SELinux logged the app's `ioctl` on `/dev/ntsync` as denied but allowed it because of Permissive; on Enforcing, `service.sh` adds rules that allow it). The Root Script option was not tested.

## Notes

- Built in CI against Android common kernel `android14-6.1-2024-05_r1` with the Pocket FIT's own kernel config; every imported symbol is checked against the device. `test/ntsync_test.py` tests the driver.
- Nothing runs during early boot and the module does not change the saved SELinux policy. With SELinux Enforcing, `service.sh` adds the app rules to the running policy only.
- Only change to the upstream driver: GKI 6.1 doesn't export `schedule_hrtimeout_range_clock()`, so it uses its own hrtimer.
- License: GPL-2.0-only (upstream driver © 2024 Elizabeth Figura).
