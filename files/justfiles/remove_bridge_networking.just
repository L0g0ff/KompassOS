# Test this Just file: /usr/bin/just --justfile files/justfiles/show_bridge_networking.just --choose

# Remove br0 bridge
[group('Network')]
remove-bridge:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh
    
    if $(ugum confirm "Remove br0 bridge and restore normal networking?"); then
        echo "Removing bridge..."
        
        # Remove bridge connections
        sudo nmcli con down bridge 2>/dev/null || true
        sudo nmcli con down ether 2>/dev/null || true
        sudo nmcli con delete bridge 2>/dev/null || true
        sudo nmcli con delete ether 2>/dev/null || true
        
        # Remove br0 from QEMU config (keep virbr0)
        sudo sed -i '/allow br0/d' /etc/qemu/bridge.conf 2>/dev/null || true
        
        # Restart NetworkManager to recreate default connections
        sudo systemctl restart NetworkManager
        
        echo "${green}✓ Bridge removed - normal networking restored${normal}"
    fi
