#!/usr/bin/env bash

set -ouex pipefail

# remove kernel locks
dnf5 versionlock delete kernel{,-core,-modules,-modules-core,-modules-extra,-tools,-tools-lib,-headers,-devel,-devel-matched}

# Add the Surface Linux repo
dnf5 config-manager \
    addrepo --from-repofile=https://pkg.surfacelinux.com/fedora/linux-surface.repo

# Install the Surface Linux kernel and related packages
dnf5 -y install --allowerasing kernel-surface iptsd libwacom-surface kernel-surface-devel surface-secureboot surface-control

# Remove the default Fedora kernel and related packages
dnf5 -y remove kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra

# Prevent kernel stuff from upgrading again
dnf5 versionlock add kernel{,-core,-modules,-modules-core,-modules-extra,-tools,-tools-lib,-headers,-devel,-devel-matched}