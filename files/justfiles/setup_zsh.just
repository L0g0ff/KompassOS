# Test this Just file: /usr/bin/just --justfile files/justfiles/setup_zsh.just --choose

# Setup zsh with Oh My Zsh and autosuggestions (fish-like autocomplete)
[group('System')]
setup-zsh:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh

    echo "${yellow}Zsh setup with Oh My Zsh${normal}"
    echo "- Installs Oh My Zsh (if not already present)"
    echo "- Adds zsh-autosuggestions (fish-like inline autocomplete)"
    echo "- Adds zsh-completions (enhanced tab completion)"
    echo "- Sets zsh as your default shell"
    echo ""

    if $(gum confirm "Continue with zsh setup?"); then
        # Install Oh My Zsh if not present
        if [ ! -d "$HOME/.oh-my-zsh" ]; then
            echo "${blue}Installing Oh My Zsh...${normal}"
            RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        else
            echo "${blue}Oh My Zsh already present, skipping.${normal}"
        fi

        # Install zsh-autosuggestions
        ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
        if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
            echo "${blue}Installing zsh-autosuggestions...${normal}"
            git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
        else
            echo "${blue}zsh-autosuggestions already present, skipping.${normal}"
        fi

        # Install zsh-completions
        if [ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ]; then
            echo "${blue}Installing zsh-completions...${normal}"
            git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"
        else
            echo "${blue}zsh-completions already present, skipping.${normal}"
        fi

        # Update plugins line in .zshrc if Oh My Zsh is configured
        if [ -f "$HOME/.zshrc" ]; then
            if grep -q 'plugins=(git)' "$HOME/.zshrc"; then
                sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-completions)/' "$HOME/.zshrc"
                echo "${blue}.zshrc updated with plugins.${normal}"
            elif ! grep -q 'zsh-autosuggestions' "$HOME/.zshrc"; then
                echo "${yellow}Manually add the following to .zshrc before 'source \$ZSH/oh-my-zsh.sh':${normal}"
                echo "  plugins=(git zsh-autosuggestions zsh-completions)"
            else
                echo "${blue}Plugins already configured in .zshrc.${normal}"
            fi
        fi

        # Set zsh as default shell
        if [ "$SHELL" != "$(which zsh)" ]; then
            echo "${blue}Setting zsh as default shell...${normal}"
            sudo usermod -s "$(which zsh)" "$USER"
            echo "${green}Zsh is now your default shell. Log out and back in to activate.${normal}"
        else
            echo "${blue}Zsh is already the default shell.${normal}"
        fi

        echo ""
        echo "${green}Setup complete!${normal}"
        echo "- Open a new terminal or run: exec zsh"
        echo "- Accept autosuggestions with → (right arrow)"
    fi
