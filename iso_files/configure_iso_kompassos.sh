#!/usr/bin/env bash
# Based on: https://github.com/get-aurora-dev/iso/blob/main/iso_files/configure_iso_anaconda.sh

set -eoux pipefail

# Map image-info.json (inherits upstream Aurora refs) to KompassOS image refs
IMAGE_INFO="$(cat /usr/share/ublue-os/image-info.json)"
IMAGE_TAG="latest"
IMAGE_NAME="$(jq -r '."image-name"' <<<"$IMAGE_INFO")"

case "$IMAGE_NAME" in
    aurora-dx-nvidia-open) IMAGE_REF="ghcr.io/l0g0ff/kompassos-dx-hwe-nvidia" ;;
    aurora-dx-surface)     IMAGE_REF="ghcr.io/l0g0ff/kompassos-dx-surface" ;;
    *)                     IMAGE_REF="ghcr.io/l0g0ff/kompassos-dx-hwe" ;;
esac

sbkey="https://github.com/ublue-os/akmods/raw/main/certs/public_key.der"

# Configure Live Environment
glib-compile-schemas /usr/share/glib-2.0/schemas

for service in tailscaled.service brew-upgrade.timer brew-update.timer brew-setup.service \
               uupd.timer ublue-system-setup.service flatpak-preinstall.service; do
    systemctl disable "$service" 2>/dev/null || true
done
for user_service in podman-auto-update.timer ublue-user-setup.service bazaar.service; do
    systemctl --global disable "$user_service" 2>/dev/null || true
done
rm -f /usr/share/applications/dev.getaurora.system-update.desktop

# Install Anaconda packages (mkdir needed for cockpit-ws-selinux scriptlet)
mkdir -p /var/lib/rpm-state
dnf install -y libblockdev-btrfs libblockdev-lvm libblockdev-dm anaconda-live anaconda-webui

# Anaconda profile
mkdir -p /etc/anaconda/profile.d
tee /etc/anaconda/profile.d/kompassos.conf <<'EOF'
[Profile]
profile_id = kompassos
base_profile = fedora-kinoite

[Profile Detection]
os_id = aurora
variant_id = kompassos

[Network]
default_on_boot = FIRST_WIRED_WITH_LINK

[Bootloader]
efi_dir = fedora
menu_auto_hide = True

[Storage]
default_scheme = BTRFS
btrfs_compression = zstd:1
default_partitioning =
    /     (min 1 GiB, max 70 GiB)
    /home (min 500 MiB, free 50 GiB)
    /var  (btrfs)

[User Interface]
webui_web_engine = slitherer
hidden_spokes =
    NetworkSpoke
    PasswordSpoke
    UserSpoke
hidden_webui_pages =
    root-password
    network
    anaconda-screen-accounts
EOF

# Pin liveinst to taskbar
KICKER_RC=/usr/share/kde-settings/kde-profile/default/xdg/kicker-extra-favoritesrc
if [[ -f "$KICKER_RC" ]]; then
    sed -i '2s/$/;liveinst.desktop/' "$KICKER_RC"
fi

. /etc/os-release
echo "KompassOS release $VERSION_ID" >/etc/system-release 2>/dev/null || true

sed -i 's/ANACONDA_PRODUCTVERSION=.*/ANACONDA_PRODUCTVERSION=""/' /usr/{,s}bin/liveinst 2>/dev/null || true

desktop-file-edit \
    --set-key=StartupWMClass --set-value=slitherer \
    /usr/share/applications/liveinst.desktop 2>/dev/null || true

# Remove Aurora welcome dialogs
rm -f /etc/xdg/autostart/ublue-welcome.desktop
rm -f /usr/share/applications/dev.getaurora.welcome.desktop

# Disable KWallet in live session
mkdir -p /etc/xdg
tee -a /etc/xdg/kwalletrc <<'EOF'
[Wallet]
Enabled=false
EOF

# Copy flatpaks for post-install transfer
cp -a /var/lib/flatpak /var/lib/flatpak_original

# Kickstart files
mkdir -p /usr/share/anaconda/post-scripts
tee /usr/share/anaconda/interactive-defaults.ks <<EOF
ostreecontainer --url=${IMAGE_REF}:${IMAGE_TAG} --transport=containers-storage --no-signature-verification
%include /usr/share/anaconda/post-scripts/install-configure-upgrade.ks
%include /usr/share/anaconda/post-scripts/disable-fedora-flatpak.ks
%include /usr/share/anaconda/post-scripts/install-flatpaks.ks
%include /usr/share/anaconda/post-scripts/secureboot-enroll-key.ks
EOF

tee /usr/share/anaconda/post-scripts/install-configure-upgrade.ks <<EOF
%post --erroronfail
bootc switch --mutate-in-place --enforce-container-sigpolicy --transport registry ${IMAGE_REF}:${IMAGE_TAG}
%end
EOF

tee /usr/share/anaconda/post-scripts/disable-fedora-flatpak.ks <<'EOF'
%post --erroronfail
systemctl disable flatpak-add-fedora-repos.service
%end
EOF

tee /usr/share/anaconda/post-scripts/install-flatpaks.ks <<'EOF'
%post --erroronfail --nochroot
deployment="$(ostree rev-parse --repo=/mnt/sysimage/ostree/repo ostree/0/1/0)"
target="/mnt/sysimage/ostree/deploy/default/deploy/$deployment.0/var/lib/"
mkdir -p "$target"
rsync -aAXUHKP /var/lib/flatpak_original/ "$target/flatpak"
sync
%end
EOF

# Fetch the Secureboot Public Key
curl --retry 15 -Lo /etc/sb_pubkey.der "$sbkey"

tee /usr/share/anaconda/post-scripts/secureboot-enroll-key.ks <<'EOF'
%post --erroronfail --nochroot
set -oue pipefail

readonly ENROLLMENT_PASSWORD="universalblue"
readonly SECUREBOOT_KEY="/etc/sb_pubkey.der"

if [[ ! -d "/sys/firmware/efi" ]]; then
    echo "EFI mode not detected. Skipping key enrollment."
    exit 0
fi

if [[ ! -f "$SECUREBOOT_KEY" ]]; then
    echo "Secure boot key not provided: $SECUREBOOT_KEY"
    exit 0
fi

SYS_ID="$(cat /sys/devices/virtual/dmi/id/product_name)"
if [[ ":Jupiter:Galileo:" =~ ":$SYS_ID:" ]]; then
    echo "Steam Deck hardware detected. Skipping key enrollment."
    exit 0
fi

mokutil --timeout -1 || :
echo -e "$ENROLLMENT_PASSWORD\n$ENROLLMENT_PASSWORD" | mokutil --import "$SECUREBOOT_KEY" || :
%end
EOF
