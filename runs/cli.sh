#!/usr/bin/env bash
set -euo pipefail

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

install_packages  yazi ffmpeg 7zip jq poppler fd ripgrep fzf zoxide resvg imagemagick mosh

# Ubuntu 24.04 does not package fastfetch directly, so install the upstream binary.
if ! command_exists fastfetch; then
    echo "Installing fastfetch..."
    FASTFETCH_VERSION="${FASTFETCH_VERSION:-2.63.1}"
    FASTFETCH_TARBALL="fastfetch-linux-amd64.tar.gz"
    FASTFETCH_URL="https://github.com/fastfetch-cli/fastfetch/releases/download/${FASTFETCH_VERSION}/${FASTFETCH_TARBALL}"
    FASTFETCH_TMP="$(mktemp -d)"
    curl -fsSL "$FASTFETCH_URL" -o "$FASTFETCH_TMP/$FASTFETCH_TARBALL"
    tar -xzf "$FASTFETCH_TMP/$FASTFETCH_TARBALL" -C "$FASTFETCH_TMP"
    mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
    rm -rf "$HOME/.local/opt/fastfetch"
    mv "$FASTFETCH_TMP/fastfetch-linux-amd64" "$HOME/.local/opt/fastfetch"
    ln -sf "$HOME/.local/opt/fastfetch/usr/bin/fastfetch" "$HOME/.local/bin/fastfetch"
    rm -rf "$FASTFETCH_TMP"
else
    echo "fastfetch already installed"
fi

# Install fzf (distro-agnostic)
if [ ! -d ~/.fzf ]; then
    echo "Installing fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all
else
    echo "fzf already installed"
fi

export PATH="$HOME/.fzf/bin:$PATH"
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
if command_exists brew; then
    brew install steipete/tap/gogcli
else
    echo "Homebrew not available. Skipping gogcli installation."
fi
