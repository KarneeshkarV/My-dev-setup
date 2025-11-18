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

install_packages  yazi ffmpeg 7zip jq poppler fd ripgrep fzf zoxide resvg imagemagick

# Install fzf (distro-agnostic)
if [ ! -d ~/.fzf ]; then
    echo "Installing fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all
else
    echo "fzf already installed"
fi

fzf --version

# Install Homebrew if not present
if ! command_exists brew; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for this session
    if [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
else
    echo "Homebrew already installed"
fi

# Install gh CLI via Homebrew
if command_exists brew; then
    echo "Installing gh CLI..."
    brew install gh
else
    echo "Homebrew not available. Skipping gh CLI installation."
fi

# Install Rust CLI tools via cargo
if command_exists cargo; then
    echo "Installing Rust CLI tools..."
    cargo install git-delta
    cargo install du-dust
else
    echo "cargo not found. Skipping Rust tools installation."
    echo "Run rust.sh first to install Rust."
fi
