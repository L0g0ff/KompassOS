# Test this Just file: /usr/bin/just --justfile files/justfiles/install_claude_distrobox.just --choose

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