#!/usr/bin/env bash
echo "running first"

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source distro utilities
source "$PROJECT_ROOT/lib/distro-utils.sh"

# Initialize distro detection
init_distro

# Install sudo if necessary (before we try to use it)
if ! command_exists sudo; then
  echo "sudo is not installed. Installing..."
  case "$DISTRO" in
    arch)
      su -c 'pacman -S --noconfirm sudo'
      ;;
    debian)
      su -c 'apt install -y sudo'
      ;;
  esac
else
  echo "sudo is already installed."
fi

# Update and upgrade system
update_system

echo "Update and upgrade complete for $DISTRO."

exit 0
