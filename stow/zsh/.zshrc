# ============================================================================
#
#                              ZSHRC Configuration
# ============================================================================
#
#
win_shut(){
/mnt/c/Windows/System32/shutdown.exe /s /f /t 0
}

if [ -z "$ZSH_VERSION" ]; then
    echo "This file is for zsh. Start zsh with: exec zsh"
    return 0 2>/dev/null || exit 0
fi

# --- Zsh Options ---
setopt AUTO_CD                # cd by typing directory name
setopt CORRECT                # Command correction suggestions
setopt INTERACTIVE_COMMENTS   # Allow comments in interactive shell
setopt NO_BEEP                # Disable beeping
setopt EXTENDED_GLOB          # Extended globbing capabilities
setopt NULL_GLOB              # Don't error on no glob matches
setopt GLOBDOTS               # Include hidden files in glob patterns
setopt AUTO_PUSHD             # Make cd push the old directory onto the stack
setopt PUSHD_IGNORE_DUPS      # Don't push duplicates onto the stack
setopt PUSHD_SILENT           # Don't print the directory stack after pushd/popd
setopt CDABLE_VARS            # Try to expand as if it was a variable

# --- History Configuration ---
HISTSIZE=100000               # Increased for longer history
SAVEHIST=100000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_ALL_DUPS   # No duplicate entries
setopt HIST_FIND_NO_DUPS      # No duplicates in search
setopt HIST_REDUCE_BLANKS     # Remove unnecessary blanks
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicates first when trimming
unsetopt SHARE_HISTORY        # Don't share history between sessions (each shell has its own)
unsetopt INC_APPEND_HISTORY   # Don't append to file immediately - keep session history isolated
setopt EXTENDED_HISTORY       # Add timestamps to history
setopt HIST_IGNORE_SPACE      # Don't record commands starting with space
setopt HIST_VERIFY            # Show command before executing from history

# Track session boundary for per-session history priority in search
_zsh_session_start_event=$(fc -l -1 2>/dev/null | awk '{print $1}')
: ${_zsh_session_start_event:=0}

# --- Environment Variables ---
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export LESS="-R -F -X"        # Better less defaults
export ANDROID_SDK_ROOT=/opt/android-sdk
export ANDROID_HOME=/opt/android-sdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export BUN_INSTALL="$HOME/.bun"
if [[ -r "$HOME/.ripgreprc" ]]; then
    export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"
else
    unset RIPGREP_CONFIG_PATH
fi

# LiteLLM gateway
export LITELLM_BASE_URL="${LITELLM_BASE_URL:-http://35.238.33.238:4000}"
export LITELLM_API_KEY="${LITELLM_API_KEY:-}"

# Docling proxy (dockling-proxy on big-coding-cpu, same VM as LiteLLM). Fronts
# the Docling pod so this URL survives the pod being replaced.
export DOCLING_BASE_URL="${DOCLING_BASE_URL:-http://35.238.33.238:8081}"

# Performance/compatibility fixes
ulimit -n 4096
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

# --- Secrets (API keys, tokens - keep out of git) ---
[[ -f ~/.secrets ]] && source ~/.secrets

