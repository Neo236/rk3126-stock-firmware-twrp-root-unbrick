# Dumping partitions

How to read partitions off a tablet, either to back up your own unit before modifying it or to contribute the pieces this
archive is still missing (a never-rooted `system`, stock `recovery`). This is how the images in this archive were made.

> [!IMPORTANT]
> Never publish `userdata`, `cache`, `misc` or `metadata`. They hold personal data: accounts, Wi-Fi passwords, app data.

## Option A: from TWRP over ADB (easiest)

Needs TWRP booted and the NAND module loaded ([twrp.md](twrp.md)). On the host:

```bash
bash scripts/dump-partitions.sh ./dump
```

By default it reads `uboot resource kernel boot recovery backup system`, streams each one with `adb exec-out dd` into `./dump/`,
and writes `SHA256SUMS` next to the files. Pass partition names to choose your own:

```bash
bash scripts/dump-partitions.sh ./dump system
```

If `adb exec-out` is not supported, dump to the SD card from the device instead:

```sh
dd if=/dev/block/rknand_system of=/external_sd/system.img bs=1M
```

`system` is 1.5 GiB raw. Most of it is free space, so it compresses well (`xz -9` or `7z`); always publish the hash of the
**uncompressed** image.

## Option B: Loader mode with Rockchip tools (gets `parameter` too)

`parameter` is not exposed as a block device in Android or TWRP. It can be read in Loader mode (`adb reboot bootloader`) by
sector number, using the values from [partition-layout.md](partition-layout.md):

```bash
rkdeveloptool rl 0x0     0x2000   parameter.raw     # parameter block
rkdeveloptool rl 0x94000 0x300000 system.img        # system
```

On Windows, RKDevTool's *Advanced Function → Export Image* takes the same start sector and count.

The `parameter` block starts with the ASCII magic `PARM`, a 4-byte length, then the plain-text `parameter` file. Keep the raw
4 MiB dump and also extract the text:

```bash
python3 -c "import struct,sys;d=open('parameter.raw','rb').read();n=struct.unpack('<I',d[4:8])[0];sys.stdout.write(d[8:8+n].decode())" > parameter.txt
```

## Verifying a dump

* The first bytes should match the magic in [image-formats.md](image-formats.md).
* `kernel`/`boot`/`resource`/`uboot` dumps from the same firmware should have the same SHA-256 as the ones in
  [`SHA256SUMS`](../SHA256SUMS). If they differ, your tablet runs a different build.
* `system` can be checked by mounting it read-only on Linux: `sudo mount -o ro,loop system.img /mnt` and looking at
  `/mnt/build.prop`.

## Note on `system` and privacy

A `system` dump from an unused or factory-reset device contains only the OEM firmware. If the tablet was rooted or had
system apps updated, check `/system/app`, `/system/priv-app` and `/system/xbin` for anything you added before publishing.
