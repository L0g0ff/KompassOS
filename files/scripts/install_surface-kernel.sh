#!/usr/bin/env bash

set -ouex pipefail

# remove kernel locks
dnf5 versionlock list
dnf5 versionlock delete kernel{,-core,-modules,-modules-core,-modules-extra,-tools,-tools-lib,-headers,-devel,-devel-matched}
dnf5 versionlock list

dnf5 config-manager \
    addrepo --from-repofile=https://pkg.surfacelinux.com/fedora/linux-surface.repo

dnf5 -y install --allowerasing kernel-surface iptsd libwacom-surface kernel-surface-devel surface-secureboot surface-control

# Prevent kernel stuff from upgrading again
dnf5 versionlock add kernel{,-core,-modules,-modules-core,-modules-extra,-tools,-tools-lib,-headers,-devel,-devel-matched}