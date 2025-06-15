# Test this Just file: /usr/bin/just --justfile files/justfiles/configure_bridge_networking.just --choose

# Setup br0 bridge for VM networking
[group('Network')]
setup-bridge:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh
    
    echo "${bold}Setting up br0 bridge for VM networking...${normal}"
    
    # Check available interfaces
    echo "Available network interfaces:"
    nmcli device status | grep -E "(ethernet|wifi)"
    echo ""
    
    # Find ethernet and wifi interfaces
    ETH_DEVICES=$(nmcli -t -f DEVICE,TYPE device | grep ethernet | cut -d: -f1)
    WIFI_DEVICES=$(nmcli -t -f DEVICE,TYPE device | grep wifi | cut -d: -f1)
    
    if [ -z "$ETH_DEVICES" ] && [ -z "$WIFI_DEVICES" ]; then
        echo "${red}No network interfaces found${normal}"
        exit 1
    fi
    
    # Build interface choices for ugum choose
    CHOICES=()
    CHOSEN_DEVICE=""
    DEVICE_TYPE=""
    
    # Add ethernet options
    if [ -n "$ETH_DEVICES" ]; then
        for device in $ETH_DEVICES; do
            CHOICES+=("${device} (ethernet)")
        done
    fi
    
    # Add wifi options with warning
    if [ -n "$WIFI_DEVICES" ]; then
        for device in $WIFI_DEVICES; do
            CHOICES+=("${device} (wifi - limited)")
        done
    fi
    
    # If only one ethernet device, use it automatically
    if [ ${#CHOICES[@]} -eq 1 ] && [[ "${CHOICES[0]}" == *"(ethernet)"* ]]; then
        CHOSEN_DEVICE=$(echo "${CHOICES[0]}" | cut -d' ' -f1)
        DEVICE_TYPE="ethernet"
        echo "Using ethernet interface: ${CHOSEN_DEVICE}"
    else
        # Multiple interfaces - let user choose with pijltjes
        echo "${bold}Select interface for bridging:${normal}"
        CHOICE=$(ugum choose "${CHOICES[@]}")
        
        # Extract device name and type from choice
        CHOSEN_DEVICE=$(echo "$CHOICE" | cut -d' ' -f1)
        if [[ "$CHOICE" == *"(ethernet)"* ]]; then
            DEVICE_TYPE="ethernet"
        else
            DEVICE_TYPE="wifi"
        fi
    fi
    
    # WiFi warning
    if [ "$DEVICE_TYPE" = "wifi" ]; then
        echo ""
        echo "${yellow}${bold}WARNING: WiFi Bridge Limitations${normal}"
        echo "${yellow}• WiFi bridging has limitations due to IEEE 802.11 standards${normal}"
        echo "${yellow}• VMs may not get direct LAN access like with ethernet bridging${normal}"
        echo "${yellow}• Some access points block bridged traffic entirely${normal}"
        echo "${yellow}• Consider using NAT networking (virbr0) for WiFi setups${normal}"
        echo ""
        if ! $(ugum confirm "Continue with WiFi bridging anyway?"); then
            echo "Bridge setup cancelled"
            exit 0
        fi
    fi
    
    # Create bridge connection
    sudo nmcli connection add type bridge \
        connection.id bridge ifname br0 bridge.stp no
    
    # Add chosen interface to bridge
    sudo nmcli connection add type ethernet \
        connection.id ether ifname ${CHOSEN_DEVICE} master bridge
    
    # Bring down existing connection
    EXISTING_CON=$(nmcli -t -f NAME,DEVICE connection show --active | grep ${CHOSEN_DEVICE} | cut -d: -f1)
    if [ -n "$EXISTING_CON" ]; then
        echo "Taking down existing connection: ${EXISTING_CON}"
        sudo nmcli con down "${EXISTING_CON}"
    fi
    
    # Activate bridge
    sudo nmcli connection up bridge
    sudo nmcli connection up ether
    
    # Add to QEMU bridge config
    if ! grep -q "allow br0" /etc/qemu/bridge.conf 2>/dev/null; then
        echo "allow br0" | sudo tee -a /etc/qemu/bridge.conf >/dev/null
    fi
    
    echo ""
    echo "${green}✓ Bridge br0 is now active using ${DEVICE_TYPE} interface ${CHOSEN_DEVICE}${normal}"
    if [ "$DEVICE_TYPE" = "ethernet" ]; then
        echo "VMs can now use bridged networking - they'll get IPs from your router"
    else
        echo "VMs will use WiFi bridging - functionality may be limited"
    fi
