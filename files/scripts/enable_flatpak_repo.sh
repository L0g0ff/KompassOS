#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -euo pipefail
# if shit breaks i at least know where it is
set -x


#
# Better Flatpak support (PoC)
#
systemctl enable flatpak-add-fedora-repos.service