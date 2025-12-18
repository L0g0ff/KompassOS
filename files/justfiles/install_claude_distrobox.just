# Test this Just file: /usr/bin/just --justfile files/justfiles/install_claude_distrobox.just --choose

# Install Claude Desktop in Distrobox
[group('Apps')]
install-claude-desktop:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh
    distrobox-assemble create --file /usr/share/kompassos/distrobox/claude-desktop/claude-distrobox.ini

# Remove Claude Desktop distrobox
[group('Apps')]
remove-claude-desktop:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh
    
    if $(gum confirm "Remove Claude Desktop distrobox?"); then
        distrobox assemble rm --file /usr/share/kompassos/distrobox/claude-desktop/claude-distrobox.ini
        echo "${green}Claude Desktop distrobox removed successfully!${normal}"
    fi