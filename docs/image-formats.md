# Image formats

All values below were read directly from the released files. Checksums are in [`SHA256SUMS`](../SHA256SUMS).

Rockchip uses three small container formats on top of the usual Android one. Recognising them by their first bytes avoids
flashing the wrong file to the wrong partition.

| File | Magic (offset 0) | Container |
|---|---|---|
| `parameter.img` | `50 41 52 4D` (`PARM`) | Rockchip parameter block |
| `uboot.img` | `4C 4F 41 44 45 52 20 20` (`LOADER  `) | Rockchip U-Boot loader image |
| `resource.img` | `52 53 43 45` (`RSCE`) | Rockchip resource image |
| `kernel.img` | `4B 52 4E 4C` (`KRNL`) | Rockchip KRNL wrapper |
| `boot.img` | `41 4E 44 52 4F 49 44 21` (`ANDROID!`) | Android boot image v0 |
| `twrp.img` | `4B 52 4E 4C` (`KRNL`) | Rockchip KRNL wrapper |
| `system.img` | ext4 superblock at 0x400 (`53 EF`) | Raw ext4 filesystem |

---

## `KRNL` wrapper (`kernel.img`, `twrp.img`)

```
offset  size  field
0x00    4     "KRNL"
0x04    4     payload length (little-endian)
0x08    n     payload
0x08+n  4     CRC
```

* **`kernel.img`** — payload is 6,977,536 bytes, an ARM zImage (`0x016F2818` at payload offset `0x24`). The rest of the
  12 MiB dump is zero padding.
* **`twrp.img`** — payload is 5,684,581 bytes of **gzip-compressed cpio** (a ramdisk, no kernel). This is the classic layout for
  Rockchip recovery partitions of this era: the bootloader loads the kernel from the separate `kernel` partition and the
  ramdisk from `recovery`.

Unpack a `KRNL` ramdisk:

```bash
# strip the 8-byte header; gzip ignores the trailing CRC with a warning
tail -c +9 twrp.img | gzip -dc > ramdisk.cpio
mkdir ramdisk && cd ramdisk && cpio -idm < ../ramdisk.cpio
```

## Android boot image (`boot.img`)

Standard v0 header, **16 KiB page size**:

| Field | Value |
|---|---|
| kernel size / load addr | 6,977,536 / `0x60408000` |
| ramdisk size / load addr | 1,486,792 / `0x62000000` |
| second size / load addr | 96,768 / `0x60F00000` |
| tags addr | `0x60088000` |
| page size | 16,384 |
| name / cmdline | empty (the cmdline comes from `parameter`) |

* The **kernel** inside `boot.img` is byte-identical to the payload of `kernel.img`.
* The **second stage** is itself an `RSCE` resource image (it carries the device tree).
* The **ramdisk** (gzip cpio) contains `rk30xxnand_ko.ko.3.10.0`, `drmboot.ko` and the `fstab.rk30board.*` files.

Any Android boot-image tool that supports a 16 KiB page size can unpack it (e.g. `unpackbootimg`, AIK, `magiskboot`).

## `RSCE` resource image (`resource.img`)

A small table of named entries in 512-byte blocks:

| Entry | Offset | Size |
|---|---|---|
| `rk-kernel.dtb` | 1,536 | 79,895 |
| `logo.bmp` | 81,920 | 14,720 |

`logo.bmp` is the boot logo. Swapping it is the usual way to change the splash screen on these devices.

## `LOADER` image (`uboot.img`)

Rockchip-signed 2nd-stage loader. Version string inside the image:

```
U-Boot 2014.10-RK3126-10-gcfab8f9-dirty (Jun 06 2016 - 16:03:15)
```

That timestamp matches `loader.timestamp=2016-06-06_16:03:15` in the kernel command line, which confirms the dump comes from the
same unit. This is **not** the MaskROM MiniLoader (`*.bin`) used by RKDevTool to talk to a dead board.

## `PARM` parameter block (`parameter.img`)

Raw 4 MiB dump of sectors `0x0`–`0x1FFF`.

```
offset  size  field
0x00    4     "PARM"
0x04    4     text length (little-endian) = 760
0x08    n     parameter text (CRLF line endings)
0x08+n  4     CRC
```

The block is stored **8 times**, every 512 KiB (`0x00000`, `0x80000`, … `0x380000`). All 8 copies in this dump are identical.
The extracted text is [`device/parameter.txt`](../device/parameter.txt).

## `system.img`

Raw dump of the 1.5 GiB `system` partition. ext4, 4 KiB blocks, 393,216 blocks (about 960 MiB used), volume label `system`,
state *clean*.

`e2fsck -fn` reports one finding: `Inode 7, i_size is 264302592, should be 268505088`. Inode 7 is the reserved
resize inode, and this mismatch is a common side effect of how Android's `make_ext4fs` builds images. It doesn't affect use.
Don't "fix" it on the published image, because that would change the hash.

### This is not a pristine factory `system`

The dump was taken **after rooting**. Comparing file timestamps against the 2016-08-31 build date, these are the only
regular files that differ from factory:

| Path | What it is |
|---|---|
| `/system/xbin/su`, `/system/xbin/daemonsu`, `/system/bin/.ext/.su`, `/system/xbin/.tmpsu` | SuperSU 2.82 `su` (armv7, matches the official zip) |
| `/system/xbin/supolicy`, `/system/lib/libsupol.so` | SuperSU 2.82 SELinux policy patcher |
| `/system/xbin/sugote`, `/system/xbin/sugote-mksh` | from the older SuperSU bundled in TWRP |
| `/system/bin/app_process32` → `/system/xbin/daemonsu` | symlink; the stock binary is kept as `app_process32_original` |
| `/system/bin/app_process_init` | copy of the stock `app_process32` |
| `/system/etc/install-recovery.sh` (+ symlink in `/system/bin`) | SuperSU's daemon launcher (the factory image had none) |
| `/system/etc/.installed_su_daemon` | marker file |
| `/system/app/SuperSU/SuperSU.apk` | **28 KiB stub** from TWRP, not the full app |
| `/system/app/Maps/Maps.apk`, `/system/app/YouTube/YouTube.apk` | timestamps only: the installer moves them out and back to free space |

Everything else is untouched OEM firmware. No accounts, Wi-Fi networks or user apps: those live in `userdata`, which is
not published. `build.prop` inside the image is byte-identical to [`device/build.prop`](../device/build.prop).

Inspect it on Linux without mounting:

```bash
debugfs -R "ls -l /xbin" system.img
debugfs -R "cat /build.prop" system.img
```
