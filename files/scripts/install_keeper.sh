#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -euo pipefail
# if shit breaks i at least know where it is
set -x

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