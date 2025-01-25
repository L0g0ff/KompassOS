#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -euo pipefail
# if shit breaks i at least know where it is
set -x

#
# DisplayLink Support
#
echo 'Installing DisplayLink support'

# Enable repo
sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo

# Get EVDI module from the repo directly
rpm-ostree install evdi

# Disable repo again
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo