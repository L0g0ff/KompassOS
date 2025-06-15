# Test this Just file: /usr/bin/just --justfile files/justfiles/kompassos.just --choose

# Show bridge status
[group('Network')]
bridge-status:
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh
    
    echo "${bold}Bridge Status${normal}"
    echo ""
    
    # Check if br0 exists
    if ip link show br0 &>/dev/null; then
        echo "${green}✓ br0 bridge is active${normal}"
        echo ""
        ip addr show br0
        echo ""
        echo "${bold}Bridge interfaces:${normal}"
        bridge link show | grep br0 || echo "No interfaces found"
    else
        echo "${yellow}○ br0 bridge not found${normal}"
    fi
    
    echo ""
    echo "${bold}QEMU bridge config:${normal}"
    cat /etc/qemu/bridge.conf 2>/dev/null || echo "No config found"
