Full partition dump of a working **Rockchip RK3126 `tablet_PC`** (`rk30sdk`, Android 5.1.1, build `LMY48Y`,
`tablet_PC_2016-08-31`), plus a TWRP 3.1.0-0 that boots on this board. Sold as Emerson EM756, Polaroid, X-View and others.

**Read the repository README (included in both zips) before flashing anything.** Check that your `build.prop` and
`/proc/cmdline` match.

### `boot-kit.zip` (~20 MB): factory partitions + TWRP

| File | Partition | State | SHA-256 |
|---|---|---|---|
| `parameter.img` | `parameter` | factory | `d35340dfcb30c3cfa2120452f42c567492a2dc2794bd492a58317aa042f4524c` |
| `uboot.img` | `uboot` | factory | `7e55fad0dc09b98f7487f6b32c3bc5a03c18db051f5b4bfc1e54ad4a8567d8ad` |
| `resource.img` | `resource` | factory | `67776d8422b85511244b8abace72381d9c69b05defb935c2bbf5e43ee1891292` |
| `kernel.img` | `kernel` | factory | `dcb8daedd42af56b6554014ddb00a4a05b34e898cfa01488dac1f32656df5ac9` |
| `boot.img` | `boot` | factory | `720562c76e4de9ca76811b91d52ffdd6c4ff2c48d70df2da73f96ed94cb5de1e` |
| `twrp.img` | `recovery` | third-party | `a088012dd75d2b2e1bf3f394ec0071561afe58b95f5550dd453a849c08a5d0f4` |

### `system.zip` (~525 MB): rooted system

| File | Partition | State | SHA-256 |
|---|---|---|---|
| `system.img` | `system` | stock + SuperSU 2.82 | `c5f96f8f2446e6ff187f9edd46b5532851dc4cdcce5dc4733be0d059a62668a1` |

`system.img` was dumped after rooting: stock Android 5.1.1 with SuperSU 2.82 installed in `/system`, nothing else changed and
no personal data. Root binaries are included, but the SuperSU app in `/system` is a 28 KiB stub, so on a wiped device install
the full SuperSU app over ADB before expecting `su` to work.

Both zips also include `SHA256SUMS`, `build.prop`, `cmdline.txt`, the real `parameter.txt` and the legal notes.

### Not included

A never-rooted factory `system`, stock `recovery`, and a RK312x MiniLoader for MaskROM. Contributions welcome.

### Reminders

* In TWRP, run `insmod /rk30xxnand_ko.ko.3.10.0` before anything else, and never read `/proc/mtd`.
* In this TWRP build a plain *Factory Reset* also wipes `system`. Use *Advanced Wipe → Data* only.

TWRP source: [HTCMania OCU 2017 thread](https://www.htcmania.com/archive/index.php/t-1311448.html) (iflashed, 2017).
