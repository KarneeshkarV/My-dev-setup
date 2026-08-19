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

# Latest master commit whose `test.yml` CI run succeeded. Fallback: nightly tag.
resolve_healthy_nvim_sha() {
    python3 - <<'PY'
import json, sys, urllib.request

url = (
    "https://api.github.com/repos/neovim/neovim/actions/workflows/test.yml/runs"
    "?branch=master&event=push&status=success&per_page=5"
)
req = urllib.request.Request(
    url,
    headers={
        "Accept": "application/vnd.github+json",
        "User-Agent": "myDev-setup-nvim",
    },
)
try:
    with urllib.request.urlopen(req, timeout=30) as resp:
        data = json.load(resp)
except Exception as exc:
    sys.stderr.write(f"GitHub API lookup failed: {exc}\n")
    sys.exit(1)

for run in data.get("workflow_runs", []):
    sha = run.get("head_sha")
    if sha and run.get("head_branch") == "master":
        print(sha)
        sys.exit(0)
sys.exit(1)
PY
}

NVIM_REPO="https://github.com/neovim/neovim.git"
NVIM_SHA="${NVIM_SHA:-}"
if [ -z "$NVIM_SHA" ]; then
    NVIM_SHA="$(resolve_healthy_nvim_sha || true)"
fi

if [ -n "$NVIM_SHA" ]; then
    echo "Neovim version: CI-green master $NVIM_SHA"
    if [ ! -d "$HOME/neovim" ]; then
        git clone --filter=blob:none --no-checkout "$NVIM_REPO" "$HOME/neovim"
    fi
    git -C "$HOME/neovim" fetch --depth 1 origin "$NVIM_SHA"
    git -C "$HOME/neovim" checkout --detach FETCH_HEAD
else
    echo "Neovim version: nightly tag (API lookup failed)"
    if [ ! -d "$HOME/neovim" ]; then
        git clone --depth 1 --branch nightly "$NVIM_REPO" "$HOME/neovim"
    else
        git -C "$HOME/neovim" fetch --depth 1 origin tag nightly --force
        git -C "$HOME/neovim" checkout --detach FETCH_HEAD
    fi
fi
echo "Checked out $(git -C "$HOME/neovim" rev-parse --short HEAD)"

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
