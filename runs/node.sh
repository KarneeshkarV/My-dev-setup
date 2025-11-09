#!/usr/bin/env bash

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source distro utilities
source "$PROJECT_ROOT/lib/distro-utils.sh"

# Initialize distro detection
init_distro

echo "Installing Node.js..."

case "$DISTRO" in
    arch)
        # Install Node.js from official Arch repos
        install_packages nodejs npm
        ;;
    debian)
        # Install Node.js from NodeSource repository
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt update
        install_packages nodejs
        ;;
esac

# Install global npm packages
echo "Installing Neovim npm package..."
sudo npm install -g neovim

# Verify installation
echo "Node.js installation complete!"
node -v
npm -v
