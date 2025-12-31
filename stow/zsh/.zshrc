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
setopt SHARE_HISTORY          # Share history between sessions
setopt INC_APPEND_HISTORY     # Write immediately, not on exit
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

# --- Aliases ---
# File navigation & listing
alias ls="eza --icons --group-directories-first"
alias ll="eza --icons --group-directories-first -la"
alias la="eza --icons --group-directories-first -a"
alias lt="eza --icons --tree --level=2"
alias lta="eza --icons --tree --level=2 -a"
alias l="eza --icons -1"
alias bat="batcat"

# Directory navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias -- -="cd -"             # Go to previous directory
alias d='dirs -v'             # Show directory stack

# Suffix aliases (auto-open files by extension)
alias -s md="bat"
alias -s mov="open"
alias -s png="open"
alias -s mp4="open"
alias -s go="$EDITOR"
alias -s js="$EDITOR"
alias -s ts="$EDITOR"
alias -s yaml="bat -l yaml"
alias -s json="jless"

# Clipboard (macOS style)
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'

# Applications
alias vim="nvim"
alias vi="nvim"
alias v="nvim"
alias python="python3"
alias py="python3"
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
alias reload='source ~/.zshrc && echo "✓ zshrc reloaded"'
alias nvimrc='${EDITOR} ~/.config/nvim'


# Misc safety nets
alias rm="rm -i"
alias mv="mv -i"
alias cp="cp -i"

# Quick look at ports
alias ports="ss -tulanp"

# --- Functions ---

