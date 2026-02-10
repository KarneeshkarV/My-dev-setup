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
alias -s mov="xdg-open"
alias -s png="xdg-open"
alias -s mp4="xdg-open"
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
