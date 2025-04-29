#!/usr/bin/env bash

echo "running first"

# Become root user (if not already)
if [[ "$EUID" -ne 0 ]]; then
  echo "Attempting to gain root privileges..."
  sudo su -  # Or simply: sudo -i
else
  echo "Already running as root."
fi

# Update package lists
apt update

# Install sudo (if necessary)
if ! command -v sudo &> /dev/null; then
  echo "sudo is not installed. Installing..."
  apt install -y sudo
else
  echo "sudo is already installed."
fi

# Upgrade packages
apt upgrade -y

echo "Update and upgrade complete."

exit 0 # Exit with success code
