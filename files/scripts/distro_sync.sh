#!/usr/bin/bash
set -eoux pipefail

# The base image can ship with a partially-applied Fedora update: some
# packages already bumped to a new release while ABI-linked companions
# (e.g. qt6-qtbase vs. plasma-workspace) are still on the older release.
# That breaks private Qt6 API symbols and crashes the Plasma QML shell
# (login screen / desktop render black, only the compositor's cursor works).
# A bare `distro-sync` also tries to touch the kernel, which conflicts with
# how rpm-ostree/bootc images pin it (the surface variant even hard-locks it
# via versionlock) — see RHBZ#1260989. So instead of a wildcard (or every
# package Fedora happened to bundle in the same 2026-08-25 Bodhi update),
# this targets only the two source packages that actually own the files
# crashing the login/desktop QML shell against qt6-qtbase-6.11.2-2:
#   - plasma-workspace: owns libbatterycontrolplugin.so and
#     libplasma_wallpaper_image.so (the undefined-symbol crashes)
#   - plasma-login-manager: owns /usr/bin/plasmalogin and its Main.qml,
#     which loads those broken plasma-workspace plugins
# Their tightly-coupled same-srpm subpackages are listed too so dnf doesn't
# have to guess; distro-sync will still pull in anything else it needs to
# keep dependencies consistent.
plasma_login_packages=(
  plasma-workspace plasma-workspace-common plasma-workspace-libs
  plasma-workspace-wallpapers libkworkspace6 plasma-lookandfeel-fedora
  plasma-login-manager kcm-plasmalogin
)
dnf5 -y distro-sync "${plasma_login_packages[@]}"
