#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -euo pipefail
# if shit breaks i at least know where it is
set -x

#
# Install OpenSnitch (daemon + UI) from the KompassOS RPM mirror.
#
# The upstream RPM's %post scriptlet runs "systemctl start opensnitch.service",
# which always fails during an image build (no running systemd/dbus) and would
# abort the whole dnf transaction. Installing with tsflags=noscripts skips
# that, then we enable (but don't start) the service ourselves - enabling only
# creates a symlink and doesn't need a running systemd instance.
daemon_rpm="$(curl -fsSL https://repo.kompassos.nl/rpm/opensnitch-rpm/latest-rpm)"
ui_rpm="$(curl -fsSL https://repo.kompassos.nl/rpm/opensnitch-rpm/latest-rpm-ui)"

dnf5 install -y --setopt=tsflags=noscripts \
  "https://repo.kompassos.nl/rpm/$daemon_rpm" \
  "https://repo.kompassos.nl/rpm/$ui_rpm"

systemctl enable opensnitch.service
