#!/usr/bin/env sh

# Thanks to rsturla for the inspiration! My script is based on this example:
# https://raw.githubusercontent.com/rsturla/eternal-images/refs/heads/main/lumina/scripts/_base/009-install-google-chrome.sh

set -ouex pipefail

echo "Installing Google Chrome"

# On libostree systems, /opt is a symlink to /var/opt,
# which actually only exists on the live system. /var is
# a separate mutable, stateful FS that's overlaid onto
# the ostree rootfs. Therefore we need to install it into
# /usr/lib/google instead, and dynamically create a
# symbolic link /opt/google => /usr/lib/google upon
# boot.

# Prepare staging directory
mkdir -p /var/opt # -p just in case it exists

# Setup repo
cat << EOF > /etc/yum.repos.d/google-chrome.repo
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-google
EOF

# Prepare alternatives directory
mkdir -p /var/lib/alternatives

# Import signing key - Disabled because of errors in google certifcate
curl --retry 3 --retry-delay 2 --retry-all-errors -sL \
  -o /etc/pki/rpm-gpg/RPM-GPG-KEY-google \
  https://dl.google.com/linux/linux_signing_key.pub
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-google

# Now let's install the packages.
rpm-ostree install google-chrome-stable

# Clean up the yum repo (updates are baked into new images)
rm /etc/yum.repos.d/google-chrome.repo -f

# And then we do the hacky dance!
mv /var/opt/google /usr/lib/google # move this over here

#####
# Register path symlink
# We do this via tmpfiles.d so that it is created by the live system.
cat >/usr/lib/tmpfiles.d/eternal-google.conf <<EOF
L  /opt/google  -  -  -  -  /usr/lib/google
EOF
