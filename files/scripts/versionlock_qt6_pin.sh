#!/usr/bin/bash
set -eoux pipefail

# Fedora 44 currently ships qt6-qtbase-6.11.2-2 without matching rebuilds of
# libplasma/plasma-login-manager/plasma-integration/plasma-activities (stuck
# on 6.7.4-1, built against the older Qt6 ABI). Mixing the two segfaults
# plasma-login-greeter on login (black screen, compositor cursor still
# visible). The base image can be internally consistent at pull time, but
# later dnf installs in this build (common-dnf.yml, e.g. install_opensnitch.sh
# pulling in a Qt6-dependent package) still resolve against the live Fedora
# repos and can silently bump qt6-qtbase past what the rest of the image has,
# recreating the mismatch. Lock qt6 to whatever the base image already has
# before any other dnf module runs, so later installs can't move it.
# Remove once Fedora ships a matching libplasma/plasma-login-manager/
# plasma-integration/plasma-activities release (independent of any
# image-version pin in recipes/recipe-dx-*.yml).
dnf5 -y versionlock add 'qt6-*'
