#!/usr/bin/env bash
set -o pipefail

# Get the directory where the script is located
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Initialize variables
filter=""
dry="0" # Use "1" for true (dry run enabled), "0" for false (execute)

# --- Argument Parsing ---
# Loop through all command-line arguments
while [[ $# -gt 0 ]]; do # Added spaces, use -gt for numerical comparison
    # Check if the argument is exactly "--dry"
    if [[ "$1" == "--dry" ]]; then # Added spaces, quotes, correct comparison
        dry="1" # Set the dry run flag to true
    else
        # Assume any other argument is the filter
        # This will overwrite previous values, taking the *last* non --dry argument
        filter="$1" # Quote variable assignment for safety
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

# --- Main Script Logic ---
log "Script directory: $script_dir"
log "Filter: '$filter'" # Added quotes around filter value for clarity
log "Dry run enabled: $dry" # Show status of dry run

log "Searching for executable installer scripts in ./runs ..."

preferred_order=(
    aafirst.sh
    stow.sh
    zsh.sh
    python.sh
    node.sh
    rust.sh
    go.sh
    cli.sh
    tmux.sh
    neovim.sh
    docker.sh
    btop.sh
    backup.sh
)

scripts_list=()
for script_name in "${preferred_order[@]}"; do
    script_path="$script_dir/runs/$script_name"
    if [[ -f "$script_path" && -x "$script_path" ]]; then
        scripts_list+=("$script_path")
    fi
done

while IFS= read -r script_path; do
    already_listed=0
    for listed_path in "${scripts_list[@]}"; do
        if [[ "$listed_path" == "$script_path" ]]; then
            already_listed=1
            break
        fi
    done
    if [[ "$already_listed" == "0" ]]; then
        scripts_list+=("$script_path")
    fi
done < <(find "$script_dir/runs" -maxdepth 1 -mindepth 1 -executable -type f -name '*.sh' 2>/dev/null | sort)

# Check if any scripts were found
if [[ "${#scripts_list[@]}" -eq 0 ]]; then # Use [[ ]] for consistency and safety
    log "No executable scripts found in $script_dir/runs"
    exit 0 # Exit cleanly if no scripts found
fi

log "Found scripts:"
printf '  %s\n' "${scripts_list[@]}"

# Iterate through the list of found script paths
for script_path in "${scripts_list[@]}"; do
    # Filtering logic:
    # If a filter IS provided AND the script path does NOT contain the filter string...
    # (-q makes grep quiet, -v inverts the match)
    if [[ -n "$filter" ]] && echo "$script_path" | grep -qv "$filter"; then
        # ...then log that we are skipping this script and continue to the next one.
        log "Filtering (skipping due to mismatch): $script_path"
        continue
    fi

    # If the script was not filtered out, prepare to run it
    log "--- Preparing to run $script_path ---"
    # Use the execute function to handle actual execution vs dry run
    execute "$script_path"
    execute_status=$? # Capture the exit status from the execute function
    log "--- Finished $script_path (Exit Status: $execute_status) ---"

    if [[ "$dry" == "0" && $execute_status -ne 0 ]]; then
        log "Error: Script $script_path failed with status $execute_status. Aborting."
        exit $execute_status
    fi
done

log "All matching scripts processed." # Completed the final message
echo "Install BTOP++"
