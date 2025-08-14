#!/usr/bin/env bash

set -ouex pipefail

GIT=https://github.com/bazzite-org/kernel-bazzite
GITOWNER=$(echo "$GIT" | sed -E 's#https://github.com/([^/]+)/([^/]+)(\.git)*#\1#')
GITREPO=$(echo "$GIT" | sed -E 's#https://github.com/([^/]+)/([^/]+)(\.git)*#\2#')

KERNEL_TAG=$(curl -s https://api.github.com/repos/$GITOWNER/$GITREPO/releases | grep tag_name | cut -d : -f2 | tr -d 'v", ' | grep -Ev '\-[0-9]+\.[0-9]+$' | head -1)
KERNEL_VERSION=$KERNEL_TAG
OS_VERSION=$(rpm -E %fedora)

# remove kernel locks
dnf5 versionlock list
dnf5 versionlock delete kernel{,-core,-modules,-modules-core,-modules-extra,-tools,-tools-lib,-headers,-devel,-devel-matched}
dnf5 versionlock list

echo 'Installing Bazzite kernel.'
dnf5 -y install --allowerasing \
    https://github.com/$GITOWNER/$GITREPO/releases/download/$KERNEL_TAG/kernel-$KERNEL_VERSION.bazzite.fc$OS_VERSION.x86_64.rpm \
    https://github.com/$GITOWNER/$GITREPO/releases/download/$KERNEL_TAG/kernel-core-$KERNEL_VERSION.bazzite.fc$OS_VERSION.x86_64.rpm \
    https://github.com/$GITOWNER/$GITREPO/releases/download/$KERNEL_TAG/kernel-modules-$KERNEL_VERSION.bazzite.fc$OS_VERSION.x86_64.rpm \
    https://github.com/$GITOWNER/$GITREPO/releases/download/$KERNEL_TAG/kernel-modules-core-$KERNEL_VERSION.bazzite.fc$OS_VERSION.x86_64.rpm \
    https://github.com/$GITOWNER/$GITREPO/releases/download/$KERNEL_TAG/kernel-modules-extra-$KERNEL_VERSION.bazzite.fc$OS_VERSION.x86_64.rpm \
    https://github.com/$GITOWNER/$GITREPO/releases/download/$KERNEL_TAG/kernel-modules-extra-matched-$KERNEL_VERSION.bazzite.fc$OS_VERSION.x86_64.rpm \
    https://github.com/$GITOWNER/$GITREPO/releases/download/$KERNEL_TAG/kernel-devel-$KERNEL_VERSION.bazzite.fc$OS_VERSION.x86_64.rpm \
    https://github.com/$GITOWNER/$GITREPO/releases/download/$KERNEL_TAG/kernel-devel-matched-$KERNEL_VERSION.bazzite.fc$OS_VERSION.x86_64.rpm

echo 'Downloading ublue-os akmods COPR repo file'
curl -L https://copr.fedorainfracloud.org/coprs/ublue-os/akmods/repo/fedora-$(rpm -E %fedora)/ublue-os-akmods-fedora-$(rpm -E %fedora).repo -o /etc/yum.repos.d/_copr_ublue-os-akmods.repo

echo 'Installing zenergy kmod'
dnf5 install -y \
    akmod-zenergy-*.fc$OS_VERSION.x86_64
    # akmod-zenpower3-*.fc$OS_VERSION.x86_64 \
    # akmod-ryzen-smu-*.fc$OS_VERSION.x86_64 \

akmods --force --kernels $KERNEL_VERSION.bazzite.fc$OS_VERSION.x86_64 --kmod zenergy
modinfo /usr/lib/modules/$KERNEL_VERSION.bazzite.fc$OS_VERSION.x86_64/extra/zenergy/zenergy.ko.xz > /dev/null \
    || (find /var/cache/akmods/zenergy/ -name \*.log -print -exec cat {} \; && exit 1)

# akmods --force --kernels $KERNEL_VERSION.bazzite.fc$OS_VERSION.x86_64 --kmod zenpower3
# modinfo /usr/lib/modules/$KERNEL_VERSION.bazzite.fc$OS_VERSION.x86_64/extra/zenpower3/zenpower3.ko.xz > /dev/null \
#     || (find /var/cache/akmods/zenpower3/ -name \*.log -print -exec cat {} \; && exit 1)

# akmods --force --kernels $KERNEL_VERSION.bazzite.fc$OS_VERSION.x86_64 --kmod ryzen-smu
# modinfo /usr/lib/modules/$KERNEL_VERSION.bazzite.fc$OS_VERSION.x86_64/extra/ryzen-smu/ryzen-smu.ko.xz > /dev/null \
#     || (find /var/cache/akmods/ryzen-smu/ -name \*.log -print -exec cat {} \; && exit 1)

# Prevent kernel stuff from upgrading again
dnf5 versionlock add kernel{,-core,-modules,-modules-core,-modules-extra,-tools,-tools-lib,-headers,-devel,-devel-matched}