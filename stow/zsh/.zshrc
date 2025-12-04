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

# --- History Configuration ---
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_ALL_DUPS   # No duplicate entries
setopt HIST_FIND_NO_DUPS      # No duplicates in search
setopt HIST_REDUCE_BLANKS     # Remove unnecessary blanks
setopt SHARE_HISTORY          # Share history between sessions
setopt INC_APPEND_HISTORY     # Write immediately, not on exit
setopt EXTENDED_HISTORY       # Add timestamps to history

# --- Environment Variables ---
export EDITOR="nvim"
export VISUAL="nvim"
export ANDROID_SDK_ROOT=/opt/android-sdk
export ANDROID_HOME=/opt/android-sdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export BUN_INSTALL="$HOME/.bun"
export PNPM_HOME="$HOME/.local/share/pnpm"

# Session-wise fix
ulimit -n 4096
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

# --- Secrets (API keys, tokens - keep out of git) ---
[ -f ~/.secrets ] && source ~/.secrets

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

# --- Aliases ---
# File navigation & listing
alias ls="eza --icons --group-directories-first"
alias ll="eza --icons --group-directories-first -la"
alias lt="eza --icons --tree --level=2"
alias bat="batcat"

# Clipboard (macOS style)
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'

# Applications
alias vim="nvim"
alias python="python3"
alias sound="pavucontrol &"

# Goose disambiguation
alias goose-ai='/home/karneeshkar/.local/bin/goose'
alias goose-db='/home/karneeshkar/go/bin/goose'

# Claude usage
alias claudeu='bunx ccusage daily'
alias claudeum='bunx ccusage monthly'

# Misc utilities
alias notify='curl -d "done" http://192.168.0.107/notify'
alias figma='bunx figma-developer-mcp --figma-api-key=$FIGMA_API_KEY'
alias VimBeGood='docker run -it --rm brandoncc/vim-be-good:latest'

# Quick config edits
alias zshrc='${EDITOR} ~/.zshrc'
alias reload='source ~/.zshrc'

# --- Functions ---

# Codex wrapper
cdx() {
  if [[ "$1" == "update" ]]; then
      brew upgrade codex
  else
     codex --search --sandbox=danger-full-access  -c sandbox_workspace_write.network_access=true
  fi
}

# Git: fetch all branches and set up tracking
gfa() {
    git fetch --all
    git branch -r | grep -v '\->' | sed 's/origin\///' | while read -r branch; do
        if git show-ref --quiet "refs/heads/$branch"; then
            echo "⏭  Skipping existing branch '$branch'"
        else
            echo "✓  Tracking new branch '$branch' → origin/$branch"
            git branch --track "$branch" "origin/$branch"
        fi
    done
    git pull --all
}

# SSH to Omen machine
omen() {
    ssh karneeshkar@192.168.0.106
}

# Claude with Z.ai backend
zclaude() {
    export ANTHROPIC_BASE_URL=https://api.z.ai/api/anthropic
    export ANTHROPIC_AUTH_TOKEN=
    claude
}

# Claude with DeepSeek backend
deepseek() {
    export ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
    export ANTHROPIC_AUTH_TOKEN=$DEEPSEEK_API_KEY
    export API_TIMEOUT_MS=600000
    export ANTHROPIC_MODEL=deepseek-chat
    export ANTHROPIC_SMALL_FAST_MODEL=deepseek-chat
    export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
    claude "$@"
}

# Claude with default Anthropic backend
cl() {
  if [[ "$1" == "update" ]]; then
        brew upgrade claude
  else
#    unset ANTHROPIC_BASE_URL
    #unset ANTHROPIC_AUTH_TOKEN
    #unset ANTHROPIC_MODEL
    #unset ANTHROPIC_SMALL_FAST_MODEL
    claude "$@"

  fi

}

# Weather lookup
weather() {
    curl -s "http://wttr.in/${1:-}"
}

# Yazi file manager with cd on exit
y() {
    local tmp cwd
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract any archive
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"    ;;
            *.tar.gz)    tar xzf "$1"    ;;
            *.tar.xz)    tar xJf "$1"    ;;
            *.bz2)       bunzip2 "$1"    ;;
            *.rar)       unrar x "$1"    ;;
            *.gz)        gunzip "$1"     ;;
            *.tar)       tar xf "$1"     ;;
            *.tbz2)      tar xjf "$1"    ;;
            *.tgz)       tar xzf "$1"    ;;
            *.zip)       unzip "$1"      ;;
            *.Z)         uncompress "$1" ;;
            *.7z)        7z x "$1"       ;;
            *)           echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# --- Keybindings ---
# FZF history widget
fzf-history-widget() {
    BUFFER=$(history -n 1 | tac | fzf --height 40% --reverse --border)
    CURSOR=$#BUFFER
}
zle -N fzf-history-widget
bindkey '^R' fzf-history-widget

# --- Lazy Loading (Performance Optimization) ---

# NVM - lazy load for faster shell startup
lazy_load_nvm() {
    unset -f nvm node npm npx 2>/dev/null
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}
nvm() { lazy_load_nvm && nvm "$@"; }
node() { lazy_load_nvm && node "$@"; }
npm() { lazy_load_nvm && npm "$@"; }
npx() { lazy_load_nvm && npx "$@"; }

# --- Completions ---
autoload -Uz compinit
# Only regenerate completions once a day
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# Bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Jina completions
if [[ -o interactive ]]; then
    compctl -K _jina jina
    _jina() {
        local words completions
        read -cA words
        if [ "${#words}" -eq 2 ]; then
            completions="$(jina commands)"
        else
            completions="$(jina completions ${words[2,-2]})"
        fi
        reply=(${(ps:\n:)completions})
    }
fi

# --- External Tools Initialization ---
# Homebrew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Starship prompt
eval "$(starship init zsh)"

# Zoxide (smart cd)
eval "$(zoxide init --cmd cd zsh)"

# FZF
[ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"

# Local environment
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# --- Plugins (install if not present) ---
# zsh-syntax-highlighting
if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [ -f /home/linuxbrew/.linuxbrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /home/linuxbrew/.linuxbrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# zsh-autosuggestions
if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [ -f /home/linuxbrew/.linuxbrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /home/linuxbrew/.linuxbrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi
