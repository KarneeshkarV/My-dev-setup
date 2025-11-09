#!/usr/bin/env bash

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source distro utilities
source "$PROJECT_ROOT/lib/distro-utils.sh"

# Initialize distro detection
init_distro

# Install CLI tools
install_mapped_packages copyq bat xclip xdotool maim zoxide rofi gcc cmake make ninja-build gdb doxygen

# Arch uses just 'gcc' which includes g++, Ubuntu uses separate packages
if [ "$DISTRO" = "debian" ]; then
    install_packages g++
fi

# Audio system
install_packages pulseaudio pavucontrol

# Install fzf (distro-agnostic)
if [ ! -d ~/.fzf ]; then
    echo "Installing fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all
else
    echo "fzf already installed"
fi

fzf --version

# Install Rust CLI tools via cargo
if command_exists cargo; then
    echo "Installing Rust CLI tools..."
    cargo install git-delta
    cargo install du-dust
else
    echo "cargo not found. Skipping Rust tools installation."
    echo "Run rust.sh first to install Rust."
fi
