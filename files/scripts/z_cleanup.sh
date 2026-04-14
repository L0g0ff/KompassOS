#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -euo pipefail
# if shit breaks i at least know where it is
set -x


#
# Overwrite Aurora branding for KompassOS backgrounds
#
ln -sf /usr/share/backgrounds/kompassos/kompassos-wallpaper-1/contents/images/3840x2160.png /usr/share/backgrounds/default.png
ln -sf /usr/share/backgrounds/kompassos/kompassos-wallpaper-1/contents/images/3840x2160.png /usr/share/backgrounds/default.jxl
ln -sf /usr/share/backgrounds/kompassos/kompassos-wallpaper-1/contents/images/3840x2160.png /usr/share/backgrounds/default-dark.png
ln -sf /usr/share/backgrounds/kompassos/kompassos-wallpaper-1/contents/images/3840x2160.png /usr/share/backgrounds/default-dark.jxl
ln -sf /usr/share/backgrounds/kompassos/kompassos-wallpaper-1/contents/images/3840x2160.png /usr/share/backgrounds/f43/default/f43-01-night.jxl
ln -sf /usr/share/backgrounds/kompassos/kompassos-wallpaper-1/contents/images/3840x2160.png /usr/share/backgrounds/f43/default/f43-01-day.jxl
ln -sf /usr/share/backgrounds/kompassos/kompassos-wallpaper-1/contents /usr/share/wallpapers/Aurora

#
# Replace Next wallpaper with KompassOS wallpaper so SDDM and KDE lock screen use it on all monitors
#
ln -sf /usr/share/backgrounds/kompassos/kompassos-wallpaper-1/contents/images/3840x2160.png /usr/share/wallpapers/Next/contents/images/1440x2960.png
ln -sf /usr/share/backgrounds/kompassos/kompassos-wallpaper-1/contents/images/3840x2160.png /usr/share/wallpapers/Next/contents/images/5120x2880.png
ln -sf /usr/share/backgrounds/kompassos/kompassos-wallpaper-1/contents/images/3840x2160.png /usr/share/wallpapers/Next/contents/images/7680x2160.png
ln -sf /usr/share/backgrounds/kompassos/kompassos-wallpaper-1/contents/images/3840x2160.png /usr/share/wallpapers/Next/contents/images_dark/1440x2960.png
ln -sf /usr/share/backgrounds/kompassos/kompassos-wallpaper-1/contents/images/3840x2160.png /usr/share/wallpapers/Next/contents/images_dark/5120x2880.png
ln -sf /usr/share/backgrounds/kompassos/kompassos-wallpaper-1/contents/images/3840x2160.png /usr/share/wallpapers/Next/contents/images_dark/7680x2160.png