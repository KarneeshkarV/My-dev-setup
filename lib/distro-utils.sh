#!/bin/bash
# Distro-agnostic utilities for package management
# Supports: Arch Linux (pacman/yay) and Ubuntu/Debian (apt)

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Detect the operating system
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID="$ID"
        OS_NAME="$NAME"
        OS_VERSION="$VERSION_ID"
    else
        echo -e "${RED}Error: Cannot detect OS. /etc/os-release not found.${NC}"
        exit 1
    fi

    case "$OS_ID" in
        arch|manjaro|endeavouros)
            DISTRO="arch"
            PKG_MGR="pacman"
            ;;
        ubuntu|debian|pop|linuxmint)
            DISTRO="debian"
            PKG_MGR="apt"
            ;;
        *)
            echo -e "${RED}Error: Unsupported distribution: $OS_ID${NC}"
            echo "Supported: Arch Linux, Ubuntu, Debian"
            exit 1
            ;;
    esac

    echo -e "${GREEN}Detected: $OS_NAME ($DISTRO)${NC}"
}

# Ensure yay is installed on Arch systems
ensure_yay() {
    if [ "$DISTRO" = "arch" ]; then
        if ! command -v yay &> /dev/null; then
            echo -e "${YELLOW}Installing yay AUR helper...${NC}"
            sudo pacman -S --needed --noconfirm git base-devel
            cd /tmp
            git clone https://aur.archlinux.org/yay.git
            cd yay
            makepkg -si --noconfirm
            cd ~
            rm -rf /tmp/yay
            echo -e "${GREEN}yay installed successfully${NC}"
        fi
    fi
}

# Update system packages
update_system() {
    echo -e "${GREEN}Updating system packages...${NC}"

    case "$DISTRO" in
        arch)
            sudo pacman -Syu --noconfirm
            ;;
        debian)
            sudo apt update && sudo apt upgrade -y
            ;;
    esac
}

# Install packages with distro-appropriate package manager
# Usage: install_packages pkg1 pkg2 pkg3...
install_packages() {
    local packages=("$@")

    if [ ${#packages[@]} -eq 0 ]; then
        echo -e "${YELLOW}No packages specified${NC}"
        return 0
    fi

    echo -e "${GREEN}Installing: ${packages[*]}${NC}"

    case "$DISTRO" in
        arch)
            # Try official repos first, then AUR
            sudo pacman -S --needed --noconfirm "${packages[@]}" 2>/dev/null || \
            yay -S --needed --noconfirm "${packages[@]}"
            ;;
        debian)
            sudo apt install -y "${packages[@]}"
            ;;
    esac
}

# Map package names between distros
# Usage: map_package "ubuntu-package-name"
# Returns: "arch-package-name" or original if no mapping needed
map_package() {
    local pkg="$1"

    # Package name mappings (Ubuntu -> Arch)
    declare -A PKG_MAP=(
        # Build tools
        ["build-essential"]="base-devel"
        ["ninja-build"]="ninja"

        # Python
        ["python3"]="python"
        ["python3-pip"]="python-pip"
        ["python3-dev"]="python"
        ["python3-venv"]="python"
        ["python3-setuptools"]="python-setuptools"

        # Lua
        ["lua5.1"]="lua51"
        ["liblua5.1-0-dev"]="lua51"

        # Libraries
        ["libsdl2-dev"]="sdl2"
        ["libmagic1"]="file"
        ["libtool-bin"]="libtool"

        # System tools
        ["software-properties-common"]=""  # Not needed on Arch
        ["apt-transport-https"]=""  # Not needed on Arch
        ["ca-certificates"]="ca-certificates"

        # Device tools
        ["device-tree-compiler"]="dtc"
    )

    if [ "$DISTRO" = "arch" ]; then
        # Return mapped package name or original
        local mapped="${PKG_MAP[$pkg]}"
        if [ -n "$mapped" ]; then
            echo "$mapped"
        else
            echo "$pkg"
        fi
    else
        # Ubuntu: return original
        echo "$pkg"
    fi
}

# Install packages with automatic name mapping
# Usage: install_mapped_packages pkg1 pkg2 pkg3...
install_mapped_packages() {
    local packages=("$@")
    local mapped_packages=()

    for pkg in "${packages[@]}"; do
        local mapped=$(map_package "$pkg")
        # Only add non-empty package names
        if [ -n "$mapped" ]; then
            mapped_packages+=("$mapped")
        fi
    done

    if [ ${#mapped_packages[@]} -gt 0 ]; then
        install_packages "${mapped_packages[@]}"
    fi
}

# Add user to a group
add_user_to_group() {
    local group="$1"
    local user="${2:-$USER}"

    echo -e "${GREEN}Adding $user to $group group...${NC}"
    sudo usermod -aG "$group" "$user"
}

# Enable and start a systemd service
enable_service() {
    local service="$1"

    echo -e "${GREEN}Enabling and starting $service...${NC}"
    sudo systemctl enable "$service"
    sudo systemctl start "$service"
}

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Install from AUR on Arch, or from source/PPA on Ubuntu
# Usage: install_special "package-name" "arch-aur-name" "ubuntu-ppa" "ubuntu-pkg-name"
install_special() {
    local name="$1"
    local arch_pkg="$2"
    local ubuntu_ppa="$3"
    local ubuntu_pkg="$4"

    echo -e "${GREEN}Installing $name...${NC}"

    case "$DISTRO" in
        arch)
            yay -S --needed --noconfirm "$arch_pkg"
            ;;
        debian)
            if [ -n "$ubuntu_ppa" ]; then
                sudo add-apt-repository -y "$ubuntu_ppa"
                sudo apt update
            fi
            sudo apt install -y "$ubuntu_pkg"
            ;;
    esac
}

# Initialize: detect OS and ensure yay on Arch
init_distro() {
    detect_os
    if [ "$DISTRO" = "arch" ]; then
        ensure_yay
    fi
}

# Export functions and variables
export -f detect_os
export -f ensure_yay
export -f update_system
export -f install_packages
export -f map_package
export -f install_mapped_packages
export -f add_user_to_group
export -f enable_service
export -f command_exists
export -f install_special
export -f init_distro
