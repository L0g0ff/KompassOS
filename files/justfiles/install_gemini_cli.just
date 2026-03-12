# Test this Just file: /usr/bin/just --justfile files/justfiles/install_gemini_cli.just --choose

# Install Gemini CLI
[group('Apps')]
install-gemini-cli:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh

    echo "- This installs the Gemini CLI tool"
    echo ""

    if $(gum confirm "Install Gemini CLI?"); then
        echo "${blue}Installing Gemini CLI...${normal}"
        brew install gemini-cli
        echo "${green}Gemini CLI installed successfully!${normal}"
        echo ""
        echo "${blue}Next steps:${normal}"
        echo "- Run 'gemini --help' for available commands"
    fi

# Update Gemini CLI
[group('Apps')]
update-gemini-cli:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh

    echo "${blue}Updating Gemini CLI...${normal}"
    brew upgrade gemini-cli
    echo "${green}Gemini CLI updated successfully!${normal}"