# Codex wrapper
cdx() {
    if [[ "$1" == "update" ]]; then
        brew upgrade codex
    else
        codex --search --sandbox=danger-full-access -c sandbox_workspace_write.network_access=true
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

# Interactive git branch switch with fzf
gbf() {
    local branch
    branch=$(git branch --all | grep -v HEAD | sed 's/.* //' | sed 's#remotes/origin/##' | sort -u | fzf --height 40% --reverse --border --preview "git log --oneline --graph --color=always {}")
    [[ -n "$branch" ]] && git checkout "$branch"
}

# Interactive git log with fzf
glf() {
    git log --oneline --color=always | fzf --ansi --height 50% --reverse --preview "git show --color=always {1}" | awk '{print $1}' | xargs -r git show
}

# Quick commit with message
gcq() {
    git add -A && git commit -m "${*:-Quick commit}"
}

# SSH to Omen machine
omen() {
    ssh karneeshkar@192.168.0.106
}

# Claude with Z.ai backend
zclaude() {
    export ANTHROPIC_BASE_URL=https://api.z.ai/api/anthropic
    export ANTHROPIC_AUTH_TOKEN=
    SHELL=/bin/bash commanda claude
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

cl_cycle() {
    local CREDS=(".credentials.val.json" ".credentials.2cc.json" ".credentials.harz.json")
    local ACTIVE=".credentials.json"
    local CREDS_DIR="$HOME/.claude"

    cd "$CREDS_DIR" || return 1

    if [[ ! -f "$ACTIVE" ]]; then
        if [[ -f "${CREDS[1]}" ]]; then
            mv "${CREDS[1]}" "$ACTIVE"
            echo "Activated: ${CREDS[1]} -> $ACTIVE"
        else
            echo "Error: No credential files found!"
            return 1
        fi
        cd - > /dev/null
        return 0
    fi

    for i in {1..${#CREDS[@]}}; do
        if [[ ! -f "${CREDS[$i]}" ]]; then
            mv "$ACTIVE" "${CREDS[$i]}"
            local next_i=$(( i % ${#CREDS[@]} + 1 ))
            mv "${CREDS[$next_i]}" "$ACTIVE"
            echo "Switched: ${CREDS[$i]} -> ${CREDS[$next_i]}"
            echo "Active credential: ${CREDS[$next_i]}"
            cd - > /dev/null
            return 0
        fi
    done

    echo "Error: Could not determine active credential file!"
    cd - > /dev/null
    return 1
}

# Claude with default Anthropic backend
cl() {
    case "$1" in
        update) bun i -g @anthropic-ai/claude-code ;;
        cycle)  cl_cycle ;;
        *)      claude "$@" ;;
    esac
}

sleeps() {
    systemctl suspend
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
    [[ -n "$cwd" && "$cwd" != "$PWD" ]] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

# Auto-activate Python virtual environments on directory change
auto_activate_venv() {
    local venv_dirs=(".venv" ".venv3" "venv" ".env")
    for dir in "${venv_dirs[@]}"; do
        if [[ -d "$dir" && -f "$dir/bin/activate" ]]; then
            source "$dir/bin/activate"
            return
        fi
    done
}
chpwd_functions+=(auto_activate_venv)

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract any archive
extract() {
    if [[ ! -f "$1" ]]; then
        echo "'$1' is not a valid file"
        return 1
    fi
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
}

# Find and kill process by port
killport() {
    local port="${1:?Port required}"
    local pid=$(lsof -t -i:$port)
    if [[ -n "$pid" ]]; then
        echo "Killing process $pid on port $port"
        kill -9 "$pid"
    else
        echo "No process found on port $port"
    fi
}

# Quick HTTP server
serve() {
    local port="${1:-8000}"
    echo "Serving at http://localhost:$port"
    python3 -m http.server "$port"
}

# Quick JSON formatting
json() {
    if [[ -p /dev/stdin ]]; then
        cat | jq .
    else
        jq . "$1"
    fi
}

# Quick file backup
bak() {
    cp "$1" "$1.bak.$(date +%Y%m%d_%H%M%S)"
}

# Find files quickly
ff() {
    find . -type f -iname "*$1*" 2>/dev/null
}

# Find directories quickly
fd() {
    find . -type d -iname "*$1*" 2>/dev/null
}

# Grep with context (use ripgrep if available)
rg() {
    if command -v rg &>/dev/null; then
        command rg --smart-case "$@"
    else
        grep -rn --color=auto "$@"
    fi
}

# Quick note taking
note() {
    local notes_dir="$HOME/notes"
    mkdir -p "$notes_dir"
    if [[ -z "$1" ]]; then
        $EDITOR "$notes_dir/scratch.md"
    else
        $EDITOR "$notes_dir/$1.md"
    fi
}

# Show top CPU/memory processes
topcpu() { ps aux --sort=-%cpu | head -${1:-10}; }
topmem() { ps aux --sort=-%mem | head -${1:-10}; }

# Benchmark shell startup time
zbench() {
    for i in $(seq 1 10); do
        time zsh -i -c exit
    done
}

# --- Keybindings ---
# Vi mode (optional - uncomment if preferred)
# bindkey -v
# export KEYTIMEOUT=1

# FZF history widget
fzf-history-widget() {
    BUFFER=$(history -n 1 | tac | fzf --height 40% --reverse --border --query="$LBUFFER")
    CURSOR=$#BUFFER
    zle reset-prompt
}
zle -N fzf-history-widget
bindkey '^R' fzf-history-widget

# FZF file widget
fzf-file-widget() {
    local file
    file=$(fzf --height 40% --reverse --border --preview 'batcat --color=always --line-range :100 {} 2>/dev/null || cat {}')
    [[ -n "$file" ]] && LBUFFER+="$file"
    zle reset-prompt
}
zle -N fzf-file-widget
bindkey '^T' fzf-file-widget

# FZF cd widget
fzf-cd-widget() {
    local dir
    dir=$(find . -type d 2>/dev/null | fzf --height 40% --reverse --border --preview 'eza --icons --tree --level=1 {}')
    [[ -n "$dir" ]] && cd "$dir"
    zle reset-prompt
}
zle -N fzf-cd-widget
bindkey '^G' fzf-cd-widget

# Open buffer line in editor
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line

# Word navigation
bindkey '^[[1;5C' forward-word   # Ctrl+Right
bindkey '^[[1;5D' backward-word  # Ctrl+Left

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
# Homebrew (must be before completions)
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# --- Completions ---
autoload -Uz compinit
autoload -Uz bashcompinit

# Only regenerate completions once a day
if [[ -n $HOME/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

bashcompinit

# Completion styles
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}No matches found%f'
zstyle ':completion:*' rehash true
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# Bun completions
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# Jina completions
if [[ -o interactive ]]; then
    compctl -K _jina jina
    _jina() {
        local words completions
        read -cA words
        if [[ "${#words}" -eq 2 ]]; then
            completions="$(jina commands)"
        else
            completions="$(jina completions ${words[2,-2]})"
        fi
        reply=(${(ps:\n:)completions})
    }
fi

# Starship prompt
eval "$(starship init zsh)"

# Zoxide (smart cd)
eval "$(zoxide init --cmd cd zsh)"

# FZF
[[ -f "$HOME/.fzf.zsh" ]] && source "$HOME/.fzf.zsh"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --preview-window=right:50%"
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'

# Local environment
[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"

# --- Plugins ---
# zsh-syntax-highlighting
if [[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [[ -f /home/linuxbrew/.linuxbrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source /home/linuxbrew/.linuxbrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# zsh-autosuggestions
if [[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [[ -f /home/linuxbrew/.linuxbrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source /home/linuxbrew/.linuxbrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
