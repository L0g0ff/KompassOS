#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -euo pipefail
# if shit breaks i at least know where it is
set -x

# Interesting Repo (Thanks!) https://github.com/sneexy-boi/bluebuild-custom/blob/main/files/scripts/system-wuzetka.sh

#
# Some basic tools, plymouth-plugin-script for bootloader and libvirt-devel for vagrant
#
rpm-ostree install nmap net-snmp-utils telnet screen libvirt-devel tilix plymouth-plugin-script fish waydroid

#
# Switch from fedora flatpak to flathub - need some extra love. Build is failing on this part
#
# flatpak remote-delete --system fedora-testing
# flatpak remote-delete --system fedora
# flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
