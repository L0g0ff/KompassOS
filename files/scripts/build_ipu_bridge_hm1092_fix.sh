#!/usr/bin/env bash
#
# Build a patched ipu-bridge.ko without the HIMX1092 entry (issue #117).
#
# Mainline commit 4fdb0342f05e ("media: ipu-bridge: Add Himax HM1092 IR
# sensor", in v7.3) lists the Windows Hello IR sensor in ipu-bridge, but the
# kernel has no driver for it. On Dell XPS/Latitude laptops with IPU6 + IVSC
# the ISYS async notifier then never completes, the ov02c10 RGB sensor gets
# no /dev/v4l-subdev node and libcamera finds no camera. Same fix as Omarchy
# (omarchy-pkgs 0552-ipu-bridge-revert-himax-hm1092.patch).
#
# The module is built from the exact Fedora kernel source of the image kernel
# (Fedora patches ipu-bridge.c heavily, so vanilla kernel.org source is not
# usable), signed with the KompassOS MOK key and installed OUTSIDE
# /usr/lib/modules, so it never replaces the stock module by default. Users
# opt in with `ujust enable-webcam-hm1092-fix`, which enrolls the MOK cert and
# adds a modprobe.d install rule with fallback to the stock module.
#
# Signing key: PEM private key in env KOMPASSOS_MOK_KEY (BlueBuild secret).
# Without it (e.g. PR builds) the module is built and checked, not installed.
#
# Remove this script once the image kernel no longer carries the HIMX1092
# entry (the script then skips by itself) or ships an HM1092 driver.

set -euo pipefail

CERT=/usr/share/kompassos/mok/kompassos-mok.der
WORK=$(mktemp -d -t ipu-bridge-build.XXXXXX)
trap 'rm -rf "$WORK"' EXIT

