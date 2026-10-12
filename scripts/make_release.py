#!/usr/bin/env python3
"""Package firmware/ into release zips after verifying SHA256SUMS.

    python scripts/make_release.py            # -> dist/<PREFIX>-boot-kit.zip, dist/<PREFIX>-system.zip
    python scripts/make_release.py --check    # verify checksums only

Two archives so people who only need TWRP or the small partitions don't
download 1.5 GiB. Both are self-describing (README, LEGAL, SHA256SUMS,
device/ metadata), so they stay useful if found on their own.
"""

import argparse
import hashlib
import sys
import zipfile
from pathlib import Path

PREFIX = "rk3126-tablet_PC-LMY48Y-20160831"
ROOT = Path(__file__).resolve().parent.parent
FIRMWARE = ROOT / "firmware"
DOCS = ["SHA256SUMS", "README.md", "README.es.md", "LEGAL.md", "LICENSE",
        "device/*", "docs/*.md", "scripts/*"]
ARCHIVES = {
    "boot-kit": ["parameter.img", "uboot.img", "resource.img", "kernel.img",
                 "boot.img", "twrp.img"],
    "system": ["system.img"],
}


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def read_sums():
    sums = {}
    for line in (ROOT / "SHA256SUMS").read_text().splitlines():
        if line.strip():
            digest, name = line.split(maxsplit=1)
            sums[name.lstrip("*")] = digest
    return sums


def verify(sums):
    ok = True
    for name, digest in sums.items():
        path = FIRMWARE / name
        if not path.is_file():
            print(f"MISSING  {name}")
            ok = False
        elif sha256(path) != digest:
            print(f"BAD      {name}")
            ok = False
        else:
            print(f"OK       {name}")
    return ok


def build(label, images):
    name = f"{PREFIX}-{label}"
    out = ROOT / "dist" / f"{name}.zip"
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for img in images:
            z.write(FIRMWARE / img, f"{name}/{img}")
        for pattern in DOCS:
            for path in sorted(ROOT.glob(pattern)):
                z.write(path, f"{name}/{path.relative_to(ROOT).as_posix()}")
    digest = sha256(out)
    print(f"{out.relative_to(ROOT)}  {out.stat().st_size:,} bytes  sha256 {digest}")
    return f"{digest}  {out.name}\n"


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--check", action="store_true", help="only verify checksums")
    ap.add_argument("--only", choices=ARCHIVES, help="build a single archive")
    args = ap.parse_args()

    sums = read_sums()
    packaged = {img for images in ARCHIVES.values() for img in images}
    if packaged != set(sums):
        sys.exit(f"SHA256SUMS and ARCHIVES disagree: {sorted(packaged ^ set(sums))}")
    if not verify(sums):
        sys.exit("checksum verification failed")
    if args.check:
        return

    (ROOT / "dist").mkdir(exist_ok=True)
    print()
    lines = [build(label, images) for label, images in ARCHIVES.items()
             if args.only in (None, label)]
    if args.only is None:
        (ROOT / "dist" / "SHA256SUMS-archives").write_text("".join(lines))


if __name__ == "__main__":
    main()
