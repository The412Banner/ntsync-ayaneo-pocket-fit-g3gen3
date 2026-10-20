# Progress log

## Resume point
Release cleanup done (2026-10-20). Releases: `v1.1` (Magisk, Latest, tag 2e9496a) and `rootscript-v1.1` (Root Script, tag 60a8e02, CI run 39514494770). Git history not rewritten (user chose to skip it). Open: SELinux Enforcing untested; Root Script untested; no esync vs ntsync benchmark.

## 2026-10-20 — Release cleanup (fix/release-cleanup → main, docs + releases)
**Why:** user asked to remove every mention of the withdrawn first version from the repo.
**User decisions:** delete the old Magisk tag; rename the Root Script release to `rootscript-v1.1`, rebuilt by CI from current main; reword this log; do NOT rewrite git history (it would force-move the published v1.1 tag), so old commit messages stay.
**Plan:** README table → `rootscript-v1.1`; CI build of the merge commit; create `rootscript-v1.1` (not Latest) with the CI zip; back up and delete the old Root Script release + tag and the old Magisk tag.
**Done:**
- main 60a8e02 (fix/release-cleanup, ff; backup ref refs/backup/20261020/main-before-release-cleanup = 67b71d3). CI run 39514494770 (push, headSha 60a8e02, job build: success).
- Root Script zip from that run: script == main, `ntsync.ko` code/data identical to the previous Root Script build (only build-id and scmversion g60a8e02 differ). Published as `rootscript-v1.1` (target 60a8e02, not Latest), asset `ntsync-pocket-fit-g3gen3-rootscript-v1.1.zip` sha256 c88832d7…85ac5d — GitHub digest matches.
- Old Root Script release + tag deleted (backup: ~/.claude/projects/-root/ntsync-rootscript-first-release-backup/, zip sha256 00af9762…). Old Magisk tag deleted; commit 767e015 still kept by refs/backup/20261020/main-before-post-boot-load.
- Backup ref renamed to refs/backup/20261020/main-before-readme-warning-trim (= 65f0550); merged branch of the warning trim deleted (tip 664cacf is in main).
- Check: no tag, branch, ref, file on main or release text mentions the withdrawn version. Old commit messages still do (history kept).
**Device test:** none (docs/releases only). Root Script still NOT device-tested.

## 2026-10-20 — Disclaimer + test status (main, docs only)
- User asked: test status per release and a risk/responsibility disclaimer at the top of the README and in each release.
- README: warning block + status table at the top (fix/readme-disclaimer, ff-merged; backup ref refs/backup/20261020/main-before-readme-disclaimer = 9b8cb42). Earlier wording fix 9b8cb42 (backup main-before-readme-accuracy = 7d06756).
- Release notes edited: v1.1 "tested, works"; Root Script release "not tested" (no record of the script ever being run on the device). Tags (v1.1 2e9496a, Root Script 767e015) and assets unchanged. Old notes saved in ~/.claude/projects/-root/ntsync-release-notes-backup/.

