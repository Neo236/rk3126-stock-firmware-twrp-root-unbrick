#!/sbin/sh
# Load the Rockchip NAND driver inside TWRP so /dev/block/rknand_* appears.
# Run on the device:
#   adb push scripts/twrp-init-nand.sh /tmp/
#   adb shell sh /tmp/twrp-init-nand.sh
#
# Safe to run more than once. Never touches /proc/mtd (it panics this kernel).

MODULE=/rk30xxnand_ko.ko.3.10.0
PROBE=/dev/block/rknand_system

if [ -b "$PROBE" ]; then
    echo "NAND already initialised."
else
    if [ ! -f "$MODULE" ]; then
        echo "ERROR: $MODULE not found. Is this the RK TWRP from this archive?" >&2
        exit 1
    fi
    case "$(uname -r)" in
        3.10.0*) ;;
        *) echo "WARNING: kernel is $(uname -r), module is built for 3.10.0" >&2 ;;
    esac

    echo "Loading $MODULE ..."
    insmod "$MODULE" || { echo "ERROR: insmod failed" >&2; exit 1; }

    # Device nodes are created asynchronously.
    i=0
    while [ ! -b "$PROBE" ] && [ $i -lt 20 ]; do
        sleep 1
        i=$((i + 1))
    done
    if [ ! -b "$PROBE" ]; then
        echo "ERROR: $PROBE did not appear after ${i}s" >&2
        exit 1
    fi
fi

echo
echo "NAND partitions:"
ls /dev/block/ | grep '^rknand_' | sed 's/^/  /'
