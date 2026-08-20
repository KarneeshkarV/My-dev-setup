#!/usr/bin/env bash
set -euo pipefail

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source distro utilities
source "$PROJECT_ROOT/lib/distro-utils.sh"

# Initialize distro detection
init_distro

echo "Installing Rust..."

# Ensure curl is installed
if ! command_exists curl; then
    install_packages curl
fi

# Install Rust using rustup (distro-agnostic)
if ! command_exists rustc; then
    echo "Installing Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
else
    echo "Rust already installed"
fi

# Source cargo environment
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

if ! command_exists cargo; then
    echo "cargo installation failed or $HOME/.cargo/bin is not on PATH"
    exit 1
fi

# Install exa (modern ls replacement)
if ! command_exists exa; then
    echo "Installing exa..."
    cargo install exa
else
    echo "exa already installed"
fi

echo "Rust installation complete!"
rustc --version
cargo --version
if ! command_exists just; then
    cargo install just
else
    echo "just already installed"
fi
