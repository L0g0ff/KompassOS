#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -euo pipefail
# if shit breaks i at least know where it is
set -x


#
# Fix SDDM Numlock
#
sed -i '/InputMethod=/a Numlock=on' /usr/lib/sddm/sddm.conf.d/plasma-wayland.conf

