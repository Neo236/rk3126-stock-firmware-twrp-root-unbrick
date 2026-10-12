# Scripts

| Script | Runs on | Requirements | Purpose |
|---|---|---|---|
| `twrp-init-nand.sh` | Device, inside TWRP | TWRP from this archive (provides `insmod` and the module) | Load the NAND driver so `/dev/block/rknand_*` appears |
| `dump-partitions.sh` | Host: Linux, macOS, or Git Bash on Windows | `bash`, `adb`, `sha256sum` | Dump partitions from a device booted into TWRP |
| `make_release.py` | Host | Python 3.7+, standard library only | Verify `SHA256SUMS` and build the release zips (maintainers) |

`adb` is part of Android SDK Platform-Tools: <https://developer.android.com/tools/releases/platform-tools>.

## Usage

```bash
adb push scripts/twrp-init-nand.sh /tmp/
adb shell sh /tmp/twrp-init-nand.sh

bash scripts/dump-partitions.sh ./dump                 # default: uboot resource kernel boot recovery backup system
bash scripts/dump-partitions.sh ./dump system boot     # selected partitions

python scripts/make_release.py --check                 # verify firmware/ against SHA256SUMS
python scripts/make_release.py                         # build dist/*.zip
```

`dump-partitions.sh` refuses to continue if the NAND driver isn't loaded, if a partition name doesn't exist, or if a dump's
size doesn't match the partition size. It warns before dumping partitions that hold personal data.

## Tests

The tests use a fake `adb` and a fake `/dev/block`, so no device is needed. They require the images in `firmware/`.

```bash
bash tests/test-dump-partitions.sh
sudo sh tests/test-twrp-init-nand.sh    # Linux only: creates block device nodes with mknod
```

The tests cover the scripts' logic. The commands they automate (`insmod`, `adb exec-out dd`) were used manually on the real
device, but the scripts themselves have not yet been run against physical hardware. Reports are welcome.
