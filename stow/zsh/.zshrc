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
setopt SHARE_HISTORY          # Share history between sessions (implies INC_APPEND_HISTORY)
setopt EXTENDED_HISTORY       # Add timestamps to history
setopt HIST_IGNORE_SPACE      # Don't record commands starting with space
setopt HIST_VERIFY            # Show command before executing from history

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

# --- Load Modular Config ---
ZSH_CONFIG_DIR="${ZDOTDIR:-$HOME/.config/zsh}"
for config_file in "$ZSH_CONFIG_DIR"/*.zsh(N); do
    source "$config_file"
done
unset config_file
