#!/usr/bin/env bash
# Dump raw NAND partitions from a tablet booted into TWRP (NAND module loaded).
# Runs on the host (Linux, macOS, or Git Bash on Windows).
#
#   bash scripts/dump-partitions.sh OUT_DIR [partition ...]
#
# Default partitions exclude anything with personal data
# (userdata, cache, misc, metadata).

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: $0 OUT_DIR [partition ...]" >&2
    exit 2
fi

out=$1
shift
if [ $# -gt 0 ]; then
    parts=("$@")
else
    parts=(uboot resource kernel boot recovery backup system)
fi

mkdir -p "$out"

# Older adbd (TWRP 3.1) does not forward exit codes, so check the output.
if ! adb shell "test -b /dev/block/rknand_system && echo ok" </dev/null | grep -q ok; then
    echo "ERROR: /dev/block/rknand_system not found. Boot TWRP and run twrp-init-nand.sh first." >&2
    exit 1
fi

for p in "${parts[@]}"; do
    case $p in
        userdata|cache|misc|metadata)
            echo "WARNING: $p may contain personal data. Do not publish it." >&2 ;;
    esac
    sectors=$(adb shell "cat /sys/class/block/rknand_$p/size 2>/dev/null" </dev/null | tr -d '\r') || true
    case $sectors in
        ''|*[!0-9]*)
            echo "ERROR: partition '$p' not found on the device" >&2
            exit 1 ;;
    esac

    echo "==> $p"
    adb exec-out "dd if=/dev/block/rknand_$p bs=1048576 2>/dev/null" </dev/null > "$out/$p.img"

    actual=$(wc -c < "$out/$p.img")
    if [ "$actual" -ne $((sectors * 512)) ]; then
        echo "ERROR: $p.img is $actual bytes, expected $((sectors * 512))" >&2
        exit 1
    fi
done

(cd "$out" && sha256sum -- *.img > SHA256SUMS)
echo
cat "$out/SHA256SUMS"
