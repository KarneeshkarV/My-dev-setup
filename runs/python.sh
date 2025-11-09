#!/usr/bin/env bash

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source distro utilities
source "$PROJECT_ROOT/lib/distro-utils.sh"

# Initialize distro detection
init_distro

echo "Installing Python..."

case "$DISTRO" in
    arch)
        # Install Python from official Arch repos (always latest)
        install_packages python python-pip python-virtualenv curl

        # Create python3.11 symlink if needed for compatibility
        if ! command_exists python3.11; then
            sudo ln -sf /usr/bin/python3 /usr/bin/python3.11 2>/dev/null || true
        fi
        ;;
    debian)
        # Install prerequisites
        install_mapped_packages curl software-properties-common

        # Add deadsnakes PPA for Python 3.11
        sudo add-apt-repository ppa:deadsnakes/ppa -y
        sudo apt update

        # Install Python 3.11 and venv
        install_packages python3.11 python3.11-venv

        # Install pip for Python 3.11
        curl -sS https://bootstrap.pypa.io/get-pip.py | sudo python3.11
        ;;
esac

# Install uv (Python package manager)
if ! command_exists uv; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh

    # Source the environment
    if [ -f "$HOME/.local/bin/env" ]; then
        source "$HOME/.local/bin/env"
    fi
else
    echo "uv already installed"
fi

# Install Python packages
echo "Installing Python packages..."
pip install --user git+https://github.com/cjbassi/rofi-copyq

echo "Python installation complete!"
python3 --version
