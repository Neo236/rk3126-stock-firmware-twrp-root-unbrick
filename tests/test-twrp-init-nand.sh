#!/bin/sh
# Tests the logic of scripts/twrp-init-nand.sh with a fake /dev/block and a
# fake insmod. Needs root on Linux (mknod creates block device nodes).
#
#   sudo sh tests/test-twrp-init-nand.sh

ROOT=$(cd "$(dirname "$0")/.." && pwd)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/dev/block" "$T/bin"

sed -e "s#MODULE=/rk30#MODULE=$T/rk30#" \
    -e "s#PROBE=/dev/block#PROBE=$T/dev/block#" \
    -e "s#ls /dev/block/#ls $T/dev/block/#" \
    -e 's#-lt 20#-lt 3#' \
    "$ROOT/scripts/twrp-init-nand.sh" > "$T/init.sh"

fails=0
check() {
    if [ "$2" = "$3" ]; then echo "PASS  $1"; else echo "FAIL  $1 (expected $3, got $2)"; fails=$((fails + 1)); fi
}
reset() {
    rm -f "$T"/dev/block/* "$T/rk30xxnand_ko.ko.3.10.0" "$T/bin/insmod"
}
fake_insmod() {
    printf '#!/bin/sh\n%s\n' "$1" > "$T/bin/insmod"
    chmod +x "$T/bin/insmod"
}
run() {
    PATH="$T/bin:$PATH" sh "$T/init.sh" >/dev/null 2>&1
    echo $?
}

reset
mknod "$T/dev/block/rknand_system" b 7 200
check "already initialised" "$(run)" 0

reset
check "module missing" "$(run)" 1

reset
touch "$T/rk30xxnand_ko.ko.3.10.0"
fake_insmod "(sleep 1; mknod $T/dev/block/rknand_system b 7 200) &"
check "loads module and waits for nodes" "$(run)" 0

reset
touch "$T/rk30xxnand_ko.ko.3.10.0"
fake_insmod "exit 1"
check "insmod failure" "$(run)" 1

reset
touch "$T/rk30xxnand_ko.ko.3.10.0"
fake_insmod "exit 0"
check "nodes never appear" "$(run)" 1

if grep -v '^#' "$ROOT/scripts/twrp-init-nand.sh" | grep -q '/proc/mtd'; then
    check "never reads /proc/mtd" 1 0
else
    check "never reads /proc/mtd" 0 0
fi

echo
[ $fails -eq 0 ] && echo "All tests passed." || { echo "$fails test(s) failed."; exit 1; }
