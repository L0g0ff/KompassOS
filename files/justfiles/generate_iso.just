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
    sudo bluebuild generate-iso --iso-name kompassos-dx-hwe.iso image ghcr.io/l0g0ff/kompassos-dx-hwe:latest
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
    sudo bluebuild generate-iso --iso-name kompassos-dx-hwe-nvidia.iso image ghcr.io/l0g0ff/kompassos-dx-hwe-nvidia:latest
    echo "ISO generated successfully in ~/iso/"