#!/usr/bin/env bash

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source distro utilities
source "$PROJECT_ROOT/lib/distro-utils.sh"

# Initialize distro detection
init_distro

echo "Installing Docker Engine..."

case "$DISTRO" in
    arch)
        # Install Docker from official Arch repos
        install_packages docker docker-compose docker-buildx
        ;;
    debian)
        # Install prerequisites
        install_packages ca-certificates curl gnupg

        # Add Docker's official GPG key
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        # Add Docker repository
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        # Install Docker Engine
        sudo apt update
        install_packages docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        ;;
esac

# Enable and start Docker service
enable_service docker

# Add user to docker group
add_user_to_group docker

echo "Docker installed successfully!"
echo "Note: You may need to log out and back in for group changes to take effect."

# Install lazydocker (distro-agnostic)
if ! command_exists lazydocker; then
    echo "Installing lazydocker..."
    curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
else
    echo "lazydocker already installed"
fi
