#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -euo pipefail
# if shit breaks i at least know where it is
set -x


#
# Overwrite Aurora branding for KompassOS backgrounds
#
ln -sf /usr/share/backgrounds/kompassos/kompassos-wallpaper-1/contents/images/3840x2160.png /usr/share/backgrounds/default.png
ln -sf /usr/share/backgrounds/kompassos/kompassos-wallpaper-1/contents/images/3840x2160.png /usr/share/backgrounds/default-dark.png
ln -sf /usr/share/backgrounds/kompassos/kompassos-wallpaper-1 /usr/share/backgrounds/aurora/aurora-wallpaper-1
ln -sf /usr/share/backgrounds/kompassos/kompassos-wallpaper-1/contents/images/3840x2160.png /usr/share/backgrounds/default.png
ln -sf /usr/share/backgrounds/kompassos/kompassos-wallpaper-1/contents/images/3840x2160.png /usr/share/backgrounds/default-dark.jxl
ln -sf /usr/share/backgrounds/kompassos/kompassos-wallpaper-1/contents/images/3840x2160.png /usr/share/backgrounds/default.jxl