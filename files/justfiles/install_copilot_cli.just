# Test this Just file: /usr/bin/just --justfile files/justfiles/install_copilot_cli.just --choose

# Install Copilot CLI (PRERELEASE)
[group('Apps')]
install-copilot-cli:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh

    echo "${yellow}Note: Copilot CLI is currently in PRERELEASE${normal}"
    echo "- This installs the official GitHub Copilot CLI tool"
    echo "- Requires authentication with GitHub account"
    echo ""

    if $(gum confirm "Install Copilot CLI?"); then
        echo "${blue}Installing Copilot CLI...${normal}"
        brew install copilot-cli@prerelease
        echo "${green}Copilot CLI installed successfully!${normal}"
        echo ""
        echo "${blue}Next steps:${normal}"
        echo "- Run 'copilot auth' to authenticate with your GitHub account"
        echo "- Run 'copilot --help' for available commands"
    fi

# Update Copilot CLI
[group('Apps')]
update-copilot-cli:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh

    echo "${blue}Updating Copilot CLI...${normal}"
    brew upgrade copilot-cli@prerelease
    echo "${green}Copilot CLI updated successfully!${normal}"

