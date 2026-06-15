#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -euo pipefail
# if shit breaks i at least know where it is
set -x

#
# Install Keeper Password Manager from our own RPM mirror.
#
# The mirror exposes a "latest-rpm" pointer file containing the filename of the
# most recent Keeper RPM. We read that filename and prepend the repo base URL to
# build the full download URL, so the build always pulls the latest version
# without pinning it here.
#

REPO_BASE="https://repo.kompassos.nl/rpm"
POINTER_URL="$REPO_BASE/keeper-rpm/latest-rpm"

# Read the filename of the latest RPM from the pointer file.
file="$(curl -fsSL "$POINTER_URL")"

if [ -z "$file" ]; then
  echo "Could not read latest Keeper RPM filename from $POINTER_URL" >&2
  exit 1
fi

echo "Installing Keeper Password Manager: $file"
dnf install -y "$REPO_BASE/$file"
