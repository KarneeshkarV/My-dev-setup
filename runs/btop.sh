#!/usr/bin/env bash

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source distro utilities
source "$PROJECT_ROOT/lib/distro-utils.sh"

# Initialize distro detection
init_distro

echo "Installing btop++..."

case "$DISTRO" in
    arch)
        # btop is available in the official Arch repos
        install_packages btop
        ;;
    debian)
        # For Ubuntu 22.04+, btop is in universe repo
        # For older versions, use snap as fallback
        if sudo apt install -y btop 2>/dev/null; then
            echo "btop installed via apt"
        else
            echo "btop not in apt repos, installing via snap..."
            sudo snap install btop
        fi
        ;;
esac

# Verify installation
if command_exists btop; then
    echo -e "${GREEN}btop++ installed successfully!${NC}"
    btop --version
else
    echo -e "${RED}btop++ installation failed${NC}"
    exit 1
fi
