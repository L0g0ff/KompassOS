# Test this Just file: /usr/bin/just --justfile files/justfiles/generate_iso.just --choose

# Generate ISO for KompassOS DX HWE
[group('Apps')]
generate-iso-kompassos-dx-hwe:
    #!/usr/bin/env bash
    sudo bluebuild generate-iso --iso-name kompassos-dx-hwe.iso image ghcr.io/l0g0ff/kompassos-dx-hwe:latest

# Generate ISO for KompassOS DX HWE Nvidia
[group('Apps')]
generate-iso-kompassos-dx-hwe-nvidia:
    #!/usr/bin/env bash
    sudo bluebuild generate-iso --iso-name kompassos-dx-hwe-nvidia.iso image ghcr.io/l0g0ff/kompassos-dx-hwe-nvidia:latest