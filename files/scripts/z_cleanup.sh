#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -euo pipefail
# if shit breaks i at least know where it is
set -x


#
# Clean up the yum repo (updates are baked into new images)
#
rm /etc/yum.repos.d/keeper.repo -f
