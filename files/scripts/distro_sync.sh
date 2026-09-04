#!/usr/bin/bash
set -eoux pipefail

# The base image can ship with a partially-applied Fedora update: some
# packages already bumped to a new release while ABI-linked companions
# (e.g. qt6-qtbase vs. plasma-workspace) are still on the older release.
# That breaks private Qt6 API symbols and crashes the Plasma QML shell
# (login screen / desktop render black, only the compositor's cursor works).
# distro-sync realigns everything to the same, already-published stable set.
dnf5 -y distro-sync
