# Test this Just file: /usr/bin/just --justfile files/justfiles/install_netextender.just --choose

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
        echo "    echo \"to connect use: nxcli connect\""
        echo '    reboot'
        echo '  SHELL'
        echo 'end'
    } > "$TARGET_DIR/Vagrantfile"

    echo "${green}${bold}Vagrantfile created successfully in: ${TARGET_DIR}${normal}"
    echo "Note: You'll need to modify the password in the generated Vagrantfile before using it."
    echo "To start the VM, run: cd ${TARGET_DIR} && vagrant up"
    if [ -n "$SSH_PUBLIC_KEY" ]; then
        echo "After the VM is running, you can connect directly with: ssh $CURRENT_USER@192.168.121.10"
        echo "After the you are ssh connected with the VM, you can you the command 'nxcli connect' to start the VPN connection"
        echo "Then can use the VM '192.168.121.10:22' as jumphost from you local machine to access the resources behind the VPN"
        echo "Happy connecting!"
    else
        echo "${yellow}No SSH key was found. You'll need to use 'vagrant ssh' to connect to the VM${normal}"
    fi
