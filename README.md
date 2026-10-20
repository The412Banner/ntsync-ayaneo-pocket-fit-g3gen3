# ntsync for the AYANEO (KONKR) Pocket FIT — Snapdragon G3 Gen 3

The Linux `ntsync` driver (from Linux 6.17), backported as a loadable module for the **AYANEO (KONKR) Pocket FIT with the Snapdragon G3 Gen 3** on its stock Android 14 firmware.

`ntsync` gives Wine/Proton native Windows-style synchronization objects (semaphores, mutexes, events) through `/dev/ntsync`, instead of emulating them in user space.

Two ways to install:

| | Magisk module | Root Script (no Magisk) |
|---|---|---|
| Needs | Magisk | Nothing extra: uses AYANEO's built-in **System Settings → Root Script** |
| Loads at boot | Yes, automatically | No: run the script again after every reboot |
| Download | `ntsync-pocket-fit-g3gen3-<version>.zip` | `ntsync-pocket-fit-g3gen3-rootscript-<version>.zip` |

## Supported device

| | |
|---|---|
| Device | AYANEO (KONKR) Pocket FIT, Snapdragon G3 Gen 3 (SG8350P) |
| Firmware | Stock Android 14, build `01.00_20251226` |
| Kernel | `6.1.75-android14-11` (Android 14 GKI 6.1) |

The module is built against `android14-6.1-2024-05_r1` (6.1.75) using the Pocket FIT's own `/proc/config.gz`, and its symbol CRCs are taken from the device's vendor modules. It only loads on kernels with the same KMI. Other devices and other firmware builds are not supported: on a mismatched kernel the driver refuses to load and nothing else changes.

## Status

**Pre-release.** Tested by the author on a Pocket FIT G3 Gen 3 (stock Android 14): both the Magisk module and the Root Script load the driver, and `test/ntsync_test.py` passes from an app. CI builds the module and checks every imported symbol against the Pocket FIT's CRCs.

## Install with Magisk

1. Download `ntsync-pocket-fit-g3gen3-<version>.zip` from [Releases](../../releases).
2. Magisk → Modules → Install from storage → pick the zip.
3. Reboot. The driver now loads on every boot.

To remove: Magisk → Modules → ntsync → Remove, then reboot.

## Install without Magisk (Root Script)

1. Download `ntsync-pocket-fit-g3gen3-rootscript-<version>.zip` from [Releases](../../releases) and extract it. Keep `ntsync-load.sh` and `ntsync.ko` in the same folder.
2. Open **System Settings → Root Script**, tap **+**, pick `ntsync-load.sh`, then tap **Run**.
3. The result should end with `OK: /dev/ntsync is ready for apps`.

The driver stays loaded until the next reboot; run the script again after each restart. Running it while the driver is already loaded is harmless. To remove, just reboot.

## Check it works

```sh
ls -l /dev/ntsync
```

`/dev/ntsync` should exist with mode `crw-rw-rw-`. With Magisk, `/data/adb/modules/ntsync/ntsync.log` should say `insmod ok`.

`test/ntsync_test.py` checks semaphores, events, mutexes, wait-any/wait-all, monotonic and realtime timeouts, and signal interruption through `/dev/ntsync`.

## What gets installed

Magisk module:
- `post-fs-data.sh` loads `ntsync.ko`, makes `/dev/ntsync` readable and writable by apps, and labels it `ntsync_device`. Results go to `ntsync.log` in the module folder.
- `service.sh` re-applies the permissions once boot completes, in case ueventd recreated the node.
- `sepolicy.rule` lets apps open and use `/dev/ntsync`.

Root Script:
- `script/ntsync-load.sh` checks the kernel, loads `ntsync.ko` from its own folder and makes `/dev/ntsync` readable and writable by apps. Nothing is written to the system.

## Source changes

The only change to the upstream driver: GKI 6.1 doesn't export `schedule_hrtimeout_range_clock()`, so the module sleeps on its own hrtimer.

## Build

`.github/workflows/build.yml` fetches the Android common kernel at `android14-6.1-2024-05_r1`, configures it with `device.config`, writes `Module.symvers` from `device_crcs.json`, builds `ntsync.ko`, checks every import against the device CRCs and packages both zips.

## License

GPL-2.0-only, same as the upstream driver (Copyright (C) 2024 Elizabeth Figura). See `LICENSE`.
