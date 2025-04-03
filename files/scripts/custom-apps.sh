#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -euo pipefail
# if shit breaks i at least know where it is
set -x

# Interesting Repo (Thanks!) https://github.com/sneexy-boi/bluebuild-custom/blob/main/files/scripts/system-wuzetka.sh

#
# Some basic tools, plymouth-plugin-script for bootloader and libvirt-devel for vagrant
#
rpm-ostree install nmap net-snmp telnet screen libvirt-devel tilix plymouth-plugin-script1

#
# Switch from fedora flatpak to flathub - need some extra love. Build is failing on this part
#
# flatpak remote-delete --system fedora-testing
# flatpak remote-delete --system fedora
# flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo


#
# Keeper
#
# Setup repo
cat << EOF > /etc/yum.repos.d/keeper.repo
[keeper-security]
name=keeper-security
baseurl=https://keepersecurity.com/desktop_electron/Linux/repo/rpm/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-keeper
EOF

# Import signing key
curl --retry 3 --retry-delay 2 --retry-all-errors -sL \
  -o /etc/pki/rpm-gpg/RPM-GPG-KEY-keeper \
  https://keepersecurity.com/desktop_electron/Linux/signing.pub
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-keeper


rpm-ostree install keeperpasswordmanager

#
# Fix SSH priv ports
#
echo 'net.ipv4.ip_unprivileged_port_start=0' > /etc/sysctl.d/50-unprivileged-ports.conf

#
# Fix SDDM Numlock
#
sed -i '/InputMethod=/a Numlock=on' /usr/lib/sddm/sddm.conf.d/plasma-wayland.conf


#
# Fix blurry wayland electron apps
#
echo 'ELECTRON_OZONE_PLATFORM_HINT=auto' >> /etc/environment

#
# Clean up the yum repo (updates are baked into new images)
#
rm /etc/yum.repos.d/keeper.repo -f