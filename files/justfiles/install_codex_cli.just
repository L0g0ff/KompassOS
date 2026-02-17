# Test this Just file: /usr/bin/just --justfile files/justfiles/install_codex_cli.just --choose

# Install Codex CLI
[group('Apps')]
install-codex-cli:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh

    echo "- This installs the Codex CLI tool"
    echo ""

    if $(gum confirm "Install Codex CLI?"); then
        echo "${blue}Installing Codex CLI...${normal}"
        brew install codex
        echo "${green}Codex CLI installed successfully!${normal}"
        echo ""
        echo "${blue}Next steps:${normal}"
        echo "- Run 'codex --help' for available commands"
    fi

# Update Codex CLI
[group('Apps')]
update-codex-cli:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh

    echo "${blue}Updating Codex CLI...${normal}"
    brew upgrade codex
    echo "${green}Codex CLI updated successfully!${normal}"

