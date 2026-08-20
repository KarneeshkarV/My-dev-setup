#!/usr/bin/env bash
set -euo pipefail

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source distro utilities
source "$PROJECT_ROOT/lib/distro-utils.sh"

# Initialize distro detection
init_distro

echo "=== Tmux Setup ==="

if ! command_exists tmux; then
    echo "Installing tmux..."
    install_packages tmux
else
    echo "tmux is already installed"
fi

echo "Initializing tmux plugin submodules..."
git -C "$PROJECT_ROOT" submodule update --init --recursive stow/tmux/.tmux/plugins/tpm stow/tmux/.tmux/plugins/tmux stow/tmux/.tmux/plugins/tmux-resurrect stow/tmux/.tmux/plugins/tmux-sensible

echo "Tmux installation complete!"
tmux -V