# Exactly one kernel is expected in the image.
mapfile -t KVERS < <(rpm -q kernel-core --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n')
if [[ ${#KVERS[@]} -ne 1 ]]; then
    echo "ERROR: expected exactly one kernel-core, found: ${KVERS[*]}" >&2
    exit 1
fi
KVER=${KVERS[0]}
VER=$(rpm -q kernel-core --qf '%{VERSION}')
REL=$(rpm -q kernel-core --qf '%{RELEASE}')
MAJMIN=$(cut -d. -f1-2 <<<"$VER")
KDIR=/usr/src/kernels/$KVER
STOCK_KO=$(find "/usr/lib/modules/$KVER" -name 'ipu-bridge.ko*' -print -quit)
DEST=/usr/lib/kompassos/kmods/$KVER

echo "Kernel: $KVER"
[[ -d $KDIR ]] || { echo "ERROR: kernel-devel for $KVER missing ($KDIR)" >&2; exit 1; }
[[ -n $STOCK_KO ]] || { echo "ERROR: stock ipu-bridge.ko not found for $KVER" >&2; exit 1; }

# Fetch the Fedora source RPM of this exact kernel build from Koji.
SRPM_URL=https://kojipkgs.fedoraproject.org/packages/kernel/$VER/$REL/src/kernel-$VER-$REL.src.rpm
curl -fsSL --retry 5 --retry-all-errors --retry-delay 10 -o "$WORK/kernel.src.rpm" "$SRPM_URL"
rpm -K --nosignature "$WORK/kernel.src.rpm" >/dev/null # digest check: catches truncated downloads
(cd "$WORK" && rpm2cpio kernel.src.rpm | cpio -idm --quiet "./linux-$VER.tar.xz" "./patch-$MAJMIN-redhat.patch")
rm -f "$WORK/kernel.src.rpm"

# Vanilla ipu-bridge.c plus only the Fedora hunks for that file.
SRC=drivers/media/pci/intel/ipu-bridge.c
mkdir -p "$WORK/src"
tar -xJf "$WORK/linux-$VER.tar.xz" -C "$WORK/src" --strip-components=1 "linux-$VER/$SRC"
awk -v f="$SRC" '
    /^diff --git / { keep = ($3 == "a/" f) }
    keep
' "$WORK/patch-$MAJMIN-redhat.patch" > "$WORK/ipu-bridge-redhat.patch"
if [[ -s $WORK/ipu-bridge-redhat.patch ]]; then
    patch -d "$WORK/src" -p1 --forward --no-backup-if-mismatch < "$WORK/ipu-bridge-redhat.patch"
fi

build() { # $1 = output dir, builds ipu-bridge.ko from $WORK/src
    mkdir -p "$1"
    cp "$WORK/src/$SRC" "$1/ipu-bridge.c"
    echo 'obj-m := ipu-bridge.o' > "$1/Kbuild"
    make -s -C "$KDIR" M="$1" modules
}

symbols() { # defined symbols of a (possibly compressed) module
    local ko=$1
    if [[ $ko == *.xz ]]; then xz -dc "$ko" > "$WORK/stock.ko"; ko=$WORK/stock.ko; fi
    nm --defined-only "$ko" | awk '{print $NF}' | grep -v '^__\(UNIQUE_ID\|export_symbol\|kstrtab\|crc\)' | sort -u
}

# Sanity check: the unmodified rebuild must match the stock module, so we
# know the reconstructed Fedora source is the one the kernel was built from.
build "$WORK/orig"
if ! diff <(symbols "$STOCK_KO") <(symbols "$WORK/orig/ipu-bridge.ko") >/dev/null; then
    echo "ERROR: rebuilt ipu-bridge.ko does not match the stock module" >&2
    diff <(symbols "$STOCK_KO") <(symbols "$WORK/orig/ipu-bridge.ko") >&2 || true
    exit 1
fi
for f in vermagic alias; do
    if [[ "$(modinfo -F "$f" "$STOCK_KO")" != "$(modinfo -F "$f" "$WORK/orig/ipu-bridge.ko")" ]]; then
        echo "ERROR: modinfo $f differs from the stock module" >&2
        exit 1
    fi
done

# Nothing to fix (anymore)? Then ship nothing.
n=$(grep -c 'IPU_SENSOR_CONFIG("HIMX1092"' "$WORK/src/$SRC" || true)
if [[ $n -eq 0 ]]; then
    echo "Kernel $KVER has no HIMX1092 entry in ipu-bridge; fix not needed, skipping."
    exit 0
fi
[[ $n -eq 1 ]] || { echo "ERROR: expected 1 HIMX1092 entry, found $n" >&2; exit 1; }

# The actual fix: drop the HIMX1092 entry and its comment line.
sed -i -e '/\/\* Himax HM1092 \*\//d' -e '/IPU_SENSOR_CONFIG("HIMX1092"/d' "$WORK/src/$SRC"
if grep -q 'HIMX1092\|HM1092' "$WORK/src/$SRC"; then
    echo "ERROR: HIMX1092 still present after patching" >&2
    exit 1
fi
build "$WORK/fixed"

if [[ -z ${KOMPASSOS_MOK_KEY:-} ]]; then
    echo "WARNING: KOMPASSOS_MOK_KEY not set; patched ipu-bridge built and verified but NOT installed."
    exit 0
fi
[[ -f $CERT ]] || { echo "ERROR: MOK certificate $CERT missing" >&2; exit 1; }

# Sign with the KompassOS MOK key; the key only ever lives in $WORK.
(umask 077; printf '%s\n' "$KOMPASSOS_MOK_KEY" > "$WORK/mok.key")
"$KDIR/scripts/sign-file" sha512 "$WORK/mok.key" "$CERT" "$WORK/fixed/ipu-bridge.ko"
rm -f "$WORK/mok.key"
modinfo -F signer "$WORK/fixed/ipu-bridge.ko" | grep -q . || { echo "ERROR: module not signed" >&2; exit 1; }

install -D -m 0644 "$WORK/fixed/ipu-bridge.ko" "$DEST/ipu-bridge.ko"
echo "Installed patched ipu-bridge.ko to $DEST (signer: $(modinfo -F signer "$DEST/ipu-bridge.ko"))"
