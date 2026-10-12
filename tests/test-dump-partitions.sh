#!/usr/bin/env bash
# Tests scripts/dump-partitions.sh against a fake adb that serves the images
# in firmware/ as if they were /dev/block/rknand_* on a device.
#
#   bash tests/test-dump-partitions.sh

set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
FW=$ROOT/firmware
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/bin"

cat > "$T/bin/adb" <<EOF
#!/usr/bin/env bash
cmd="\$*"
case "\$cmd" in
    "shell test -b /dev/block/rknand_system && echo ok")
        [ -z "\${NO_NAND:-}" ] && echo ok ;;
    shell\ cat\ /sys/class/block/rknand_*)
        p=\${cmd#*rknand_}; p=\${p%%/*}
        [ -f "$FW/\$p.img" ] && echo \$(( \$(wc -c < "$FW/\$p.img") / 512 )) ;;
    exec-out\ dd\ if=/dev/block/rknand_*)
        p=\${cmd#*rknand_}; p=\${p%% *}
        \${TRUNCATE:-cat} "$FW/\$p.img" ;;
    *)
        echo "fake adb: unhandled: \$cmd" >&2; exit 1 ;;
esac
EOF
chmod +x "$T/bin/adb"

fails=0
check() {
    if [ "$2" = "$3" ]; then echo "PASS  $1"; else echo "FAIL  $1 (expected $3, got $2)"; fails=$((fails + 1)); fi
}
dump() {
    PATH="$T/bin:$PATH" bash "$ROOT/scripts/dump-partitions.sh" "$@" >"$T/log" 2>&1
    echo $?
}

check "dumps partitions" "$(dump "$T/a" parameter uboot resource kernel boot)" 0
for f in parameter uboot resource kernel boot; do
    expected=$(grep " $f.img\$" "$ROOT/SHA256SUMS" | cut -d' ' -f1)
    actual=$(sha256sum "$T/a/$f.img" | cut -d' ' -f1)
    check "$f.img matches SHA256SUMS" "$actual" "$expected"
done

check "fails without NAND driver" "$(NO_NAND=1 dump "$T/b")" 1
check "fails on unknown partition" "$(dump "$T/c" kernal)" 1
grep -q "partition 'kernal' not found" "$T/log"; check "reports unknown partition" $? 0
check "fails on truncated transfer" "$(TRUNCATE="head -c 1000" dump "$T/d" kernel)" 1
check "fails without arguments" "$(dump)" 2

echo
[ $fails -eq 0 ] && echo "All tests passed." || { echo "$fails test(s) failed."; exit 1; }
