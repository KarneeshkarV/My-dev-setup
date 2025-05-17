#!/usr/bin/env zsh

# Get the directory where the script is located
script_dir=$(cd "$(dirname "${(%):-%x}")" && pwd)

# Initialize variables
dry=0 # Use 1 for dry run, 0 to execute

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry) dry=1 ;;
    *)     break ;;
  esac
  shift
done

# --- Logging Function ---
log() {
  if (( dry )); then
    echo "[DRY_RUN]: $1"
  else
    echo "$1"
  fi
}

# --- Execution Function ---
execute() {
  log "Executing: $*"
  (( dry )) && { log "(skipped)"; return 0; }
  "$@"
}

log "----------------------------- dev env -----------------------------"

# --- Unused function (kept for reference) ---
# update_files() {
#   local src_dir=$1
#   local dest_dir=${2%/}
#
#   log "Copying over files from: $src_dir"
#   pushd "$src_dir" > /dev/null || return 1
#
#   for c in */; do
#     local dest="$dest_dir/${c%/}"
#     log "  removing: $dest"
#     (( ! dry )) && rm -rf "$dest"
#     log "  copying: $c → $dest_dir"
#     (( ! dry )) && cp -r "$c" "$dest_dir"
#   done
#
#   popd > /dev/null || return 1
# }

# --- Copy Function ---
copy() {
  local src=$1 dest=$2
  # Ensure source exists before proceeding
  if [[ ! -e "$src" ]]; then
    log "ERROR: Source '$src' not found. Skipping copy."
    return 1
  fi
  log "Removing: $dest"
  (( ! dry )) && rm -rf "$dest"
  log "Copying: $src → $dest"
  (( ! dry )) && cp -r "$src" "$dest"
}

# --- Unused function (kept for reference) ---
# copy_file() {
#   local from=$1 to=$2 name=${from:t}
#   execute rm -f "$to/$name"
#   execute cp "$from" "$to/$name"
# }

# === Your specific copies ===
# Change directory to the script's directory to resolve relative paths
cd "$script_dir" || exit 1

copy ".zshrc"          "$HOME/.zshrc"
copy ".local/scripts" "$HOME/.local/scripts"

copy ".config/i3" "$HOME/.config/i3"
copy ".config/rofi" "$HOME/.config/rofi"
copy ".config/ghostty" "$HOME/.config/ghostty"
# Only source if we’re in an interactive Zsh session and the file exists
if [[ -n "$ZSH_VERSION" && -f "$HOME/.zshrc" ]]; then
  log "Sourcing $HOME/.zshrc in Zsh"
  # Use '.' or 'source' - '.' is slightly more portable but source is fine in zsh
  # Using the full path is more reliable than '~'
  source "$HOME/.zshrc"
elif [[ -f "$HOME/.zshrc" ]]; then
    log "Not an interactive Zsh session, skipping source."
else
    log "WARNING: $HOME/.zshrc not found after copy. Cannot source."
fi

# Make all scripts in ~/.local/scripts executable, check if directory exists
if [[ -d "$HOME/.local/scripts" ]]; then
    log "Making scripts executable under $HOME/.local/scripts"
    # Find regular files and make them executable
    # Using find is safer than globbing if there are many files or none
    find "$HOME/.local/scripts" -maxdepth 1 -type f -exec chmod +x {} \;
else
    log "Directory $HOME/.local/scripts does not exist, skipping chmod."
fi

log "----------------------------- dev env finished -----------------------------"
