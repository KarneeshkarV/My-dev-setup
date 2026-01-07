#!/usr/bin/env bash

# Backup and Sync Script
# Exports package lists and Brewfile for reproducible setups

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_ROOT/backup"

# Source distro utilities
source "$PROJECT_ROOT/lib/distro-utils.sh"

# Initialize distro detection
init_distro

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo -e "${GREEN}=== Package Backup & Sync ===${NC}"
echo "Backup directory: $BACKUP_DIR"
echo ""

# Export system packages based on distro
case "$DISTRO" in
    arch)
        echo -e "${GREEN}Exporting Arch Linux packages...${NC}"

        # Explicitly installed packages (not dependencies)
        pacman -Qe > "$BACKUP_DIR/pacman-explicit.txt"
        echo "  → pacman-explicit.txt ($(wc -l < "$BACKUP_DIR/pacman-explicit.txt") packages)"

        # Native packages only (from official repos)
        pacman -Qen > "$BACKUP_DIR/pacman-native.txt"
        echo "  → pacman-native.txt ($(wc -l < "$BACKUP_DIR/pacman-native.txt") packages)"

        # AUR packages
        pacman -Qem > "$BACKUP_DIR/pacman-aur.txt"
        echo "  → pacman-aur.txt ($(wc -l < "$BACKUP_DIR/pacman-aur.txt") packages)"
        ;;
    debian)
        echo -e "${GREEN}Exporting Debian/Ubuntu packages...${NC}"

        # Manually installed packages
        apt-mark showmanual > "$BACKUP_DIR/apt-manual.txt"
        echo "  → apt-manual.txt ($(wc -l < "$BACKUP_DIR/apt-manual.txt") packages)"

        # All installed packages with versions
        dpkg-query -W -f='${Package} ${Version}\n' > "$BACKUP_DIR/apt-all.txt"
        echo "  → apt-all.txt ($(wc -l < "$BACKUP_DIR/apt-all.txt") packages)"
        ;;
esac

echo ""

# Export Homebrew packages if installed
if command_exists brew; then
    echo -e "${GREEN}Exporting Homebrew packages...${NC}"

    # Generate Brewfile
    brew bundle dump --file="$BACKUP_DIR/Brewfile" --force
    echo "  → Brewfile ($(grep -c '^' "$BACKUP_DIR/Brewfile") entries)"

    # Also export as plain list
    brew list > "$BACKUP_DIR/brew-list.txt"
    echo "  → brew-list.txt ($(wc -l < "$BACKUP_DIR/brew-list.txt") packages)"
else
    echo -e "${YELLOW}Homebrew not installed, skipping Brewfile export${NC}"
fi

echo ""

# Export Cargo packages if installed
if command_exists cargo; then
    echo -e "${GREEN}Exporting Cargo packages...${NC}"
    cargo install --list | grep -E '^[a-zA-Z]' | awk '{print $1}' > "$BACKUP_DIR/cargo-packages.txt"
    echo "  → cargo-packages.txt ($(wc -l < "$BACKUP_DIR/cargo-packages.txt") packages)"
else
    echo -e "${YELLOW}Cargo not installed, skipping${NC}"
fi

# Export npm global packages if installed
if command_exists npm; then
    echo -e "${GREEN}Exporting npm global packages...${NC}"
    npm list -g --depth=0 --json 2>/dev/null | jq -r '.dependencies | keys[]' > "$BACKUP_DIR/npm-global.txt" 2>/dev/null || \
    npm list -g --depth=0 2>/dev/null | tail -n +2 | awk '{print $2}' | cut -d@ -f1 > "$BACKUP_DIR/npm-global.txt"
    echo "  → npm-global.txt ($(wc -l < "$BACKUP_DIR/npm-global.txt") packages)"
else
    echo -e "${YELLOW}npm not installed, skipping${NC}"
fi

# Export pip packages if uv or pip is installed
if command_exists uv; then
    echo -e "${GREEN}Exporting uv/pip packages...${NC}"
    uv pip list --format=freeze 2>/dev/null > "$BACKUP_DIR/pip-packages.txt" || \
    pip list --format=freeze > "$BACKUP_DIR/pip-packages.txt" 2>/dev/null
    echo "  → pip-packages.txt ($(wc -l < "$BACKUP_DIR/pip-packages.txt") packages)"
elif command_exists pip; then
    echo -e "${GREEN}Exporting pip packages...${NC}"
    pip list --format=freeze > "$BACKUP_DIR/pip-packages.txt" 2>/dev/null
    echo "  → pip-packages.txt ($(wc -l < "$BACKUP_DIR/pip-packages.txt") packages)"
else
    echo -e "${YELLOW}pip/uv not installed, skipping${NC}"
fi

echo ""

# Add timestamp
date -Iseconds > "$BACKUP_DIR/.last-backup"
echo -e "${GREEN}Backup completed at $(cat "$BACKUP_DIR/.last-backup")${NC}"

echo ""
echo "To restore packages:"
echo "  Arch:   sudo pacman -S --needed - < backup/pacman-native.txt"
echo "          yay -S --needed - < backup/pacman-aur.txt"
echo "  Ubuntu: xargs sudo apt install -y < backup/apt-manual.txt"
echo "  Brew:   brew bundle --file=backup/Brewfile"
echo "  Cargo:  xargs cargo install < backup/cargo-packages.txt"
echo "  npm:    xargs npm install -g < backup/npm-global.txt"
