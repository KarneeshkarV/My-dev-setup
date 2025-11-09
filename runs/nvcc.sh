#!/usr/bin/env bash

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source distro utilities
source "$PROJECT_ROOT/lib/distro-utils.sh"

# Initialize distro detection
init_distro

echo "Installing NVIDIA Container Toolkit..."

case "$DISTRO" in
    arch)
        # Install NVIDIA Container Toolkit from AUR
        echo "Installing nvidia-container-toolkit from AUR..."
        yay -S --needed --noconfirm nvidia-container-toolkit
        ;;
    debian)
        # Add NVIDIA Container Toolkit repository
        echo "Adding NVIDIA Container Toolkit repository..."
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
          sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

        curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
          sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
          sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

        # Install nvidia-container-toolkit
        sudo apt update
        install_packages nvidia-container-toolkit
        ;;
esac

# Configure Docker to use NVIDIA runtime
if command_exists docker; then
    echo "Configuring Docker to use NVIDIA runtime..."
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker
    echo "Docker configured for NVIDIA GPU support"
else
    echo "Docker not found. Install Docker first (run docker.sh)"
fi

echo "NVIDIA Container Toolkit installation complete!"