## 2026-10-20 — Bannerlator uses the kernel driver (main, device-proven)
**Device test:** DiRT Showdown in Bannerlator, layer DroidDeck-Proton 11.0-9.1 v14 (proton-wine), Sync = ntsync.
- wine_debug.log: `ntsync: WINENTSYNC set, using kernel /dev/ntsync.`, no esync lines.
- While running: wineserver 2602 ntsync fds, showdown.exe 1 `/dev/ntsync` + 608 `anon_inode:ntsync`, 0 eventfds; module refcount 2602.
- logcat: no FATAL, crash buffer empty; dmesg: no oops/CFI. Two avc denials `ioctl` on `/dev/ntsync` (untrusted_app_27 → device:s0, permissive=1): Enforcing devices depend on the service.sh live rules (untested).
- Earlier esync runs: the stock Wine 11 path opened `/dev/ntsync` ("ntsync: up and running.") but games still used esync.
**Docs:** README gets "Using it with Wine/Proton" + "Tested" sections (branch fix/readme-device-tested, fast-forwarded to main at the user's request; backup ref refs/backup/20261020/main-before-readme-device-tested = c0fca3e). v1.1 release notes edited (tag 2e9496a and asset sha256 2a0aa419… unchanged).

## 2026-10-20 — v1.1 install + reboot on device (main, device-proven)
**Device test:** user installed v1.1 from /sdcard/Download/ntsync-pocket-fit-g3gen3-v1.1.zip (sha256 2a0aa419...326a, matches release) and rebooted. Boot reached Android normally.
- Installed /data/adb/modules/ntsync/ntsync.ko sha256 7172979b... and service.sh eedcbe04... == files in the v1.1 release zip.
- ntsync.log: `18:02:22 insmod ok`, `/dev/ntsync` crw-rw-rw- 10,115, `stable for 60s`; `loading` guard removed; `lsmod`: ntsync 49152 0.
- dmesg: no oops/panic/CFI lines. logcat crash buffer: nvkeeper (stack-protector abort, 18:02:02) and qcrosvm trustedvm (18:02:07), both before ntsync loaded. Same pair is in every boot's tombstones back to tombstone_00/01 (factory build, 2025-12-25), so stock behaviour, not ntsync.
- test/ntsync_test.py from the Termux app: ALL PASS.

## 2026-10-20 — Load only after boot (fix/post-boot-load, manual load device-proven; install NOT tested)
**Why:** installing the first Magisk build and rebooting left the Pocket FIT stuck in the bootloader FastBoot menu on every boot; the user had to factory reset. The driver had worked before when loaded by hand after boot.
**Findings:**
- Driver unchanged since Oct 12: `src/` and the Magisk scripts are identical between 6197e08 and 767e015; the Oct 12 CI build (run 38285662206) and the first Magisk build's `ntsync.ko` have byte-identical code/data sections.
- Live device: `/proc/config.gz` identical to `device.config`; all 35 imports exported by the running kernel; `sepolicy.rule` applies cleanly offline with magiskpolicy.
- So the new part on the day of the bootloop was the Magisk boot path: `sepolicy.rule` (merged at early init) and `insmod` in `post-fs-data.sh`. Which of the two failed is unproven; boot logs were lost in the wipe.
**Change:**
- Removed `magisk/sepolicy.rule` and `magisk/post-fs-data.sh`.
- `magisk/service.sh` waits for `sys.boot_completed` + 15 s, checks the kernel is `6.1.75-android14-11*`, writes a `loading` guard, insmods, and removes the guard after 60 s stable. A leftover guard on the next boot disables the module instead of loading.
- SELinux rules only applied live (`magiskpolicy --live`) and only when Enforcing; nothing persistent.
- `customize.sh` aborts on any other kernel release.
**Device test:** guard logic tested on the device with a fake insmod (leftover guard → `disable` created; normal run → guard cleared). Real load NOT tested yet.
- Step 1 (2026-10-20 17:11 EDT): CI build ebea17c `service.sh` run by hand as root from /data/local/tmp (not installed). insmod ok, `/dev/ntsync` crw-rw-rw- 10,115, guard cleared after 60 s ("stable for 60s"). `ntsync 49152 0 - Live (OE)`. dmesg during the run: no oops/warning/CFI lines (only permissive avc). logcat crash buffer empty. `test/ntsync_test.py` from the Termux app uid: ALL PASS (timeouts, wake, wait-all, mutex, signal).
- 2026-10-20: the first Magisk release was deleted at the user's request. Its tag was kept at 767e015 (deleted later in the release cleanup). Release notes + zip backed up to ~/.claude/projects/-root/ntsync-first-release-backup/ (local, not in the repo). The separate Root Script release (post-boot manual loader) stayed published.
- 2026-10-20: v1.1 released (Latest) at the user's request: merge 2e9496a on main (backup ref refs/backup/20261020/main-before-post-boot-load = 767e015), CI run 39498862107 success, tag v1.1 == 2e9496a, asset ntsync-pocket-fit-g3gen3-v1.1.zip sha256 2a0aa419... (driver code sections identical to the device-tested ebea17c build). README has no mention of the first build. Magisk install + reboot NOT device-tested at release.
**Recovery without wipe:** stock init_boot rebuilt from Magisk's backup at `/sdcard/Download/pocketfit-backup/stock_init_boot_a.img`; `fastboot boot` it to start without Magisk.

## Lessons learned (don't repeat these)
- The first Magisk build was released before the Magisk install path was ever tested on the device. Never release a boot-time module before it is device-proven.
- Nothing that can crash may run during early boot without a way to switch itself off.
