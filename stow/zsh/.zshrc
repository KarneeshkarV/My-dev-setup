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
    "/usr/local/go/bin"
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

# Add grok completion functions to fpath BEFORE compinit runs, so the single
# compinit (in completions.zsh) picks up _grok. Adding another compinit later
# would wipe runtime compdefs such as zoxide's `cd` completion.
fpath=(~/.grok/completions/zsh $fpath)

for config_file in "$ZSH_CONFIG_DIR"/*.zsh(N); do
    source "$config_file"
done
unset config_file

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Add local scripts to PATH
export PATH="/home/centserver/My-dev-setup/stow/scripts/.local/scripts:$PATH"

# Initialize Starship prompt
eval "$(starship init zsh)"

# Pi coding agent (managed runtime; follows the active Pi Node version)
export PATH="$HOME/.local/share/pi-node/current/bin:$PATH"

# opencode
export PATH=/home/centserver/.opencode/bin:$PATH

. "$HOME/.local/bin/env"

# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
# NOTE: fpath for _grok is set earlier (before the module loop). Do NOT run
# compinit again here: a second compinit rebuilds the completion table and
# discards runtime compdefs, breaking zoxide's `cd` completion.
# <<< grok installer <<<

eval "$(/home/centserver/.local/bin/mise activate zsh)"

# AI Usage Bar release limits command
alias limits='/home/centserver/projects/AI-Usage-Bar/target/release/ai-usage-bar limits'
