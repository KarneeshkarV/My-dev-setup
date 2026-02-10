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
