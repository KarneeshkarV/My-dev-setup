# --- Lazy Loading (Performance Optimization) ---

# NVM - lazy load for faster shell startup
lazy_load_nvm() {
    unset -f nvm node npm npx 2>/dev/null
    export NVM_DIR="$HOME/.nvm"
    [[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"
    [[ -s "$NVM_DIR/bash_completion" ]] && \. "$NVM_DIR/bash_completion"
}
nvm() { lazy_load_nvm && nvm "$@"; }
node() { lazy_load_nvm && node "$@"; }
npm() { lazy_load_nvm && npm "$@"; }
npx() { lazy_load_nvm && npx "$@"; }

# --- External Tools Initialization ---

# Homebrew (lazy-loaded for faster startup)
_brew_shellenv_cache="$HOME/.cache/brew_shellenv"
if [[ ! -f "$_brew_shellenv_cache" ]] || [[ "/home/linuxbrew/.linuxbrew/bin/brew" -nt "$_brew_shellenv_cache" ]]; then
    mkdir -p "$(dirname "$_brew_shellenv_cache")"
    /home/linuxbrew/.linuxbrew/bin/brew shellenv > "$_brew_shellenv_cache"
fi
source "$_brew_shellenv_cache"
unset _brew_shellenv_cache

# Starship prompt
eval "$(starship init zsh)"

# Zoxide (smart cd) - skip when DISABLE_ZOXIDE is set (e.g., in Claude Code)
if [ -z "$DISABLE_ZOXIDE" ]; then
    eval "$(zoxide init --cmd cd zsh)"
fi

# FZF
[[ -f "$HOME/.fzf.zsh" ]] && source "$HOME/.fzf.zsh"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --preview-window=right:50%"
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'

# Local environment
[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"
