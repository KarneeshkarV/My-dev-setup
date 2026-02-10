# --- Completions ---
autoload -Uz compinit
autoload -Uz bashcompinit

if [[ -f ~/.zcompdump && $(date +'%j') == $(stat -c '%j' ~/.zcompdump 2>/dev/null) ]]; then
    compinit -C
else
    compinit
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
