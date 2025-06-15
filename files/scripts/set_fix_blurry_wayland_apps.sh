#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -euo pipefail
# if shit breaks i at least know where it is
set -x


#
# Fix blurry wayland electron apps
#
echo 'ELECTRON_OZONE_PLATFORM_HINT=auto' >> /etc/environment
