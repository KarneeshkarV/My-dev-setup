#!/usr/bin/env bash

echo "Installing Neovim from source..."

rm -rf ~/.config/nvim/
# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source distro utilities
source "$PROJECT_ROOT/lib/distro-utils.sh"

# Initialize distro detection
init_distro

# Install build dependencies
echo "Installing build dependencies..."
install_mapped_packages ripgrep git xclip cmake gettext lua5.1 liblua5.1-0-dev unzip wget make

# Neovim version
version="${NVIM_VERSION:-v0.10.2}"
echo "Neovim version: \"$version\""

# Clone or update neovim repository
if [ ! -d "$HOME/neovim" ]; then
    echo "Cloning Neovim repository..."
    git clone https://github.com/neovim/neovim.git "$HOME/neovim" --depth 3
else
    echo "Neovim repository already exists"
fi

# Fetch and checkout version
git -C ~/neovim fetch --all
git -C ~/neovim checkout "$version"

# Build and install Neovim
echo "Building Neovim..."
make -C ~/neovim clean
make -C ~/neovim CMAKE_BUILD_TYPE=RelWithDebInfo
sudo make -C ~/neovim install

# Install Neovim config if not already present
if [ ! -d "${XDG_CONFIG_HOME:-$HOME/.config}/nvim" ]; then
    echo "Installing Neovim configuration..."
    git clone https://github.com/watninja68/karnee_neovim_config.git "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
else
    echo "Neovim config already exists"
fi

# Install Luarocks
if ! command_exists luarocks; then
    echo "Installing Luarocks..."
    cd /tmp
    wget --no-check-certificate https://luarocks.org/releases/luarocks-3.11.1.tar.gz
    tar zxpf luarocks-3.11.1.tar.gz
    cd luarocks-3.11.1
    ./configure && make && sudo make install
    cd ~
    rm -rf /tmp/luarocks-3.11.1*
else
    echo "Luarocks already installed"
fi

# Install luacheck
echo "Installing luacheck..."
sudo luarocks install luacheck

echo "Neovim installation complete!"
nvim --version
