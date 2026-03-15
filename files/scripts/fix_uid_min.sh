#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -euo pipefail
# if shit breaks i at least know where it is
set -x


#
# Fix UID_MIN so fresh Anaconda installs assign UID 1000 to the first user.
# rpm-ostree sets UID_MIN=800 in ostree-based images by default, causing
# Anaconda to assign UID 800+ instead of 1000, breaking SDDM and KDE Plasma.
# See: https://gitlab.com/fedora/ostree/sig/-/issues/90
#
sed -i 's/^UID_MIN[[:space:]].*$/UID_MIN\t\t1000/' /etc/login.defs
