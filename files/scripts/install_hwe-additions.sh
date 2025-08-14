#!/usr/bin/bash

# Source: https://github.com/ublue-os/bluefin/blob/8abcdaef1315bf3d605e00685c7c456a1b392ca2/build_files/base/09-hwe-additions.sh
# Switch to non HWE Aurora image and add this configuration to KompassOS because HWE is deprecated in Aurora Fedora 43

# This is a Work in progress! Don't use!

set -eoux pipefail

# remove kernel locks
dnf5 versionlock list
dnf5 versionlock delete kernel{,-core,-modules,-modules-core,-modules-extra,-tools,-tools-lib,-headers,-devel,-devel-matched}

# NOTE: we won't use dnf5 copr plugin for ublue-os/akmods until our upstream provides the COPR standard naming
sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo

# Fetch Common AKMODS & Kernel RPMS
AKMODS_FLAVOR="bazzite"
KERNEL="6.15.9-106.bazzite.fc42.x86_64"
# Hardcoded for testing
skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/akmods:bazzite-42-6.15.9-106.bazzite.fc42.x86_64 dir:/tmp/akmods
#skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/akmods:"${AKMODS_FLAVOR}"-"$(rpm -E %fedora)"-"${KERNEL}" dir:/tmp/akmods
AKMODS_TARGZ=$(jq -r '.layers[].digest' </tmp/akmods/manifest.json | cut -d : -f 2)
echo $AKMODS_TARGZ
dnf5 search kernel-core
uname -a
tar -xvzf /tmp/akmods/"$AKMODS_TARGZ" -C /tmp/
mv /tmp/rpms/* /tmp/akmods/
# NOTE: kernel-rpms should auto-extract into correct location
dnf5 -y install --allowerasing /tmp/kernel-rpms/kernel{,-core,-modules,-modules-core,-modules-extra}-"${KERNEL}".rpm

# Install RPMS
dnf5 -y install --allowerasing /tmp/akmods/kmods/*kvmfr*.rpm

# Everyone
# NOTE: we won't use dnf5 copr plugin for ublue-os/akmods until our upstream provides the COPR standard naming
sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo
AKMODS=(
    /tmp/akmods/kmods/*xone*.rpm
    /tmp/akmods/kmods/*framework-laptop*.rpm
    /tmp/akmods/kmods/*openrazer*.rpm
)
dnf5 -y install "${AKMODS[@]}"

# RPMFUSION Dependent AKMODS
dnf5 -y install \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm

dnf5 -y install \
        v4l2loopback /tmp/akmods/kmods/*v4l2loopback*.rpm

dnf5 -y remove rpmfusion-free-release rpmfusion-nonfree-release

# Asus/Surface for HWE
curl --retry 3 -Lo /etc/yum.repos.d/_copr_lukenukem-asus-linux.repo \
    https://copr.fedorainfracloud.org/coprs/lukenukem/asus-linux/repo/fedora-$(rpm -E %fedora)/lukenukem-asus-linux-fedora-$(rpm -E %fedora).repo

curl --retry 3 -Lo /etc/yum.repos.d/linux-surface.repo \
        https://pkg.surfacelinux.com/fedora/linux-surface.repo

# Asus Firmware -- Investigate if everything has been upstreamed
# git clone https://gitlab.com/asus-linux/firmware.git --depth 1 /tmp/asus-firmware
# cp -rf /tmp/asus-firmware/* /usr/lib/firmware/
# rm -rf /tmp/asus-firmware

ASUS_PACKAGES=(
    asusctl
    asusctl-rog-gui
)

SURFACE_PACKAGES=(
    iptsd
    libcamera
    libcamera-tools
    libcamera-gstreamer
    libcamera-ipa
    pipewire-plugin-libcamera
)

dnf5 -y install --skip-unavailable \
    "${ASUS_PACKAGES[@]}" \
    "${SURFACE_PACKAGES[@]}"

dnf5 -y swap \
    libwacom-data libwacom-surface-data

dnf5 -y swap \
    libwacom libwacom-surface

tee /usr/lib/modules-load.d/ublue-surface.conf << EOF
# Only on AMD models
pinctrl_amd

# Surface Book 2
pinctrl_sunrisepoint

# For Surface Laptop 3/Surface Book 3
pinctrl_icelake

# For Surface Laptop 4/Surface Laptop Studio
pinctrl_tigerlake

# For Surface Pro 9/Surface Laptop 5
pinctrl_alderlake

# For Surface Pro 10/Surface Laptop 6
pinctrl_meteorlake

# Only on Intel models
intel_lpss
intel_lpss_pci

# Add modules necessary for Disk Encryption via keyboard
surface_aggregator
surface_aggregator_registry
surface_aggregator_hub
surface_hid_core
8250_dw

# Surface Laptop 3/Surface Book 3 and later
surface_hid
surface_kbd
EOF

KERNEL_SUFFIX=""
QUALIFIED_KERNEL="$(rpm -qa | grep -P 'kernel-(|'"$KERNEL_SUFFIX"'-)(\d+\.\d+\.\d+)' | sed -E 's/kernel-(|'"$KERNEL_SUFFIX"'-)//')"

/usr/bin/dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible -v --add ostree -f "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"
chmod 0600 "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"

# Prevent kernel stuff from upgrading again
dnf5 versionlock add kernel{,-core,-modules,-modules-core,-modules-extra,-tools,-tools-lib,-headers,-devel,-devel-matched}