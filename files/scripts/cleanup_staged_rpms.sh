#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -euo pipefail
set -x

#
# Clean up staged RPM cache (prevents ~1.2GB of stale data from invalidating container layers on every build)
#
rm -rf /run/rpm-ostree/staged-rpms/*
