#!/usr/bin/env bash

# Get the directory where the script is located
script_dir=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

# Initialize variables
dry="0" # Use "1" for true (dry run enabled), "0" for false (execute)

# --- Argument Parsing ---
# Loop through all command-line arguments
while [[ $# -gt 0 ]]; do # Added spaces, use -gt for numerical comparison
    # Check if the argument is exactly "--dry"
    if [[ "$1" == "--dry" ]]; then # Added spaces, quotes, correct comparison
        dry="1" # Set the dry run flag to true
   fi
    # Move to the next argument
    shift
done

# --- Logging Function ---
# Prints messages, prepending [DRY_RUN] if dry run is enabled
log() {
    # Use the correct variable 'dry'
    if [[ "$dry" == "1" ]]; then # Added spaces, quotes, correct comparison
        echo "[DRY_RUN]: $1"
    else
        echo "$1"
    fi
}

# --- Execution Function ---
# Executes commands passed as arguments, unless dry run is enabled
execute() {
    # Log the command that would be executed. Quote "$@" to handle args with spaces.
    log "Executing: \"$@\""

    # Check the correct variable 'dry', add spaces, quotes, comparison
    if [[ "$dry" == "1" ]]; then
        # If dry run, print the intent and return success without executing
        log "(Skipped execution due to dry run)"
        return 0 # Indicate success for dry run scenarios
    fi

    # If not dry run, execute the command with its arguments
    "$@"
    # Capture and return the actual exit status of the command
    return $?
}
log "-----------------------------dev env -----------------------------" 

update_files() {
    log "copying over files from: $1"
    pushd $1 &> /dev/null
    (
        configs=`find . -mindepth 1 -maxdepth 1 -type d`
        for c in $configs; do
            directory=${2%/}/${c#./}
            log "    removing: rm -rf $directory"

            if [[ $dry_run == "0" ]]; then
                rm -rf $directory
            fi

            log "    copying env: cp $c $2"
            if [[ $dry_run == "0" ]]; then
                cp -r ./$c $2
            fi
        done

    )
    popd &> /dev/null
}

copy() {
    log "removing: $2"
    if [[ $dry_run == "0" ]]; then
        rm $2
    fi
    log "copying: $1 to $2"
    if [[ $dry_run == "0" ]]; then
        cp $1 $2
    fi
}
update_files $DEV_ENV/env/.config $XDG_CONFIG_HOME
update_files $DEV_ENV/env/.local $HOME/.local

copy $DEV_ENV/tmux-sessionizer/tmux-sessionizer $HOME/.local/scripts/tmux-sessionizer
copy $DEV_ENV/env/.zsh_profile $HOME/.zsh_profile
copy $DEV_ENV/env/.zshrc $HOME/.zshrc
copy $DEV_ENV/env/.xprofile $HOME/.xprofile
copy $DEV_ENV/env/.tmux-sessionizer $HOME/.tmux-sessionizer
copy $DEV_ENV/dev-env $HOME/.local/scripts/dev-env
