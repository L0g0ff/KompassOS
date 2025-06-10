# Test this Just file: /usr/bin/just --justfile files/justfiles/kompassos.just --choose

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

# Install vagrant https://thenets.org/running-vagrant-libvirt-on-bluefin-or-aurora/
[group('Apps')]
install-vagrant:
    #!/usr/bin/env bash
    # Install the libvirt-devel - libvirt-devel already installed in KompassOS
    # rpm-ostree install libvirt-devel
    # Add the hashicorp/tap repo
    brew tap hashicorp/tap
    # Install vagrant for Linux
    brew install hashicorp/tap/vagrant
    # Install the vagrant-libvirt plugin
    vagrant plugin install vagrant-libvirt

# Setup NetExtender VPN with Vagrant
[group('Apps')]
setup-netextender-vagrant vpn_server="" vpn_port="" vpn_domain="" vpn_user="" target_dir="":
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh

    # Check if vagrant is installed
    if ! command -v vagrant &> /dev/null; then
        echo "${red}${bold}Warning: Vagrant is not installed!${normal}"
        echo "Would you like to install Vagrant now?"
        if $(ugum confirm "Install Vagrant?"); then
            echo "Installing Vagrant..."
            just install-vagrant
        else
            echo "${yellow}Please install Vagrant first using: just install-vagrant${normal}"
            exit 1
        fi
    fi

    # Check if vagrant-libvirt plugin is installed
    if ! vagrant plugin list | grep -q vagrant-libvirt; then
        echo "${red}${bold}Warning: vagrant-libvirt plugin is not installed!${normal}"
        echo "Would you like to install the vagrant-libvirt plugin now?"
        if $(ugum confirm "Install vagrant-libvirt plugin?"); then
            vagrant plugin install vagrant-libvirt
        else
            echo "${yellow}Please install the vagrant-libvirt plugin first using: vagrant plugin install vagrant-libvirt${normal}"
            exit 1
        fi
    fi

    # Set default directory
    DEFAULT_DIR="$HOME/virt/netextender"

    # Check for SSH key
    if [ ! -f "$HOME/.ssh/id_rsa.pub" ]; then
        echo "${yellow}${bold}No SSH key found at $HOME/.ssh/id_rsa.pub${normal}"
        echo "Would you like to generate one?"
        if $(ugum confirm "Generate SSH key?"); then
            ssh-keygen -t rsa -b 4096
        fi
    fi

    # Get SSH public key
    SSH_PUBLIC_KEY=$(cat $HOME/.ssh/id_rsa.pub 2>/dev/null || echo "")
    CURRENT_USER=$(whoami)

    # If no target directory provided, ask for it
    if [ -z "{{ target_dir }}" ]; then
        echo "${bold}Where would you like to save the Vagrant configuration?${normal}"
        echo "1. Default directory ($DEFAULT_DIR)"
        echo "2. Current directory ($(pwd))"
        echo "3. Custom location"
        
        LOCATION_CHOICE=$(ugum choose "Default directory" "Current directory" "Custom location")
        
        case "$LOCATION_CHOICE" in
            "Default directory")
                TARGET_DIR="$DEFAULT_DIR"
                ;;
            "Current directory")
                TARGET_DIR=$(pwd)
                ;;
            "Custom location")
                TARGET_DIR=$(ugum input --placeholder="Enter full path for configuration")
                ;;
        esac
    else
        TARGET_DIR="{{ target_dir }}"
    fi

    # Create target directory if it doesn't exist
    if [ ! -d "$TARGET_DIR" ]; then
        echo "Creating directory: $TARGET_DIR"
        mkdir -p "$TARGET_DIR"
    fi

    # If no parameters provided, prompt for them
    if [ -z "{{ vpn_server }}" ] || [ -z "{{ vpn_port }}" ] || [ -z "{{ vpn_domain }}" ] || [ -z "{{ vpn_user }}" ]; then
        echo "${bold}NetExtender Vagrant Configuration${normal}"
        echo "Please provide the following details:"
        
        VPN_SERVER=$(ugum input --placeholder="VPN Server (e.g. vpn.example.org)" --value="{{ vpn_server }}")
        VPN_PORT=$(ugum input --placeholder="VPN Port (e.g. 4433)" --value="{{ vpn_port }}")
        VPN_DOMAIN=$(ugum input --placeholder="VPN Domain" --value="{{ vpn_domain }}")
        VPN_USER=$(ugum input --placeholder="VPN Username" --value="{{ vpn_user }}")
    else
        VPN_SERVER="{{ vpn_server }}"
        VPN_PORT="{{ vpn_port }}"
        VPN_DOMAIN="{{ vpn_domain }}"
        VPN_USER="{{ vpn_user }}"
    fi

    # Write Vagrantfile
    {
        echo '# -*- mode: ruby -*-'
        echo '# vi: set ft=ruby :'
        echo ''
        echo 'Vagrant.configure("2") do |config|'
        echo '  config.vm.box = "generic/ubuntu2204"'
        echo '  config.vm.box_version = "4.3.12"'
        echo ''
        echo '  config.vm.network "private_network", ip: "192.168.121.10"'
        echo ''
        echo '  config.vm.provider "libvirt" do |libvirt|'
        echo '    libvirt.cpus = 1'
        echo '    libvirt.memory = 1024'
        echo '  end'
        echo ''
        if [ -n "$SSH_PUBLIC_KEY" ]; then
            echo '  config.vm.provision "shell", inline: <<-SHELL'
            echo '    # Create user if it doesn'"'"'t exist'
            echo "    if ! id -u $CURRENT_USER >/dev/null 2>&1; then"
            echo "      useradd -m -s /bin/bash $CURRENT_USER"
            echo "      # Add user to sudo group"
            echo "      usermod -aG sudo $CURRENT_USER"
            echo "      # Set up password-less sudo for the user"
            echo "      echo '$CURRENT_USER ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$CURRENT_USER"
            echo "    fi"
            echo ''
            echo "    # Set up SSH key"
            echo "    mkdir -p /home/$CURRENT_USER/.ssh"
            echo "    echo '$SSH_PUBLIC_KEY' > /home/$CURRENT_USER/.ssh/authorized_keys"
            echo "    chmod 700 /home/$CURRENT_USER/.ssh"
            echo "    chmod 600 /home/$CURRENT_USER/.ssh/authorized_keys"
            echo "    chown -R $CURRENT_USER:$CURRENT_USER /home/$CURRENT_USER/.ssh"
            echo '  SHELL'
            echo ''
        fi
        echo '  config.vm.provision "shell", inline: <<-SHELL'
        echo '    printf "\nDisk free space before...\n"'
        echo '    df -lhT /'
        echo '    apt-get update'
        echo '    apt-get install -y default-jre wget'
        echo '    printf "\nAllowTcpForwarding..\n"'
        echo '    sudo sed -i "s/#AllowTcpForwarding yes/AllowTcpForwarding yes/g" /etc/ssh/sshd_config'
        echo '    wget https://software.sonicwall.com/NetExtender/NetExtender-linux-amd64-10.3.0-21.tar.gz'
        echo '    tar -zxvf NetExtender-linux-amd64-10.3.0-21.tar.gz'
        echo '    cd netextender'
        echo '    sudo ./install.sh'
        echo ''
        echo '    sudo cat >/etc/networkd-dispatcher/routable.d/50-ifup-hooks <<EOFHOOK'
        echo '#!/bin/sh'
        echo 'if ! iptables -t nat -C POSTROUTING -o snwl_ssltunnel -j MASQUERADE 2>/dev/null'
        echo 'then'
        echo "    nxcli connection delete $VPN_DOMAIN"
        echo "    nxcli connection add $VPN_DOMAIN --server $VPN_SERVER:$VPN_PORT --username=$VPN_USER --password=CHANGE_ME --domain=$VPN_DOMAIN --protocol Auto"
        echo '    echo 1 > /proc/sys/net/ipv4/ip_forward'
        echo '    iptables -t nat -A POSTROUTING -o snwl_ssltunnel -j MASQUERADE'
        echo 'fi'
        echo 'exit 0'
        echo 'EOFHOOK'
        echo ''
        echo '    sudo chmod 755 /etc/networkd-dispatcher/routable.d/50-ifup-hooks'
        echo ''
        echo '    sudo echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/ip_forward.conf'
        echo '    echo "add the following to the host system: ip route add 10.5.50.0/24 via 192.168.121.10"'
        echo "    echo \"to connect use: nxcli connect""
        echo '    reboot'
        echo '  SHELL'
        echo 'end'
    } > "$TARGET_DIR/Vagrantfile"

    echo "${green}${bold}Vagrantfile created successfully in: ${TARGET_DIR}${normal}"
    echo "Note: You'll need to modify the password in the generated Vagrantfile before using it."
    echo "To start the VM, run: cd ${TARGET_DIR} && vagrant up"
    if [ -n "$SSH_PUBLIC_KEY" ]; then
        echo "After the VM is running, you can connect directly with: ssh $CURRENT_USER@192.168.121.10"
    else
        echo "${yellow}No SSH key was found. You'll need to use 'vagrant ssh' to connect to the VM${normal}"
    fi

# Install Claude Desktop in Distrobox
[group('Apps')]
install-claude-desktop:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh
    distrobox create --name claude --image ubuntu:22.04 || true && distrobox enter claude -- bash -c 'sudo apt update && sudo apt install -y wget curl && curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && sudo apt-get install -y nodejs libatk-bridge2.0-0 libgtk-3-0 libgbm1 && sudo npm install -g electron && wget -O- https://raw.githubusercontent.com/emsi/claude-desktop/refs/heads/main/install-claude-desktop.sh | bash && distrobox-export --app claude-desktop' && echo "To run claude-desktop, use the command: claude-desktop"

# Remove Claude Desktop distrobox
[group('Apps')]
remove-claude-desktop:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh
    
    if $(ugum confirm "Remove Claude Desktop distrobox?"); then
        echo "Removing exported applications..."
        distrobox-export --app claude-desktop --delete || true
        
        echo "Stopping and removing distrobox..."
        distrobox stop claude || true
        distrobox rm claude || true
        
        echo "${green}Claude Desktop distrobox removed successfully!${normal}"
    fi

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
