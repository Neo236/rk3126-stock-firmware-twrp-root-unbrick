# Partition layout

Source: kernel command line ([`device/cmdline.txt`](../device/cmdline.txt)), read from `/proc/cmdline` on a running unit.

```
mtdparts=rk29xxnand:0x00002000@0x00002000(uboot),0x00002000@0x00004000(misc),...,-@0x003B4000(userdata)
```

Each entry is `size@offset(name)`. Both numbers are in **512-byte sectors** (Rockchip's LBA unit), so
`0x2000` sectors = 8192 × 512 B = 4 MiB.

The `parameter` block is not listed in `mtdparts`: it implicitly occupies sectors `0x0`–`0x1FFF`, before `uboot`.

| Partition | Offset (sectors) | Size (sectors) | Size (dec) | Starts at | Size | Block device |
|---|---|---|---|---|---|---|
| `parameter` | `0x00000000` | `0x00002000` | 8,192 | 0 MiB | 4 MiB | — |
| `uboot` | `0x00002000` | `0x00002000` | 8,192 | 4 MiB | 4 MiB | `rknand_uboot` |
| `misc` | `0x00004000` | `0x00002000` | 8,192 | 8 MiB | 4 MiB | `rknand_misc` |
| `resource` | `0x00006000` | `0x00008000` | 32,768 | 12 MiB | 16 MiB | `rknand_resource` |
| `kernel` | `0x0000E000` | `0x00006000` | 24,576 | 28 MiB | 12 MiB | `rknand_kernel` |
| `boot` | `0x00014000` | `0x00006000` | 24,576 | 40 MiB | 12 MiB | `rknand_boot` |
| `recovery` | `0x0001A000` | `0x00010000` | 65,536 | 52 MiB | 32 MiB | `rknand_recovery` |
| `backup` | `0x0002A000` | `0x00020000` | 131,072 | 84 MiB | 64 MiB | `rknand_backup` |
| `cache` | `0x0004A000` | `0x00040000` | 262,144 | 148 MiB | 128 MiB | `rknand_cache` |
| `metadata` | `0x0008A000` | `0x00008000` | 32,768 | 276 MiB | 16 MiB | `rknand_metadata` |
| `kpanic` | `0x00092000` | `0x00002000` | 8,192 | 292 MiB | 4 MiB | `rknand_kpanic` |
| `system` | `0x00094000` | `0x00300000` | 3,145,728 | 296 MiB | 1.5 GiB | `rknand_system` |
| `radical_update` | `0x00394000` | `0x00020000` | 131,072 | 1,832 MiB | 64 MiB | `rknand_radical_update` |
| `userdata` | `0x003B4000` | `-` (rest) | — | 1,896 MiB | rest of NAND | `rknand_userdata` |

Block device names come from the TWRP `recovery.fstab` and from the stock ramdisk, which use `/dev/block/rknand_<name>`.

## Converting for tools

| You need | Formula | Example (`system`) |
|---|---|---|
| Byte offset | `offset × 512` | `0x94000 × 512` = 310,378,496 |
| `dd` with `bs=512` | `skip=offset count=size` | `skip=606208 count=3145728` |
| RKDevTool / `rkdeveloptool rl` | sector values as-is | `rl 0x94000 0x300000 system.img` |

## Filesystems

| Partition | Content |
|---|---|
| `uboot`, `resource`, `kernel`, `boot`, `recovery` | raw images (see [image-formats.md](image-formats.md)) |
| `misc` | raw, bootloader control block (recovery commands) |
| `backup` | raw; on Rockchip SDKs often holds a copy of the update package — unverified on this unit |
| `system`, `cache`, `metadata`, `radical_update`, `userdata` | ext4 |
| `kpanic` | raw, kernel panic log |
