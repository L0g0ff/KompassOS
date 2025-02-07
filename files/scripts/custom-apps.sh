#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -euo pipefail
# if shit breaks i at least know where it is
set -x

# Interesting Repo (Thanks!) https://github.com/sneexy-boi/bluebuild-custom/blob/main/files/scripts/system-wuzetka.sh

#
# Keeper
#
# echo 'Download and Install Keeper'
# curl -sL -o /tmp/keeper.rpm "https://download.keepersecurity.com/desktop_electron/Linux/repo/rpm/keeperpasswordmanager-16.11.3-1.x86_64.rpm"
# rpm-ostree install /tmp/keeper.rpm

#
# Citrix Workspace - Grumble crappy Citrix mirror...
#
# echo 'Download and Install Citrix Client'
# curl -sL -o /tmp/citrix.rpm "https://downloads.citrix.com/23169/ICAClient-rhel-24.11.0.85-0.x86_64.rpm?__gda__=exp=1737740175~acl=/*~hmac=91f04a83f0adacdf352312e8a1f8fbab6cee2e42c2841f878f280adf5388002f"
# rpm-ostree install /tmp/citrix.rpm

# #
# # Remote Desktop Manager - USE Distrobox for better keeper support.
# #
# echo 'Download and Install RDM'
# curl -sL -o /tmp/rdm.rpm "https://cdn.devolutions.net/download/Linux/RDM/2024.3.2.5/RemoteDesktopManager_2024.3.2.5_x86_64.rpm"
# rpm-ostree install /tmp/rdm.rpm


# #
# # Prospect Outlook - USE PWA instead
# #
# echo 'Download and Prospect Outlook Client'
# curl -sL -o /tmp/prospect.rpm "https://github.com/julian-alarcon/prospect-mail/releases/download/v0.5.4/prospect-mail-0.5.4.x86_64.rpm"
# rpm-ostree install /tmp/prospect.rpm


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

rm /etc/yum.repos.d/keeper.repo -f