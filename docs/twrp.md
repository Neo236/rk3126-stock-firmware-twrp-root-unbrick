# TWRP on rknand

## About the image

| | |
|---|---|
| File | `twrp.img` (5,684,593 bytes) |
| Version | TWRP **3.1.0-0** (`ro.twrp.version`) |
| Format | `KRNL`-wrapped gzip cpio ramdisk (no kernel; uses the device's `kernel` partition) |
| Target partition | `recovery` (32 MiB) |
| Origin | Distributed as `recovery_twrp_3.1.0-0+Tablet+Altroconsumo+2017.rar` in the HTCMania thread [*[Hilo Oficial] Tablet OCU 2017 [RK3126]*](https://www.htcmania.com/archive/index.php/t-1311448.html), posted by **iflashed** on 2017-04-30. The name points to a port made for the *Altroconsumo 2017* tablet, another RK3126 clone. The person who built the port is not credited in the thread. |

The ramdisk ships NAND driver modules for several kernel versions, which is why it works on many Rockchip boards:

```
rk30xxnand_ko.ko.3.0.8+
rk30xxnand_ko.ko.3.0.36+
rk30xxnand_ko.ko.3.10.0     <- the one this board needs
```

It also bundles a SuperSU installer under `/supersu/`. See [root.md](root.md).

> [!CAUTION]
> **Known bug (reported in the source thread):** a plain *Wipe → Factory Reset* in this build also wipes `system`, leaving the
> tablet unbootable until `system` is restored. To wipe only user data, use *Advanced Wipe* and tick **Data** only.
> Always take a TWRP backup of `system` first.

## The `insmod` quirk

The kernel on this board has no built-in NAND driver: the stock Android ramdisk loads `rk30xxnand_ko.ko.3.10.0` during boot.
In the author's session TWRP did not do this on its own, so after booting into it:

* `/proc/partitions` is empty or lists only `zram`/`mmcblk` (SD card)
* every NAND mount fails, and backups/wipes do nothing

Fix, from `adb shell` inside TWRP:

```sh
insmod /rk30xxnand_ko.ko.3.10.0
ls /dev/block/rknand_*
```

Or run the helper, which is idempotent and waits for the nodes to appear:

```bash
adb push scripts/twrp-init-nand.sh /tmp/
adb shell sh /tmp/twrp-init-nand.sh
```

After that, TWRP's GUI **Mount** and **Backup** screens work normally.

> [!CAUTION]
> Do not run `cat /proc/mtd` (or tools that read it) with this driver loaded. On this board it causes an immediate kernel
> panic and reboot. Use `/proc/partitions` and `/dev/block/rknand_*` instead.

## TWRP's fstab

Taken from `/etc/recovery.fstab` inside the image (abridged):

| Mount point | Type | Device |
|---|---|---|
| `/boot` | emmc (raw) | `/dev/block/rknand_boot` |
| `/kernel` | emmc (raw) | `/dev/block/rknand_kernel` |
| `/resource` | emmc (raw) | `/dev/block/rknand_resource` |
| `/recovery` | emmc (raw) | `/dev/block/rknand_recovery` |
| `/misc` | emmc (raw) | `/dev/block/rknand_misc` |
| `/backup` | emmc (raw) | `/dev/block/rknand_backup` |
| `/system` | ext4 | `/dev/block/rknand_system` |
| `/data` | ext4 | `/dev/block/rknand_userdata` |
| `/cache` | ext4 | `/dev/block/rknand_cache` |
| `/metadata` | ext4 | `/dev/block/rknand_metadata` |
| `/radical_update` | ext4 | `/dev/block/rknand_radical_update` |
| `/external_sd` | vfat | `/dev/block/mmcblk0p1` |

`emmc` here is just TWRP's name for "raw partition"; the storage really is NAND.

`default.prop` in the image sets `ro.secure=0`, `ro.debuggable=1` and `service.adb.root=1`, so `adb shell` inside TWRP is root.

## Flashing it

This board's U-Boot (`2014.10-RK3126`) implements **both** USB protocols, so there are two ways in. You can tell which mode the
tablet is in by which tool sees it: `fastboot devices` vs. AndroidTool's *"Found One LOADER Device"*.

### Fastboot

The U-Boot image contains a fastboot implementation with `oem unlock` support (strings `rk_fastboot`, `fastboot_unlocked`,
`oem unlock_accept`), and it validates the recovery image before writing it. The maintainer recalls flashing this way:

```bash
adb reboot bootloader
fastboot oem unlock      # may need to be confirmed; not needed if already unlocked
fastboot flash recovery twrp.img
fastboot reboot
```

Uses the regular Google ADB/fastboot driver on Windows.

### Rockusb / Loader mode (AndroidTool, RKDevTool)

The method from the source thread, and the one that still works when Android won't boot:

1. Install Rockchip's `DriverAssistant`, open AndroidTool / RKDevTool.
2. Enter Loader mode (*Reboot to bootloader* from the stock recovery, or hold the recovery key while plugging in USB).
3. Untick everything except `parameter` and `recovery`; point `recovery` at `twrp.img`; *Run*.

On Linux/macOS, [`rkdeveloptool`](https://github.com/rockchip-linux/rkdeveloptool) writes the same sectors:

```bash
rkdeveloptool wl 0x1A000 twrp.img
rkdeveloptool rd
```

### From a rooted Android

```sh
su -c "dd if=/sdcard/twrp.img of=/dev/block/rknand_recovery"
```

## Booting into TWRP

`adb reboot recovery`, or with the tablet off hold **Vol−** + **Power** until the recovery appears (combo from the source
thread; it may differ on other clones).
