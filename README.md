# ntsync for the AYANEO (KONKR) Pocket FIT — Snapdragon G3 Gen 3

The Linux `ntsync` driver (from Linux 6.17), backported as a loadable module for the **AYANEO (KONKR) Pocket FIT with the Snapdragon G3 Gen 3** on its stock Android 14 firmware, packaged as a Magisk module.

`ntsync` gives Wine/Proton native Windows-style synchronization objects (semaphores, mutexes, events) through `/dev/ntsync`, instead of emulating them in user space.

## Supported device

| | |
|---|---|
| Device | AYANEO (KONKR) Pocket FIT, Snapdragon G3 Gen 3 (SG8350P) |
| Firmware | Stock Android 14, build `01.00_20251226` |
| Kernel | `6.1.75-android14-11` (Android 14 GKI 6.1) |
| Root | Magisk |

The module is built against `android14-6.1-2024-05_r1` (6.1.75) using the Pocket FIT's own `/proc/config.gz`, and its symbol CRCs are taken from the device's vendor modules. It only loads on kernels with the same KMI. Other devices and other firmware builds are not supported: on a mismatched kernel the driver refuses to load and nothing else changes.

## Status

**Pre-release.** Tested by the author on a Pocket FIT G3 Gen 3 (stock Android 14) after it was built. CI builds the module and checks every imported symbol against the Pocket FIT's CRCs.

## Install

1. Download `ntsync-pocket-fit-g3gen3-<version>.zip` from [Releases](../../releases).
2. Magisk → Modules → Install from storage → pick the zip.
3. Reboot.

## Check it works

```sh
su -c 'ls -lZ /dev/ntsync; cat /data/adb/modules/ntsync/ntsync.log'
```

`/dev/ntsync` should exist with mode `crw-rw-rw-` and the log should say `insmod ok`.

`test/ntsync_test.py` checks semaphores, events, mutexes, wait-any/wait-all, monotonic and realtime timeouts, and signal interruption through `/dev/ntsync`.

## Uninstall

Magisk → Modules → ntsync → Remove, then reboot.

## What the module does

- `post-fs-data.sh` loads `ntsync.ko`, makes `/dev/ntsync` readable and writable by apps, and labels it `ntsync_device`. Results go to `ntsync.log` in the module folder.
- `service.sh` re-applies the permissions once boot completes, in case ueventd recreated the node.
- `sepolicy.rule` lets apps open and use `/dev/ntsync`.

## Source changes

The only change to the upstream driver: GKI 6.1 doesn't export `schedule_hrtimeout_range_clock()`, so the module sleeps on its own hrtimer.

## Build

`.github/workflows/build.yml` fetches the Android common kernel at `android14-6.1-2024-05_r1`, configures it with `device.config`, writes `Module.symvers` from `device_crcs.json`, builds `ntsync.ko`, checks every import against the device CRCs and packages the Magisk zip.

## License

GPL-2.0-only, same as the upstream driver (Copyright (C) 2024 Elizabeth Figura). See `LICENSE`.
