#!/usr/bin/env bash

echo "Installing tmux and configuring plugins..."

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source distro utilities
source "$PROJECT_ROOT/lib/distro-utils.sh"

# Initialize distro detection
init_distro

# Install tmux
echo "Installing tmux package..."
install_packages tmux

# Initialize git submodules for tmux plugins
echo "Initializing tmux plugin submodules..."
cd "$PROJECT_ROOT" || exit 1
git submodule update --init --recursive stow/tmux/.tmux/plugins/tpm
git submodule update --init --recursive stow/tmux/.tmux/plugins/tmux
git submodule update --init --recursive stow/tmux/.tmux/plugins/tmux-resurrect
git submodule update --init --recursive stow/tmux/.tmux/plugins/tmux-sensible

# Stow tmux configuration
echo "Creating symlinks for tmux configuration..."
cd "$PROJECT_ROOT/stow" || exit 1
stow -v -t "$HOME" tmux

echo ""
echo "${GREEN}Tmux installed successfully!${NC}"
echo ""
echo "To complete plugin installation:"
echo "  1. Start tmux: ${YELLOW}tmux${NC}"
echo "  2. Press ${YELLOW}prefix + I${NC} (default: Ctrl+b then Shift+i) to install plugins"
echo ""
echo "Your tmux plugins will be automatically loaded on next tmux start."
