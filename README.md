# Rockchip RK3126 Tablet Stock Firmware, TWRP and Root (rk30sdk, Android 5.1.1)

[Leer en español](README.es.md)

Full partition dump of a generic Rockchip RK3126 tablet (`tablet_PC`, board `rk30sdk`, Android 5.1.1, build `LMY48Y`),
a TWRP recovery that boots on this board, and documentation for unbricking, backing up and rooting it.

This firmware was shipped under several brands. The build fingerprint identifies it as **Emerson EM756**, and it also
contains **Polaroid**, **X-View** and **Skyth-tek** identifiers.

> [!WARNING]
> Flashing images from a different firmware can permanently brick a NAND-based Rockchip device.
> Confirm your device matches [Compatibility](#compatibility) before flashing, and read [LEGAL.md](LEGAL.md).

## Downloads

Binaries are published as release assets, not stored in the repository:
[**Releases**](https://github.com/Neo236/rk3126-stock-firmware-twrp-root-unbrick/releases)

| Archive | Size | Contents |
|---|---|---|
| `rk3126-tablet_PC-LMY48Y-20160831-boot-kit.zip` | 20 MB | `parameter`, `uboot`, `resource`, `kernel`, `boot`, `twrp` |
| `rk3126-tablet_PC-LMY48Y-20160831-system.zip` | 525 MB | `system` |

| Image | Partition | Source | Description |
|---|---|---|---|
| `parameter.img` | `parameter` | Factory | Partition table and kernel cmdline ([text](device/parameter.txt)) |
| `uboot.img` | `uboot` | Factory | U-Boot 2014.10, supports Rockusb and fastboot |
| `resource.img` | `resource` | Factory | Boot logo and device tree |
| `kernel.img` | `kernel` | Factory | Linux 3.10.0 |
| `boot.img` | `boot` | Factory | Kernel and ramdisk |
| `system.img` | `system` | Factory + SuperSU 2.82 | See [note on system.img](#note-on-systemimg) |
| `twrp.img` | `recovery` | Third party | TWRP 3.1.0-0 ([origin](docs/twrp.md#about-the-image)) |

All images are raw, full-size partition dumps. Verify them before flashing:

```bash
sha256sum -c --ignore-missing SHA256SUMS
```

### Note on system.img

`system.img` was dumped after rooting. It is the factory system with SuperSU 2.82 installed in `/system`; no other files
were changed and it contains no personal data ([full list of changes](docs/image-formats.md#this-is-not-a-pristine-factory-system)).
The SuperSU app stored in `/system` is a 28 KiB stub, so on a device with wiped `userdata` the full SuperSU app must be
installed over ADB before `su` works ([details](docs/root.md)).

## Compatibility

Compare with `adb shell getprop` on your device. Full file: [device/build.prop](device/build.prop).

| Property | Value |
|---|---|
| `ro.build.display.id` | `tablet_PC_2016-08-31` |
| `ro.build.id` | `LMY48Y` |
| `ro.build.version.release` | `5.1.1` |
| `ro.build.fingerprint` | `Emerson/EM756/EM756:5.1.1/LMY48Y/jingy08311656:user/release-keys` |
| `ro.product.board` | `rk30sdk` |
| `ro.board.platform` | `rk312x` |
| `ro.fota.oem` | `skyth-tek-RK3126_5.1` |

The `mtdparts` value in your `/proc/cmdline` must also be identical to the one in [device/cmdline.txt](device/cmdline.txt).
If it differs, the device uses a different firmware and these images must not be flashed.

**Hardware:** Rockchip RK3126 (4x Cortex-A7, 32-bit), raw NAND storage through Rockchip's `rknand` driver (not eMMC),
Linux 3.10.0, U-Boot 2014.10. Partition layout: [docs/partition-layout.md](docs/partition-layout.md).

## Unbricking

With the device in Loader mode (`adb reboot bootloader`), RKDevTool or AndroidTool on Windows, or
[rkdeveloptool](https://github.com/rockchip-linux/rkdeveloptool) on Linux, can rewrite every partition:

1. Load `parameter.txt`.
2. Assign `uboot`, `resource`, `kernel`, `boot`, `recovery` (`twrp.img`) and `system` to their images.
3. Flash, then wipe `data` and `cache` from TWRP using *Advanced Wipe*.

This recovers soft bricks (boot loops, corrupted `system`, broken recovery). A device that only responds in MaskROM mode
also requires an RK312x MiniLoader, which is not included. The full restore procedure has not yet been tested end to end
with these files.

## TWRP

TWRP does not detect any partition until the NAND driver module is loaded. From `adb shell` in TWRP:

```sh
insmod /rk30xxnand_ko.ko.3.10.0
```

[scripts/twrp-init-nand.sh](scripts/twrp-init-nand.sh) loads the module and verifies the result.

> [!CAUTION]
> - Reading `/proc/mtd` with this driver causes a kernel panic.
> - In this TWRP build, *Factory Reset* also wipes `system`. Use *Advanced Wipe* and select only *Data*.

Installation methods and details: [docs/twrp.md](docs/twrp.md).

## Root

Tested on this device. In TWRP, after loading the NAND driver, run the bundled SuperSU installer:

```bash
adb shell sh /supersu/install-supersu.sh
```

Then boot Android and install the full SuperSU 2.82 app (`common/Superuser.apk` from `SuperSU-v2.82-201705271822.zip`):

```bash
adb install -r Superuser.apk
```

Step-by-step guide and troubleshooting: [docs/root.md](docs/root.md).

## Documentation

| Document | Contents |
|---|---|
| [docs/partition-layout.md](docs/partition-layout.md) | Partition table, offsets, sector conversion |
| [docs/image-formats.md](docs/image-formats.md) | Image headers, unpacking, changes in `system` |
| [docs/twrp.md](docs/twrp.md) | TWRP origin, installation, NAND driver |
| [docs/root.md](docs/root.md) | Rooting with SuperSU |
| [docs/dumping.md](docs/dumping.md) | Dumping partitions from a device |
| [device/README.md](device/README.md) | `build.prop`, kernel cmdline and `parameter` notes |
| [scripts/README.md](scripts/README.md) | Helper scripts, requirements and tests |

## Contributing

The following are not yet available. Contributions from an identical device are welcome, with their SHA-256:

- Factory `system` image that has never been rooted
- Factory `recovery` image
- RK312x MiniLoader for MaskROM recovery

## License

Documentation and scripts are licensed under the [MIT License](LICENSE). Firmware images belong to their respective
copyright holders and are not covered by this license; see [LEGAL.md](LEGAL.md).

## Support

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/V4I625QFV8)
