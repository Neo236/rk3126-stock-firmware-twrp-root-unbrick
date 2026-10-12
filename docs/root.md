# Rooting with SuperSU

Android 5.1.1 (API 22) with SELinux **enforcing**. On this API level SuperSU installs in **system mode**: `su` is a client that
talks to a `daemonsu` started early in boot. If the daemon isn't running, or no manager app answers the request, `su` exits
with status 1 even though the binary is there. That is the usual failure on these tablets.

## Method A — TWRP's built-in installer (verified on this unit)

The TWRP image in this archive carries its own SuperSU installer at `/supersu/install-supersu.sh`. It is Chainfire's
installer script adapted to read files from `/supersu` instead of a zip, and it does the complete API 22 install:
`su`/`daemonsu`/`supolicy`/`libsupol.so` with the right modes and SELinux labels, the `app_process32` → `daemonsu` hook,
`/system/etc/install-recovery.sh` (+ symlink in `/system/bin`), and `su --install`.

What it doesn't provide is a usable manager app: `/supersu/Superuser.apk` is a 28 KiB stub. Without the full app, `su` requests
are never answered and fail with exit code 1. So the procedure has two halves.

### 1. In TWRP

```bash
adb reboot recovery
adb push scripts/twrp-init-nand.sh /tmp/
adb shell sh /tmp/twrp-init-nand.sh        # loads the NAND driver
adb shell sh /supersu/install-supersu.sh   # mounts /system and /data itself
adb reboot
```

The script prints its progress (`- Placing files`, `- Post-installation script`, `- Done !`). Messages about missing
`Maps.apk`/`YouTube.apk` or `chattr` are harmless.

### 2. In Android

Install the full SuperSU app from `SuperSU-v2.82-201705271822.zip` (file `common/Superuser.apk`, about 6 MB):

```bash
adb install -r Superuser.apk
```

Open SuperSU and set:

* **Settings → Superuser access:** *Apps and ADB*
* **Settings → Default access:** *Grant*

### Verify

```bash
adb shell su -c id
# uid=0(root) gid=0(root) ...
```

Root survived reboots on the author's unit.

### Notes from the session

After running the installer, a few extra commands were also run by hand: `chmod 06755 /system/xbin/su`,
`ln -sf /system/xbin/su /system/bin/su`, and rewriting `install-recovery.sh` to just launch `daemonsu --auto-daemon &`. The
installer already handles all three (it uses mode `0755`, places `/system/bin/.ext/.su`, and installs its own
`install-recovery.sh` with the same daemon line). They didn't break anything, but they aren't needed. The step that fixed
the exit-code-1 problem was installing the full app.

## Shortcut — flash the rooted `system.img`

The `system.img` in this archive already has the result of Method A applied (SuperSU 2.82 binaries, `app_process32` hook,
SELinux labels). Writing it to `system` and then doing only **step 2** above (install the full app, set access) gives the
same result without running the installer. This replaces your whole `system` partition: take a TWRP backup first.

## Method B — official SuperSU 2.82 zip (untested here)

Chainfire's last official zip should also work, as long as the NAND driver is loaded first so the installer can mount
`/system`:

```bash
adb shell sh /tmp/twrp-init-nand.sh
adb push SuperSU-v2.82-201705271822.zip /tmp/
adb shell twrp install /tmp/SuperSU-v2.82-201705271822.zip
```

The HTCMania thread for the OCU 2017 tablet (also RK3126, same TWRP) reports success with SuperSU 2.79 flashed from TWRP's
*Install* screen.

SuperSU is proprietary freeware and is **not** redistributed here. The copy used for this archive:

```
4ecc40e78a1b38b5e50d1f149858503b46d5e88e2a59d8dc63b83a334c22fd13  SuperSU-v2.82-201705271822.zip
```

## No working touchscreen?

The SuperSU settings above need taps. Use a USB OTG mouse, or `adb shell input tap X Y` with coordinates taken from
`adb exec-out screencap -p > s.png` (remember the screen is rotated: `ro.sf.hwrotation=270`).

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `su` exits 1, no prompt | Only the stub app is installed, or Superuser access excludes ADB. Install the full APK and check settings. |
| `su` exits 1 after a reboot | `daemonsu` not running: `adb shell ps \| grep daemonsu`. Re-run the installer. |
| Installer: can't mount `/system` | NAND module not loaded. Run `twrp-init-nand.sh` first. |
| Boot loop after install | Restore `system` from a TWRP backup taken before rooting. |

## Alternatives (untested on this board)

* **Magisk v25.2** is the last release supporting Android 5.x and would patch `boot.img` instead of `/system`. The 16 KiB page
  size and the separate `kernel` partition are untested with it.
