# Test this Just file: /usr/bin/just --justfile files/justfiles/usroverlay.just --choose

# Mount a temporary writable overlay on /usr for testing packages (discarded on reboot)
[group('System')]
usroverlay:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh

    echo "${yellow}Temporary /usr Overlay${normal}"
    echo "This mounts a writable overlay on /usr for testing purposes."
    echo "${red}All changes will be discarded on reboot.${normal}"
    echo ""
    echo "Example usage after enabling:"
    echo "  ${blue}sudo dnf5 install <package>${normal}"
    echo ""

    if $(gum confirm "Enable temporary /usr overlay?"); then
        sudo bootc usroverlay
        echo ""
        echo "${green}Overlay active.${normal} You can now install packages temporarily with ${blue}sudo dnf5 install${normal}."
        echo "${red}Remember: all changes are lost on reboot.${normal}"
    fi
