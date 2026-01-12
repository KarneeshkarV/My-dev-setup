#!/usr/bin/env bash
set -euo pipefail

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_DIR="$SCRIPT_DIR/stow"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize variables
DRY_RUN=0
UNSTOW=0
RESTOW=0
PACKAGES=()

# --- Usage ---
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [PACKAGES...]

Manage dotfiles using GNU Stow.

OPTIONS:
    -d, --dry       Dry run - show what would be done without making changes
    -u, --unstow    Remove symlinks instead of creating them
    -r, --restow    Restow packages (unstow then stow - useful for updates)
    -l, --list      List available stow packages
    -h, --help      Show this help message

PACKAGES:
    Specify one or more packages to stow. If none specified, all packages
    in the stow/ directory will be processed.

EXAMPLES:
    $(basename "$0")              # Stow all packages
    $(basename "$0") zsh git      # Stow only zsh and git
    $(basename "$0") -r zsh       # Restow zsh (refresh symlinks)
    $(basename "$0") -u tmux      # Remove tmux symlinks
    $(basename "$0") --dry        # Preview what would happen
EOF
}

# --- Logging Functions ---
log() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_dry() { echo -e "${YELLOW}[DRY]${NC} $1"; }

# --- List available packages ---
list_packages() {
    log "Available stow packages in $STOW_DIR:"
    for pkg in "$STOW_DIR"/*/; do
        pkg_name=$(basename "$pkg")
        echo "  - $pkg_name"
    done
}

# --- Get all packages ---
get_all_packages() {
    local packages=()
    for pkg in "$STOW_DIR"/*/; do
        packages+=("$(basename "$pkg")")
    done
    echo "${packages[@]}"
}

# --- Stow a package ---
stow_package() {
    local pkg="$1"
    local action="stow"
    local stow_args=("-v" "-t" "$HOME" "-d" "$STOW_DIR")

    if [[ ! -d "$STOW_DIR/$pkg" ]]; then
        log_error "Package '$pkg' not found in $STOW_DIR"
        return 1
    fi

    if ((RESTOW)); then
        action="restow"
        stow_args+=("-R")
    elif ((UNSTOW)); then
        action="unstow"
        stow_args+=("-D")
    else
        stow_args+=("-S")
    fi

    if ((DRY_RUN)); then
        stow_args+=("-n")
        log_dry "Would $action: $pkg"
    else
        log "Running $action: $pkg"
    fi

    if stow "${stow_args[@]}" "$pkg" 2>&1; then
        if ((DRY_RUN)); then
            log_dry "  $action would succeed for $pkg"
        else
            log_success "$action completed: $pkg"
        fi
    else
        log_error "Failed to $action: $pkg"
        return 1
    fi
}

# --- Ensure stow is installed ---
check_stow() {
    if ! command -v stow &>/dev/null; then
        log_error "GNU Stow is not installed. Please run: ./runs/stow.sh"
        exit 1
    fi
}

# --- Ensure required directories exist ---
ensure_directories() {
    local dirs=(
        "$HOME/.config"
        "$HOME/.local"
        "$HOME/.local/scripts"
    )

    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            if ((DRY_RUN)); then
                log_dry "Would create directory: $dir"
            else
                mkdir -p "$dir"
                log "Created directory: $dir"
            fi
        fi
    done
}

# --- Make scripts executable ---
make_scripts_executable() {
    local scripts_dir="$HOME/.local/scripts"
    if [[ -d "$scripts_dir" ]]; then
        if ((DRY_RUN)); then
            log_dry "Would make scripts executable in $scripts_dir"
        else
            find "$scripts_dir" -maxdepth 1 -type f -exec chmod +x {} \;
            log_success "Made scripts executable in $scripts_dir"
        fi
    fi
}

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dry)
            DRY_RUN=1
            shift
            ;;
        -u|--unstow)
            UNSTOW=1
            shift
            ;;
        -r|--restow)
            RESTOW=1
            shift
            ;;
        -l|--list)
            list_packages
            exit 0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            PACKAGES+=("$1")
            shift
            ;;
    esac
done

# --- Main ---
echo "============================== dev env =============================="

check_stow
ensure_directories

# If no packages specified, use all
if [[ ${#PACKAGES[@]} -eq 0 ]]; then
    read -ra PACKAGES <<< "$(get_all_packages)"
    log "No packages specified, using all: ${PACKAGES[*]}"
fi

# Process each package
FAILED=0
for pkg in "${PACKAGES[@]}"; do
    if ! stow_package "$pkg"; then
        FAILED=$((FAILED + 1))
    fi
done

# Make scripts executable after stowing
if ((! UNSTOW)); then
    make_scripts_executable
fi

echo "====================================================================="

if ((FAILED > 0)); then
    log_error "$FAILED package(s) failed"
    exit 1
else
    if ((DRY_RUN)); then
        log_success "Dry run complete - no changes made"
    else
        log_success "All packages processed successfully"
    fi
fi
