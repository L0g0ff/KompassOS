# Test this Just file: /usr/bin/just --justfile files/justfiles/fix_dell_wd25.just --choose

# Fix screen blanking/flickering with Dell WD25 docking station (requires reboot)
[group('System')]
fix-dell-wd25:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh

    echo "${yellow}Dell WD25 Docking Station Fix${normal}"
    echo "Applies kernel parameters to fix screen blanking and flickering:"
    echo "  ${blue}i915.enable_psr=0 i915.enable_fbc=0 iommu=pt pcie_ports=native${normal}"
    echo ""
    echo "${red}A reboot is required for the changes to take effect.${normal}"
    echo ""

    if $(gum confirm "Apply kernel parameters?"); then
        sudo rpm-ostree kargs --append='i915.enable_psr=0' --append='i915.enable_fbc=0' --append='iommu=pt' --append='pcie_ports=native'
        echo ""
        echo "${green}Kernel parameters applied.${normal} Please reboot to activate the fix."
    fi
