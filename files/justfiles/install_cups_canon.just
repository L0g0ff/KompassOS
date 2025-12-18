# Test this Just file: /usr/bin/just --justfile files/justfiles/install_cups_canon.just --choose

# Install CUPS with Canon drivers in Distrobox
[group('Apps')]
install-cups-canon:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh
    echo "${green}Installing CUPS with Canon drivers in Distrobox...${normal}"
    distrobox-assemble create --file /usr/share/kompassos/distrobox/cups-canon/cups-distrobox.ini --replace && echo "${green}CUPS with Canon drivers installed successfully!${normal}" && echo "CUPS web interface available at: http://localhost:6631" && echo "To enter the container: distrobox enter cups-canon" && echo "To install the correct CUPS driver: sudo dpkg -i cnrdrvcups-ufr2-uk_6.10-1.03_amd64.deb and follow the wizard"

# Remove CUPS Canon distrobox
[group('Apps')]
remove-cups-canon:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh
    
    if $(gum confirm "Remove CUPS Canon distrobox?"); then
        echo "Stopping and removing distrobox..."
        distrobox stop cups-canon || true
        distrobox rm cups-canon || true
        
        echo "${green}CUPS Canon distrobox removed successfully!${normal}"
    fi

# Start CUPS service in distrobox
[group('Apps')]
start-cups-canon:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh
    echo "${green}Starting CUPS service...${normal}"
    distrobox enter cups-canon -- sudo systemctl start cups && echo "${green}CUPS started! Web interface: http://localhost:6631${normal}"

# Stop CUPS service in distrobox
[group('Apps')]
stop-cups-canon:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh
    echo "${green}Stopping CUPS service...${normal}"
    distrobox enter cups-canon -- sudo systemctl stop cups && echo "${green}CUPS stopped!${normal}"

# Check CUPS status
[group('Apps')]
status-cups-canon:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh
    echo "${green}CUPS status:${normal}"
    distrobox enter cups-canon -- systemctl status cups
