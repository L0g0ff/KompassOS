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
#ln -sf /usr/share/backgrounds/kompassos/kompassos-wallpaper-1/contents/images/3840x2160.png /usr/share/backgrounds/f43/default/f43-01-night.jxl
#ln -sf /usr/share/backgrounds/kompassos/kompassos-wallpaper-1/contents/images/3840x2160.png /usr/share/backgrounds/f43/default/f43-01-day.jxl
ln -sf /usr/share/backgrounds/kompassos/kompassos-wallpaper-1/contents/images/3840x2160.png /usr/share/backgrounds/aurora/aurora-wallpaper-3/contents/images/3840x2160.jxl
ln -sf /usr/share/backgrounds/kompassos/kompassos-wallpaper-1/contents/images/3840x2160.png /usr/share/backgrounds/aurora/aurora-wallpaper-12/contents/images/3840x2160.jxl

# Raise UID_MIN to 1000 so system users (e.g. plasma-setup, UID 968) are not
# shown in the plasmalogin greeter. Runs last to win over shadow-utils and
# Citrix ICA Client (integrate.sh resets it to 800). See gh#74
sed -i 's/^UID_MIN.*/UID_MIN\t\t\t  1000/' /etc/login.defs

# Remove stray /run/lock/subsys left behind by Citrix ICA Client. Its logging
# daemon ctxcwalogd uses a legacy SysV-init lock (/var/lock/subsys -> /run/lock/subsys),
# which gets baked into the image. /run is tmpfs and recreated empty on boot, and
# the SELinux policy maps this path to <<none>> (unlabeled). That unlabeled dir
# breaks titanoboa's rootfs-selinux-fix step (setfiles -F + chcon --user=system_u):
#   "chcon: can't apply partial context to unlabeled file 'subsys'"
# Removing (not labeling) is the correct fix. See gh#80
rm -rf /run/lock/subsys