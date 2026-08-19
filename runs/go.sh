#!/usr/bin/env bash

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source distro utilities
source "$PROJECT_ROOT/lib/distro-utils.sh"

# Initialize distro detection
init_distro

# Install prerequisites
install_packages wget tar curl python

# Go version to install
GO_VERSION="1.24.2"
GO_TARBALL="go${GO_VERSION}.linux-amd64.tar.gz"
GO_URL="https://go.dev/dl/${GO_TARBALL}"
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

echo "Installing Go ${GO_VERSION}..."
curl -fsSL "$GO_URL" -o "${WORKDIR}/${GO_TARBALL}"

EXPECTED_SHA=$(curl -fsSL "https://go.dev/dl/?mode=json&include=all" | python3 -c "
import json, sys
version = 'go${GO_VERSION}'
filename = '${GO_TARBALL}'
for rel in json.load(sys.stdin):
    if rel.get('version') != version:
        continue
    for f in rel.get('files', []):
        if f.get('filename') == filename:
            print(f['sha256'])
            sys.exit(0)
sys.stderr.write('checksum not found for ' + filename + '\n')
sys.exit(1)
")

GOT_SHA=$(sha256sum "${WORKDIR}/${GO_TARBALL}" | awk '{print $1}')
if [ "$GOT_SHA" != "$EXPECTED_SHA" ]; then
    echo "SHA256 mismatch for ${GO_TARBALL}"
    echo "expected: ${EXPECTED_SHA}"
    echo "got:      ${GOT_SHA}"
    exit 1
fi
echo "SHA256 verified: ${GOT_SHA}"

if [ -d /usr/local/go ]; then
    echo "Removing old Go installation..."
    sudo rm -rf /usr/local/go
fi
sudo tar -C /usr/local -xzf "${WORKDIR}/${GO_TARBALL}"

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
go install github.com/jesseduffield/lazygit@latest

echo "Go installation complete!"
