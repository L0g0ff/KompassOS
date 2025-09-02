# Test this Just file: /usr/bin/just --justfile files/justfiles/install_winboat.just --choose

# Install WinBoat - Run Windows applications on Linux
[group('Apps')]
install-winboat:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh
    
    echo "${yellow}Note: WinBoat is currently in BETA${normal}"
    echo "- Individual Windows apps may not work perfectly"
    echo "- The 'Windows Desktop App' is stable and recommended"
    echo ""
    
    if $(ugum confirm "Continue with WinBoat installation?"); then
        INSTALL_DIR="$HOME/.local/bin"
        mkdir -p "$INSTALL_DIR"
        
        echo "${blue}Downloading WinBoat...${normal}"
        LATEST_URL=$(curl -s https://api.github.com/repos/TibixDev/winboat/releases/latest | grep '"browser_download_url":.*\.AppImage"' | cut -d '"' -f 4)
        
        curl -L -o "$INSTALL_DIR/winboat.AppImage" "$LATEST_URL"
        chmod +x "$INSTALL_DIR/winboat.AppImage"
        
        # Download official icon
        echo "${blue}Downloading WinBoat icon...${normal}"
        mkdir -p "$HOME/.local/share/icons"
        curl -L -o "$HOME/.local/share/icons/winboat.png" "https://raw.githubusercontent.com/TibixDev/winboat/main/icons/icon.png"
        
        # Create desktop entry
        mkdir -p "$HOME/.local/share/applications"
        DESKTOP_PATH="$HOME/.local/share/applications/winboat.desktop"
        echo "[Desktop Entry]" > "$DESKTOP_PATH"
        echo "Name=WinBoat" >> "$DESKTOP_PATH" 
        echo "Comment=Run Windows applications on Linux" >> "$DESKTOP_PATH"
        echo "Exec=$HOME/.local/bin/winboat.AppImage" >> "$DESKTOP_PATH"
        echo "Icon=$HOME/.local/share/icons/winboat.png" >> "$DESKTOP_PATH"
        echo "Terminal=false" >> "$DESKTOP_PATH"
        echo "Type=Application" >> "$DESKTOP_PATH"
        echo "Categories=System" >> "$DESKTOP_PATH"
    
        echo "${green}WinBoat installed successfully!${normal}"
    fi

# Remove WinBoat
[group('Apps')]
remove-winboat:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh
    
    echo "${yellow}Note: This will only remove the WinBoat application${normal}"
    echo "- Your Windows VMs and data will be preserved"
    echo "- To remove VMs, use Virtual Machine Manager or WinBoat itself"
    echo ""
    
    if $(ugum confirm "Remove WinBoat application?"); then
        rm -f "$HOME/.local/bin/winboat.AppImage"
        rm -f "$HOME/.local/share/applications/winboat.desktop"
        rm -f "$HOME/.local/share/icons/winboat.png"
        echo "${green}WinBoat application removed${normal}"
        echo ""
        echo "${blue}Your Windows VMs remain untouched and can be managed via:${normal}"
        echo "- Virtual Machine Manager (virt-manager)"
        echo "- Docker containers: docker ps -a | grep winboat"
    fi