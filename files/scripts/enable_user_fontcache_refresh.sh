#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -euo pipefail
# if shit breaks i at least know where it is
set -x

#
# Enable the one-time per-user fontconfig cache refresh (CBDT emoji fix).
#
# TEMPORARY: remove together with kompassos-fontcache-refresh.service after
# ~2026-09-16. See that unit for details.
#
systemctl --user enable kompassos-fontcache-refresh.service --global
