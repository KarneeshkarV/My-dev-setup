#!/usr/bin/env bash
set -euo pipefail

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source distro utilities
source "$PROJECT_ROOT/lib/distro-utils.sh"

# Initialize distro detection
init_distro

echo "Installing GNU Stow..."

# Install stow (same package name on both distros)
if ! command_exists stow; then
    install_packages stow
else
    echo "stow is already installed"
fi

echo "Linking dotfiles into $HOME..."
mkdir -p "$HOME/.config" "$HOME/.local"

stow_packages=()
while IFS= read -r -d '' package_path; do
    stow_packages+=("$(basename "$package_path")")
done < <(find "$PROJECT_ROOT/stow" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

if [ "${#stow_packages[@]}" -eq 0 ]; then
    echo "No stow packages found in $PROJECT_ROOT/stow"
    exit 0
fi

linked_packages=()
skipped_packages=()
for package in "${stow_packages[@]}"; do
    if stow --dir="$PROJECT_ROOT/stow" --target="$HOME" --restow "$package"; then
        linked_packages+=("$package")
    else
        skipped_packages+=("$package")
        echo "Skipping stow package due to conflicts: $package"
    fi
done

if [ "${#linked_packages[@]}" -gt 0 ]; then
    echo "Linked stow packages: ${linked_packages[*]}"
fi

if [ "${#skipped_packages[@]}" -gt 0 ]; then
    echo "Skipped conflicting stow packages: ${skipped_packages[*]}"
    echo "Move or merge the conflicting files, then rerun this script to link them."
fi

echo "GNU Stow setup complete!"
