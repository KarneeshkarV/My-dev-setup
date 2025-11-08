#!/usr/bin/env bash

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source distro utilities
source "$PROJECT_ROOT/lib/distro-utils.sh"

# Initialize distro detection
init_distro

echo "Installing Zephyr RTOS dependencies..."

case "$DISTRO" in
    arch)
        # Install dependencies from Arch repos
        install_packages git cmake ninja gperf ccache dfu-util dtc wget \
          python python-pip python-setuptools python-wheel xz file \
          make gcc sdl2 arm-none-eabi-gcc arm-none-eabi-newlib

        # Install esptool from AUR
        yay -S --needed --noconfirm esptool
        ;;
    debian)
        # Update system
        update_system

        # Add Kitware repository for latest CMake
        if [ ! -f /usr/share/keyrings/kitware-archive-keyring.gpg ]; then
            echo "Adding Kitware repository..."
            wget https://apt.kitware.com/kitware-archive.sh
            sudo bash kitware-archive.sh
            rm kitware-archive.sh
        fi

        # Install dependencies
        install_packages git cmake ninja-build gperf ccache dfu-util device-tree-compiler wget \
          python3-dev python3-pip python3-setuptools python3-tk python3-wheel xz-utils file \
          make gcc gcc-multilib g++-multilib libsdl2-dev libmagic1

        # Enable universe repository and install esptool
        sudo apt-add-repository universe -y
        sudo apt update
        install_packages esptool
        ;;
esac

# Create Zephyr project directory
if [ ! -d ~/zephyrproject ]; then
    mkdir -p ~/zephyrproject
fi

# Create virtual environment
if [ ! -d ~/zephyrproject/.venv ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv ~/zephyrproject/.venv
fi

# Activate virtual environment
source ~/zephyrproject/.venv/bin/activate

# Install west
pip install west

# Initialize Zephyr project if not already done
if [ ! -d ~/zephyrproject/.west ]; then
    echo "Initializing Zephyr project..."
    west init ~/zephyrproject
    cd ~/zephyrproject
    west update
else
    echo "Zephyr project already initialized"
    cd ~/zephyrproject
fi

# Export Zephyr environment
west zephyr-export

# Install Python dependencies
west packages pip --install

# Install SDK and fetch blobs
cd ~/zephyrproject/zephyr
west sdk install
west blobs fetch hal_espressif

echo "Zephyr RTOS installation complete!"
echo "Activate the environment with: source ~/zephyrproject/.venv/bin/activate"










