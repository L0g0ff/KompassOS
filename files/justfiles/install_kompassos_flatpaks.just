# Test this Just file: /usr/bin/just --justfile files/justfiles/install_kompassos_flatpaks.just --choose

# Install KompassOS flatpaks (re-run if network was unavailable during first boot)
[group('System')]
install-kompassos-flatpaks:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh

    echo "${yellow}Installing KompassOS Flatpaks${normal}"
    echo "This re-runs the flatpak setup configured in the KompassOS image."
    echo ""

    if $(gum confirm "Apply all KompassOS flatpaks?"); then
        echo "${blue}Running bluebuild-flatpak-manager...${normal}"
        bluebuild-flatpak-manager apply all
        echo "${green}Done!${normal}"
    fi
