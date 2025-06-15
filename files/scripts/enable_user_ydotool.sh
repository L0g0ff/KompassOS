#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -euo pipefail
# if shit breaks i at least know where it is
set -x

#
# Enable custom Ydotool service
#
# systemctl enable ydotool.service
systemctl --user enable ydotool.service --global
