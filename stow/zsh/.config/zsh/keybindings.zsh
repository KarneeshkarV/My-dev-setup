# --- Keybindings ---

# Vi mode (optional - uncomment if preferred)
# bindkey -v
# export KEYTIMEOUT=1

# FZF history widget — session commands first, then global by frequency
fzf-history-widget() {
    local result session_start
    session_start=${_zsh_session_start_event:-0}

    result=$(
        {
            # 1. Current session commands (most recent first)
            fc -rln $((session_start + 1)) -1 2>/dev/null | sed 's/^[[:space:]]*//'
            # 2. Pre-session history sorted by frequency
            fc -ln 1 "$session_start" 2>/dev/null | sed 's/^[[:space:]]*//' \
                | sort | uniq -c | sort -rn | sed 's/^[[:space:]]*[0-9]*[[:space:]]*//'
        } | awk '!seen[$0]++' | fzf --height 40% --reverse --border --query="$LBUFFER"
    )
    if [[ -n "$result" ]]; then
        BUFFER="$result"
        CURSOR=$#BUFFER
    fi
    zle reset-prompt
}
zle -N fzf-history-widget
bindkey '^R' fzf-history-widget

# FZF file widget
fzf-file-widget() {
    local file
    file=$(find . -type f -not -path '*/.git/*' 2>/dev/null | fzf --height 40% --reverse --border --preview 'batcat --color=always --line-range :100 {} 2>/dev/null || cat {}')
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

# Tmux session switcher
tmux-s-widget() {
    BUFFER="tmux-s"
    zle accept-line
}
zle -N tmux-s-widget
bindkey '^P' tmux-s-widget

# Word navigation
bindkey '^[[1;5C' forward-word   # Ctrl+Right
bindkey '^[[1;5D' backward-word  # Ctrl+Left
