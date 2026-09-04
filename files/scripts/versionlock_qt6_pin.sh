#!/usr/bin/bash
set -eoux pipefail

# Pinning the base image alone isn't enough: the dnf installs later in the
# build (common-dnf.yml) still resolve against the live Fedora repos and
# silently pull qt6-qtbase back up to whatever is currently published there
# (6.11.2-2), recreating the exact ABI mismatch with libplasma/plasma-login-
# manager/plasma-integration/plasma-activities (still 6.7.4-1) that this
# whole pin was meant to avoid. Lock qt6 to what's already in the pinned
# base image before any other dnf module runs. Remove once the base image
# is unpinned (see recipes/recipe-dx-*.yml).
dnf5 -y versionlock add 'qt6-*'
