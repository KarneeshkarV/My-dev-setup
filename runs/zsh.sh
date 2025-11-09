#!/usr/bin/env bash

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source distro utilities
source "$PROJECT_ROOT/lib/distro-utils.sh"

# Initialize distro detection
init_distro

echo "=== ZSH Setup ==="

# Install zsh if not already installed
if ! command_exists zsh; then
    echo "Installing zsh..."
    install_packages zsh
else
    echo "zsh is already installed"
fi

# Get zsh path
ZSH_PATH=$(which zsh)
echo "ZSH path: $ZSH_PATH"

# Check if zsh is already the default shell
if [ "$SHELL" = "$ZSH_PATH" ]; then
    echo "zsh is already your default shell!"
else
    echo "Changing default shell to zsh..."

    # Check if zsh is in /etc/shells
    if ! grep -q "$ZSH_PATH" /etc/shells; then
        echo "Adding $ZSH_PATH to /etc/shells..."
        echo "$ZSH_PATH" | sudo tee -a /etc/shells
    fi

    # Change the default shell
    echo "Running chsh to set zsh as default shell..."
    chsh -s "$ZSH_PATH"

    if [ $? -eq 0 ]; then
        echo "✓ Default shell changed to zsh successfully!"
        echo ""
        echo "IMPORTANT: You need to log out and log back in for the change to take effect."
        echo "Alternatively, you can start a new zsh session by running: zsh"
        echo ""

        # Ask if user wants to restart now
        read -p "Would you like to start a new zsh session now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Starting zsh..."
            exec zsh
        fi
    else
        echo "✗ Failed to change default shell"
        exit 1
    fi
fi

# Install Starship prompt
echo ""
echo "=== Starship Prompt Setup ==="

if ! command_exists starship; then
    echo "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y

    if [ $? -eq 0 ]; then
        echo "✓ Starship installed successfully!"
    else
        echo "✗ Failed to install Starship"
        echo "You can manually install it later with: curl -sS https://starship.rs/install.sh | sh"
    fi
else
    echo "Starship is already installed"
fi

# Add scripts directory to PATH
SCRIPTS_DIR="$PROJECT_ROOT/stow/scripts/.local/scripts"
ZSHRC="$HOME/.zshrc"

if [ -d "$SCRIPTS_DIR" ]; then
    echo ""
    echo "Setting up scripts directory in PATH..."

    # Check if already in .zshrc
    if [ -f "$ZSHRC" ]; then
        if grep -q "$SCRIPTS_DIR" "$ZSHRC"; then
            echo "Scripts directory already in .zshrc"
        else
            echo "Adding scripts directory to .zshrc..."
            echo "" >> "$ZSHRC"
            echo "# Add local scripts to PATH" >> "$ZSHRC"
            echo "export PATH=\"$SCRIPTS_DIR:\$PATH\"" >> "$ZSHRC"
            echo "✓ Scripts directory added to PATH in .zshrc"
        fi
    else
        echo "Creating .zshrc and adding scripts directory..."
        echo "# Add local scripts to PATH" > "$ZSHRC"
        echo "export PATH=\"$SCRIPTS_DIR:\$PATH\"" >> "$ZSHRC"
        echo "✓ .zshrc created with scripts directory in PATH"
    fi
else
    echo "⚠ Scripts directory not found: $SCRIPTS_DIR"
fi

# Initialize Starship in .zshrc
curl -sS https://starship.rs/install.sh | sh
if command_exists starship; then
    echo ""
    echo "Setting up Starship initialization..."

    if [ -f "$ZSHRC" ]; then
        if grep -q "starship init zsh" "$ZSHRC"; then
            echo "Starship already initialized in .zshrc"
        else
            echo "Adding Starship initialization to .zshrc..."
            echo "" >> "$ZSHRC"
            echo "# Initialize Starship prompt" >> "$ZSHRC"
            echo 'eval "$(starship init zsh)"' >> "$ZSHRC"
            echo "✓ Starship initialization added to .zshrc"
        fi
    else
        echo "Creating .zshrc and adding Starship initialization..."
        echo "# Initialize Starship prompt" > "$ZSHRC"
        echo 'eval "$(starship init zsh)"' >> "$ZSHRC"
        echo "✓ .zshrc created with Starship initialization"
    fi
fi
