# Test this Just file: /usr/bin/just --justfile files/justfiles/install_claude_code.just --choose

# Install Claude Code (BETA)
[group('Apps')]
install-claude-code:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh
    
    echo "${yellow}Note: Claude Code is currently in BETA${normal}"
    echo "- This installs the official Claude CLI tool from Anthropic"
    echo "- Requires authentication with Claude account"
    echo ""
    
    if $(gum confirm "Install Claude Code?"); then
        echo "${blue}Installing Claude Code...${normal}"
        curl -fsSL https://claude.ai/install.sh | bash -s latest
        echo "${green}Claude Code installed successfully!${normal}"
        echo ""
        echo "${blue}Next steps:${normal}"
        echo "- Run 'claude auth' to authenticate with your Claude account"
        echo "- Run 'claude --help' for available commands"
    fi

# Update Claude Code
[group('Apps')]
update-claude-code:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh
    
    echo "${blue}Updating Claude Code...${normal}"
    claude update
    echo "${green}Claude Code updated successfully!${normal}"

