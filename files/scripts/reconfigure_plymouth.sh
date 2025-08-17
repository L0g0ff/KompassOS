#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -euo pipefail
# if shit breaks i at least know where it is
set -x

# Source Repo (Thanks!) https://github.com/adi1090x/plymouth-themes/

#
# Theme is already copied (see recipe)
# Set the theme (tech_b, in this case)
# Rebuilt the initrd (see recipe)
#
#plymouth-set-default-theme rings_2
plymouth-set-default-theme kompassos
