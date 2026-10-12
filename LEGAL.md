# Legal notes

This repository is a **preservation archive** for an obsolete, unsupported consumer device. Its purpose is to let owners
back up, repair and keep using hardware that the manufacturer no longer supports.

## What the MIT license covers

Only the original work in this repository: the documentation (`README*`, `docs/`, `device/README.md`) and the scripts in
`scripts/`. See [LICENSE](LICENSE).

## What it does not cover

| Component | Owner / origin | License |
|---|---|---|
| `kernel.img`, kernel inside `boot.img` | Linux kernel 3.10, modified by Rockchip/OEM | GPL-2.0. The OEM never published the matching source. Rockchip's public RK312x 3.10 kernel trees are the closest available reference. |
| `uboot.img` | U-Boot 2014.10, modified by Rockchip | GPL-2.0+, plus Rockchip binary components |
| `rk30xxnand_ko.ko.*` (in `boot.img`, `twrp.img`) | Rockchip | Proprietary, binary-only |
| `boot.img` ramdisk, `resource.img` | AOSP (Apache-2.0) plus Rockchip/OEM files | Mixed |
| `system.img` | AOSP, Rockchip/OEM, Google apps (GMS) | Mixed; includes proprietary Google and OEM apps |
| SuperSU files inside `system.img` | Chainfire / CCMT | Proprietary freeware, installed in place by the rooting procedure |
| `parameter.img` | OEM | Configuration data |
| `twrp.img` | TeamWin Recovery Project 3.1.0, third-party Rockchip port | TWRP is GPL-3.0 ([source](https://github.com/TeamWin)). Obtained from the [HTCMania OCU 2017 thread](https://www.htcmania.com/archive/index.php/t-1311448.html) (posted by iflashed, 2017); the port's builder is not credited there. |
| SuperSU files inside `twrp.img` (`/supersu/`) | Chainfire / CCMT | Proprietary freeware |
| SuperSU zip | Chainfire / CCMT | Proprietary freeware. **Not redistributed** here; referenced by name and SHA-256 only. |

No copyright is claimed over any of these. They are redistributed unmodified, as dumped from a device the maintainer owns,
for interoperability, repair and archival purposes.

## Takedown

If you hold rights to any file here and want it removed, open an issue or contact the maintainer. It will be taken down from
GitHub and a removal request filed with the Internet Archive.

## No warranty

Flashing firmware can permanently damage a device. Everything here is provided **as is**, without warranty of any kind.
You are responsible for what you do with it.
