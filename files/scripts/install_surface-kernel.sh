#!/usr/bin/env bash

set -ouex pipefail

# remove kernel locks
dnf5 versionlock delete kernel{,-core,-modules,-modules-core,-modules-extra,-tools,-tools-lib,-headers,-devel,-devel-matched}

# Add the Surface Linux repo
# see recipe /files/dnf/surface-linux.repo
# hardcoded the repo for F43 compatibility
## dnf5 config-manager \
##     addrepo --from-repofile=https://pkg.surfacelinux.com/fedora/linux-surface.repo

# Install the Surface Linux kernel and related packages
#test libwacom
#dnf5 -y install --allowerasing kernel-surface iptsd kernel-surface-devel surface-secureboot surface-control kernel-surface-core
dnf5 -y install --allowerasing --exclude=libinput* kernel-surface iptsd libwacom-surface kernel-surface-devel surface-secureboot surface-control kernel-surface-core
# Remove the default Fedora kernel and related packages, but EXCLUDE all Surface kernel packages
dnf5 -y remove --exclude=kernel-surface* --exclude=fakeroot* kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra

# Prevent kernel stuff from upgrading again
dnf5 versionlock add kernel{,-core,-modules,-modules-core,-modules-extra,-tools,-tools-lib,-headers,-devel,-devel-matched}

# Work around iptsd@.service.in shipping StopWhenUnneeded=yes: the unit is only
# ever activated via udev's SYSTEMD_WANTS (a one-shot job trigger), not a
# persistent Wants= relation. Systemd then decides nothing "needs" the unit a
# few seconds after start and stops it, even though the hidraw device is still
# present - breaking touch/pen until suspend/resume re-triggers udev.
# See: https://github.com/systemd/systemd/issues/23410
mkdir -p /usr/lib/systemd/system/iptsd@.service.d
cat > /usr/lib/systemd/system/iptsd@.service.d/10-stop-when-unneeded.conf <<'EOF'
[Unit]
StopWhenUnneeded=no
EOF