# --- PATH Configuration ---
typeset -U path  # Ensure unique entries only
path=(${path:#$HOME/.nvm/versions/node/*/bin})
path=(${path:#$HOME/.local/share/pnpm})
path=(${path:#/home/karneeshkar/.local/share/pnpm})
path=(
    "$HOME/.local/bin"
    "$HOME/.local/scripts"
    "$HOME/.fzf/bin"
    "$HOME/.cargo/bin"
    "$HOME/go/bin"
    "$BUN_INSTALL/bin"
    "$HOME/.npm-global/bin"
    "$JAVA_HOME/bin"
    "$ANDROID_SDK_ROOT/emulator"
    "$ANDROID_SDK_ROOT/platform-tools"
    "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin"
    $path
)
export PATH
erniequeue() {
 local pod ip port
 pod=$(runpodctl pod list 2>/dev/null | \
    jq -r 'first(.[] | select((.name + " " + (.imageName // "")) |
           test("ernie"; "i")) | .id) // empty')
 [[ -n "$pod" ]] || { print -u2 -- 'no ernie pod running'; return 1; }
 eval "$(runpodctl ssh info "$pod" -o json 2>/dev/null | \
    jq -r '"ip=\(.ip) port=\(.port)"')"
 [[ -n "$ip" && -n "$port" ]] || { print -u2 -- "no ssh endpoint for $pod"; return 1; }
 ssh -i "$HOME/.runpod/ssh/runpodctl-ssh-key" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=10 "root@$ip" -p "$port" <<'REMOTE_CMD'
L=/workspace/image/sglang-ernie.log
q=$(ss -tn state established 2>/dev/null | grep -c ":30000")
echo "queue      : $q waiting  (~$((q * 100))s for a new request)"
echo "completed  : $(grep -c "Pixel data generated successfully" $L)"
echo "denoise    : $(grep -o "\[DenoisingStage\] finished in [0-9.]*" $L | \
                       tail -1 | grep -o "[0-9.]*$")s  (compute; ~90 is healthy)"
echo "errors     : $(grep -icE "traceback|out of memory" $L)"
nvidia-smi --query-gpu=memory.used,memory.total,utilization.gpu \
           --format=csv,noheader | sed "s/^/gpu        : /"
echo "step       : $(tail -1 $L | sed -e "s/\x1b\[[0-9;]*m//g" | \
                       grep -o "[0-9]*/50" | tail -1)"
REMOTE_CMD
}
gssh() {
    local line

    line=$(
        gcloud compute instances list \
            --filter="status=RUNNING" \
            --format="table[no-heading](name,zone,machineType.basename(),networkInterfaces[0].networkIP)" |
        column -t |
        fzf --prompt="VM > "
    ) || return

    read -r name zone _ _ <<<"$line"

    gcloud compute ssh "$name" --zone="$zone"
}

rssh() {
    local line id info ip port key

    line=$(
        runpodctl pod list -o json |
            jq -r '.[] | [.id, .name, "\(.gpuCount)xGPU", "\(.costPerHr)/hr"] | @tsv' |
            column -t |
            fzf --prompt="Pod > "
    ) || return

    read -r id _ <<<"$line"

    info=$(runpodctl ssh info "$id" -o json) || return
    ip=$(jq -r '.ip // empty' <<<"$info")
    port=$(jq -r '.port // empty' <<<"$info")
    key=$(jq -r '.ssh_key.path // empty' <<<"$info")

    if [[ -z "$ip" || -z "$port" ]]; then
        echo "rssh: no SSH endpoint for pod $id" >&2
        return 1
    fi

    if [[ -n "$key" ]]; then
        ssh -i "$key" -p "$port" "root@${ip}"
    else
        ssh -p "$port" "root@${ip}"
    fi
}
# --- Directory Hashes (quick access with ~name) ---
hash -d dl=~/Downloads
hash -d docs=~/Documents
hash -d conf=~/.config

# --- Auto-attach to tmux (for Ghostty tab restore) ---
if [[ -z "$TMUX" ]] && [[ "$TERM_PROGRAM" == "ghostty" ]]; then
    # Find an unattached tmux session and attach to it
    unattached=$(tmux ls -F '#{session_name}:#{session_attached}' 2>/dev/null | awk -F: '$2 == "0" {print $1; exit}')
    if [[ -n "$unattached" ]]; then
        exec tmux attach-session -t "$unattached"
    fi
fi

# --- Load Modular Config ---
ZSH_CONFIG_DIR="${ZDOTDIR:-$HOME/.config/zsh}"
for config_file in "$ZSH_CONFIG_DIR"/*.zsh(N); do
    source "$config_file"
done
unset config_file

# opencode
export PATH=/home/karphi/.opencode/bin:$PATH


# Added by Antigravity CLI installer
export PATH="/home/karphi/.local/bin:$PATH"

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

# Go installation
export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"

# Added by the Hunk installer (https://hunk.dev)
export PATH='/home/karphi/.hunk/bin':"$PATH"

# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
fpath=(~/.grok/completions/zsh $fpath)
autoload -Uz compinit && compinit -C
# <<< grok installer <<<

# mise shims avoid scanning the Windows PATH during shell startup.
eval "$(/home/karphi/.local/bin/mise activate --shims zsh)"
export TERM=xterm-256color

export T3CODE_TELEMETRY_ENABLED=false
export T3CODE_OTEL_SDK_DISABLED=true
