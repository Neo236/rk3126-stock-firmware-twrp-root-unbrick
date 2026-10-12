# Publishing (maintainer notes)

Where each part lives:

| What | Where | Why |
|---|---|---|
| Docs, scripts, `device/`, `SHA256SUMS` | Git repository | Small text, worth versioning |
| `boot-kit.zip` + `system.zip` | GitHub Release assets | Up to 2 GiB per file, doesn't bloat Git history |
| Same zips + loose images | Internet Archive item | Permanent mirror, per-file download, survives the GitHub repo |

Git LFS is not worth it here: it has a small free quota and LFS files don't show up in GitHub's source archives.

## Names and search keywords

People find firmware by searching for the SoC, the board string, the brand on the box and the problem ("unbrick", "stock
rom"). GitHub search weighs the repo **name**, **description**, **topics** and README; Google mostly the README title and text.
So:

* **Repo name:** `rk3126-stock-firmware-twrp-root-unbrick`. Short enough to type, covers the 5 main searches. Brands and the
  Android version go in the description and topics, where there's room.
* **Description** (max 350 chars), **topics** (max 20) and **release title**: see the commands below.
* Avoid putting "pre-rooted" in the name: 5 of the 6 partitions are untouched factory dumps, only `system` is rooted. The
  README and release notes say that explicitly.

## 1. Build the release archives

```bash
python scripts/make_release.py
```

Produces in `dist/`:

* `rk3126-tablet_PC-LMY48Y-20160831-boot-kit.zip` (~20 MB)
* `rk3126-tablet_PC-LMY48Y-20160831-system.zip` (~525 MB)
* `SHA256SUMS-archives`

It refuses to build if any image doesn't match `SHA256SUMS`.

## 2. GitHub

```bash
git add .
git commit -m "Initial import: RK3126 tablet_PC LMY48Y firmware, TWRP and docs"
gh repo create rk3126-stock-firmware-twrp-root-unbrick --public --source . --push \
  --description "Rockchip RK3126 tablet (rk30sdk, Android 5.1.1 LMY48Y) full stock firmware dump, TWRP and SuperSU root guide. Unbrick with RKDevTool. Emerson EM756 / Polaroid / X-View clones."
gh repo edit --add-topic rockchip,rk3126,rk312x,rk30sdk,android,android-5,lollipop,firmware,stock-rom,firmware-dump,twrp,root,supersu,unbrick,rkdevtool,nand,tablet,emerson,polaroid,preservation

gh release create v1.0.0 \
  dist/rk3126-tablet_PC-LMY48Y-20160831-boot-kit.zip \
  dist/rk3126-tablet_PC-LMY48Y-20160831-system.zip \
  dist/SHA256SUMS-archives \
  SHA256SUMS \
  --title "v1.0.0 — RK3126 tablet_PC LMY48Y (2016-08-31): full stock dump + TWRP" \
  --notes-file docs/release-notes-v1.0.0.md
```

The README links already point to `github.com/Neo236/rk3126-stock-firmware-twrp-root-unbrick`; change them if you pick another
repo name.

## 3. Internet Archive

Needs a free archive.org account and the CLI (`pip install internetarchive`, then `ia configure`).

Identifiers are permanent and global. Suggested: `rk3126-tablet-pc-lmy48y-stock-firmware-20160831`.

```bash
ia upload rk3126-tablet-pc-lmy48y-stock-firmware-20160831 \
  dist/rk3126-tablet_PC-LMY48Y-20160831-boot-kit.zip \
  dist/rk3126-tablet_PC-LMY48Y-20160831-system.zip \
  firmware/parameter.img firmware/uboot.img firmware/resource.img firmware/kernel.img firmware/boot.img firmware/twrp.img \
  SHA256SUMS README.md README.es.md LEGAL.md device/build.prop device/cmdline.txt device/parameter.txt \
  --metadata="mediatype:software" \
  --metadata="collection:open_source_software" \
  --metadata="title:Rockchip RK3126 Tablet (rk30sdk) Android 5.1.1 LMY48Y - Full Stock Firmware Dump, TWRP & Root" \
  --metadata="date:2016-08-31" \
  --metadata="creator:Rockchip / OEM (tablet_PC)" \
  --metadata="subject:rockchip;rk3126;rk312x;rk30sdk;android 5.1.1;lollipop;stock rom;firmware dump;unbrick;twrp;supersu;root;rkdevtool;Emerson EM756;Polaroid;X-View;tablet_PC" \
  --metadata="description:Full partition dump (parameter, uboot, resource, kernel, boot, system) of a generic Rockchip RK3126 tablet, build tablet_PC_2016-08-31 / LMY48Y, Android 5.1.1. All partitions are factory except system, which includes SuperSU 2.82. Also includes TWRP 3.1.0 for rknand. Documentation and checksums: https://github.com/Neo236/rk3126-stock-firmware-twrp-root-unbrick" \
  --metadata="language:eng"
```

The loose small images let people grab a single partition without downloading a zip. `system.img` goes in only as a zip
(the raw 1.5 GiB is mostly empty space). New items take minutes to hours to appear.

Published item: <https://archive.org/details/rk3126-tablet-pc-lmy48y-stock-firmware-20160831>.

## 4. Optional

* **Software Heritage:** save the Git repo at <https://archive.softwareheritage.org/save/> so the docs are archived too.
* **Wayback Machine:** save the GitHub repo and release pages at <https://web.archive.org/save>.
* **Forums:** a short post on XDA, 4PDA or the HTCMania RK3126 thread, linking both mirrors, is where people searching for
  this firmware will actually look.

## Before publishing: checklist

- [ ] `python scripts/make_release.py --check` passes
- [ ] No `userdata`, `cache`, `misc` or `metadata` dumps anywhere in the upload
- [ ] `system.img` contains no personal data (checked: only SuperSU files differ from factory)
- [ ] Links in `README.md` / `README.es.md` updated after both uploads
