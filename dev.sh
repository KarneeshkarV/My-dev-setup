#!/usr/bin/env bash

# Get the directory where the script is located
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Initialize variables
dry="0" # Use "1" for dry run, "0" to execute

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--dry" ]]; then
        dry="1"
    fi
    shift
done

# --- Logging Function ---
log() {
    if [[ "$dry" == "1" ]]; then
        echo "[DRY_RUN]: $1"
    else
        echo "$1"
    fi
}

# --- Execution Function ---
execute() {
    log "Executing: \"$@\""
    if [[ "$dry" == "1" ]]; then
        log "(Skipped execution due to dry run)"
        return 0
    fi
    "$@"
    return $?
}

log "----------------------------- dev env -----------------------------" 

update_files() {
    src_dir=$1
    dest_dir=${2%/}

    log "Copying over files from: $src_dir"
    pushd "$src_dir" > /dev/null || return 1

    for c in */; do
        directory="$dest_dir/${c%/}"
        log "    removing: $directory"
        if [[ "$dry" == "0" ]]; then
            rm -rf "$directory"
        fi

        log "    copying: $c to $dest_dir"
        if [[ "$dry" == "0" ]]; then
            cp -r "$c" "$dest_dir"
        fi
    done

    popd > /dev/null || return 1
}

copy() {
    src=$1
    dest=$2
    log "Removing: $dest"
    if [[ "$dry" == "0" ]]; then
        rm -rf "$dest"
    fi
    log "Copying: $src to $dest"
    if [[ "$dry" == "0" ]]; then
        cp -r "$src" "$dest"
    fi
}

copy_file() {
    from=$1
    to=$2
    name=$(basename "$from")
    execute rm -f "$to/$name"
    execute cp "$from" "$to/$name"
}

# Example usage (uncomment and adjust as needed):
# update_files "$DEV_ENV/env/.config" "$XDG_CONFIG_HOME"
# update_files "$DEV_ENV/env/.local" "$HOME/.local"
# copy "$DEV_ENV/tmux-sessionizer/tmux-sessionizer" "$HOME/.local/scripts/tmux-sessionizer"
# copy "$DEV_ENV/env/.zsh_profile" "$HOME/.zsh_profile"
# copy "$DEV_ENV/env/.zshrc" "$HOME/.zshrc"
# copy "$DEV_ENV/env/.xprofile" "$HOME/.xprofile"
# copy "$DEV_ENV/env/.tmux-sessionizer" "$HOME/.tmux-sessionizer"
# copy "$DEV_ENV/dev-env" "$HOME/.local/scripts/dev-env"

copy ".local/scripts" "$HOME/.local/scripts"
chmod +x "$HOME/.local/scripts" -R

