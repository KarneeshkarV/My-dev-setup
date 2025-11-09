#!/usr/bin/env bash

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source distro utilities
source "$PROJECT_ROOT/lib/distro-utils.sh"

# Initialize distro detection
init_distro

# Install prerequisites
install_packages wget tar

# Go version to install
GO_VERSION="1.24.2"
GO_TARBALL="go${GO_VERSION}.linux-amd64.tar.gz"

# Remove old Go installation if exists
if [ -d /usr/local/go ]; then
    echo "Removing old Go installation..."
    sudo rm -rf /usr/local/go
fi

# Download and install Go
echo "Installing Go ${GO_VERSION}..."
wget "https://go.dev/dl/${GO_TARBALL}" -O "/tmp/${GO_TARBALL}"
sudo tar -C /usr/local -xzf "/tmp/${GO_TARBALL}"
rm "/tmp/${GO_TARBALL}"

# Add Go to PATH
LINE='export PATH=$PATH:/usr/local/go/bin'
PROFILE="$HOME/.profile"

if ! grep -Fxq "$LINE" "$PROFILE"; then
    echo "$LINE" >> "$PROFILE"
    echo "Line added to $PROFILE"
else
    echo "Line already exists in $PROFILE"
fi

# Also add to current session
export PATH=$PATH:/usr/local/go/bin

# Verify installation
go version

# Install Go tools
echo "Installing Go CLI tools..."
go install github.com/danielmiessler/fabric@latest
go install github.com/jesseduffield/lazygit@latest

echo "Go installation complete!"
