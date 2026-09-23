# Test this Just file: /usr/bin/just --justfile files/justfiles/generate_iso.just --choose

# Generate ISO for KompassOS DX HWE
[group('Apps')]
generate-iso-kompassos-dx-hwe:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Creating ISO directory..."
    mkdir -p ~/iso
    echo "Changing to ISO directory..."
    cd ~/iso
    echo "Generating ISO..."
    rm -f kompassos-dx-hwe.iso kompassos-dx-hwe.iso-CHECKSUM
    # Calls the installer container directly: bluebuild generate-iso pins v1.4.0,
    # whose lorax templates strip /usr/sbin/load_policy (anaconda 44.30 exit crash).
    sudo podman run --rm --privileged \
        -v "$PWD":/build-container-installer/build \
        -v dnf-cache:/cache/dnf/ \
        ghcr.io/jasonn3/build-container-installer:v1.5.0 \
        VARIANT=Kinoite \
        ISO_NAME=build/kompassos-dx-hwe.iso \
        DNF_CACHE=/cache/dnf \
        SECURE_BOOT_KEY_URL=https://github.com/ublue-os/bazzite/raw/main/secure_boot.der \
        ENROLLMENT_PASSWORD=universalblue \
        WEB_UI=false \
        IMAGE_NAME=kompassos-dx-hwe \
        IMAGE_REPO=ghcr.io/l0g0ff \
        IMAGE_TAG=latest \
        VERSION=44
    echo "ISO generated successfully in ~/iso/"

# Generate ISO for KompassOS DX HWE Nvidia
[group('Apps')]
generate-iso-kompassos-dx-hwe-nvidia:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Creating ISO directory..."
    mkdir -p ~/iso
    echo "Changing to ISO directory..."
    cd ~/iso
    echo "Generating ISO..."
    rm -f kompassos-dx-hwe-nvidia.iso kompassos-dx-hwe-nvidia.iso-CHECKSUM
    # Calls the installer container directly: bluebuild generate-iso pins v1.4.0,
    # whose lorax templates strip /usr/sbin/load_policy (anaconda 44.30 exit crash).
    sudo podman run --rm --privileged \
        -v "$PWD":/build-container-installer/build \
        -v dnf-cache:/cache/dnf/ \
        ghcr.io/jasonn3/build-container-installer:v1.5.0 \
        VARIANT=Kinoite \
        ISO_NAME=build/kompassos-dx-hwe-nvidia.iso \
        DNF_CACHE=/cache/dnf \
        SECURE_BOOT_KEY_URL=https://github.com/ublue-os/bazzite/raw/main/secure_boot.der \
        ENROLLMENT_PASSWORD=universalblue \
        WEB_UI=false \
        IMAGE_NAME=kompassos-dx-hwe-nvidia \
        IMAGE_REPO=ghcr.io/l0g0ff \
        IMAGE_TAG=latest \
        VERSION=44
    echo "ISO generated successfully in ~/iso/"

# Generate ISO for KompassOS DX Surface
[group('Apps')]
generate-iso-kompassos-dx-surface:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Creating ISO directory..."
    mkdir -p ~/iso
    echo "Changing to ISO directory..."
    cd ~/iso
    echo "Generating ISO..."
    rm -f kompassos-dx-surface.iso kompassos-dx-surface.iso-CHECKSUM
    # Calls the installer container directly: bluebuild generate-iso pins v1.4.0,
    # whose lorax templates strip /usr/sbin/load_policy (anaconda 44.30 exit crash).
    sudo podman run --rm --privileged \
        -v "$PWD":/build-container-installer/build \
        -v dnf-cache:/cache/dnf/ \
        ghcr.io/jasonn3/build-container-installer:v1.5.0 \
        VARIANT=Kinoite \
        ISO_NAME=build/kompassos-dx-surface.iso \
        DNF_CACHE=/cache/dnf \
        SECURE_BOOT_KEY_URL=https://raw.githubusercontent.com/linux-surface/linux-surface/master/pkg/keys/surface.cer \
        ENROLLMENT_PASSWORD=universalblue \
        WEB_UI=false \
        IMAGE_NAME=kompassos-dx-surface \
        IMAGE_REPO=ghcr.io/l0g0ff \
        IMAGE_TAG=latest \
        VERSION=44
    echo "ISO generated successfully in ~/iso/"