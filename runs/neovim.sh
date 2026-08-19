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

# Build from current origin/master HEAD
echo "Neovim version: origin/master HEAD"

if [ ! -d "$HOME/neovim" ]; then
    echo "Cloning Neovim repository..."
    git clone --depth 1 --branch master https://github.com/neovim/neovim.git "$HOME/neovim"
else
    echo "Updating Neovim repository to origin/master..."
    git -C "$HOME/neovim" fetch --depth 1 origin master
    git -C "$HOME/neovim" checkout -B master origin/master
fi

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
    wget https://luarocks.org/releases/luarocks-3.11.1.tar.gz
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
