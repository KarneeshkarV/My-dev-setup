# ============================================================================
#                              ZSHRC Configuration
# ============================================================================

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
export PNPM_HOME="$HOME/.local/share/pnpm"
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

# Performance/compatibility fixes
ulimit -n 4096
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

# --- Secrets (API keys, tokens - keep out of git) ---
[[ -f ~/.secrets ]] && source ~/.secrets

# --- PATH Configuration ---
typeset -U path  # Ensure unique entries only
path=(
    "$HOME/.local/bin"
    "$HOME/.local/scripts"
    "$HOME/go/bin"
    "$BUN_INSTALL/bin"
    "$PNPM_HOME"
    "$JAVA_HOME/bin"
    "$ANDROID_SDK_ROOT/emulator"
    "$ANDROID_SDK_ROOT/platform-tools"
    "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin"
    $path
)
export PATH

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

# pnpm
export PNPM_HOME="/home/karneeshkar/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# opencode
export PATH=/home/karneeshkar/.opencode/bin:$PATH

# --- Pi defaults ---
# Start pi plain by default: don't auto-load AGENTS.md/CLAUDE.md from parent folders.
# To opt a project back into context-file loading, create .pi/load-context-files in that project.
pi() {
    if [[ -f .pi/load-context-files ]]; then
        command pi "$@"
    else
        command pi --no-context-files "$@"
    fi
}
