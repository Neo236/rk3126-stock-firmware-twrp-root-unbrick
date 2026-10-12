# Device metadata

| File | Source |
|---|---|
| `build.prop` | `/system/build.prop`, copied as-is (identical to the one inside `system.img`) |
| `cmdline.txt` | `/proc/cmdline` of the running unit |
| `parameter.txt` | Text payload of the `parameter` block, extracted from `parameter.img` (CRLF line endings kept) |

## `parameter.txt`

This is the real file, dumped from sector 0. Use it as-is with RKDevTool / AndroidTool / `upgrade_tool`.

```
FIRMWARE_VER:5.0.2
MACHINE_MODEL:rk312x
MACHINE_ID:007
MANUFACTURER:RK30SDK
MAGIC: 0x5041524B
ATAG: 0x60000800
MACHINE: 312x
CHECK_MASK: 0x80
KERNEL_IMG: 0x60408000
#RECOVER_KEY: 1,1,0,20,0
CMDLINE:console=ttyFIQ0 androidboot.baseband=N/A androidboot.hardware=rk30board androidboot.console=ttyFIQ0 init=/init initrd=0x62000000,0x00800000 mtdparts=rk29xxnand:...
```

Things worth knowing:

* `FIRMWARE_VER` says **5.0.2** even though the system is Android 5.1.1. The OEM never updated it. Don't use it to identify
  the build.
* `vmalloc=496M cma=4M rockchip_jtag`, which show up in `/proc/cmdline`, are **not** in `parameter`. They come from the
  device tree's `bootargs`. `storagemedia`, `uboot_logo` and `loader.timestamp` are appended by the loader. Comparing
  `cmdline.txt` with `parameter.txt` shows which part comes from where.
* `mtdparts` is identical in both, so the partition table in [docs/partition-layout.md](../docs/partition-layout.md) is exact.

Don't rebuild a `parameter` from `/proc/cmdline` and flash it. Before this dump existed, one was reconstructed that way using
typical SDK values, and compared with the real file it got `FIRMWARE_VER`, `MANUFACTURER`, `KERNEL_IMG`, `PWR_HLD` and the
cmdline wrong.

## Notes from `build.prop`

* Built 2016-08-31 by `jingy@thzy-0C`, `user` build, `release-keys`, security patch 2015-12-01.
* Brand strings from several resellers: fingerprint `Emerson/EM756`, `ro.com.google.clientidbase=android-polaroid`,
  `ro.rk.homepage_base=http://www.x-view.com`, `ro.fota.oem=skyth-tek-RK3126_5.1`.
* Default locale `es_ES`, timezone `America/Argentina/Buenos_Aires`: the build targeted the Spanish-speaking/Argentine market.
* `ro.adb.secure=0` and `persist.service.adb.enable=0`: ADB is off by default but needs no key authorisation once enabled.
