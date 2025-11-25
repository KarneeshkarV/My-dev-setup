
cdx() {
  if [[ "$1" == "update" ]]; then
    brew upgrade @openai/codex@latest
  else
    codex \
      --model 'gpt-5.1-codex' \
      --full-auto \
      -c model_reasoning_summary_format=experimental \
      --search "$@"
  fi
}
# --- Aliases ---
alias bat="batcat"
alias ls="exa --icons --group-directories-first"
alias sound="pavucontrol &"
alias goose-ai='/home/karneeshkar/.local/bin/goose'
alias goose-db='/home/karneeshkar/go/bin/goose'
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'
alias vim="nvim"
alias python="python3"
alias notify='curl -d "done" http://192.168.0.107/notify'
alias claudeu='bunx ccusage daily'
alias claudeum='bunx ccusage monthly'
alias figma='bunx figma-developer-mcp --figma-api-key=$FIGMA_API_KEY'
alias VimBeGood='docker run -it --rm brandoncc/vim-be-good:latest'
fzf-history-widget() {
  BUFFER=$(history -n 1 | tac | fzf --height 40% --reverse --border)
  CURSOR=$#BUFFER
}
zle     -N   fzf-history-widget
bindkey '^R' fzf-history-widget
gAllBranch() {
  # 1) update all remotes
  git fetch --all

  # 2) for each origin/* remote branch (minus HEAD), create a local tracking branch if missing
  git for-each-ref --format='%(refname:lstrip=3)' refs/remotes/origin \
    | grep -v '^HEAD$' \
    | while read -r branch; do
        # if a local branch by this name already exists, skip
        if git show-ref --quiet refs/heads/"$branch"; then
          echo "Skipping existing branch '$branch'"
        else
          echo "Tracking new branch '$branch' → origin/$branch"
          git branch --track "$branch" "origin/$branch"
        fi
      done

  # 3) pull from all remotes
  git pull --all
}
git_fetch_all() {
git branch -r \
  | grep -v '\->' \
  | sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" \
  | while read remote; do \
      git branch --track "${remote#origin/}" "$remote"; \
    done
git fetch --all
git pull --all
   
}
omen(){
  ssh karneeshkar@192.168.0.106
}
zclaude() {
export ANTHROPIC_BASE_URL=https://api.z.ai/api/anthropic
export ANTHROPIC_AUTH_TOKEN=
claude
}
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}
deepseek() {
    export ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
    export ANTHROPIC_AUTH_TOKEN=$DEEPSEEK_API_KEY
    export API_TIMEOUT_MS=600000
    export ANTHROPIC_MODEL=deepseek-chat
    export ANTHROPIC_SMALL_FAST_MODEL=deepseek-chat
    export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
    claude $1
}
cl(){
    unset ANTHROPIC_BASE_URL
    unset ANTHROPIC_AUTH_TOKEN
    unset ANTHROPIC_MODEL 
    unset ANTHROPIC_SMALL_FAST_MODEL
    claude $1
}
weather(){
curl http://wttr.in/$1
}
# --- External Tools ---
eval "$(starship init zsh)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export PATH="$HOME/.local/scripts:$PATH"


export ANDROID_SDK_ROOT=/opt/android-sdk
export ANDROID_HOME=/opt/android-sdk
export PATH=$PATH:/opt/android-sdk/emulator
export PATH=$PATH:/opt/android-sdk/platform-tools
export PATH=$PATH:/opt/android-sdk/cmdline-tools/latest/bin
# pnpm
export PNPM_HOME="/home/karneeshkar/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"

# bun completions
[ -s "/home/karneeshkar/.bun/_bun" ] && source "/home/karneeshkar/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
eval "$(zoxide init --cmd cd zsh)"

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH


# JINA_CLI_BEGIN

## autocomplete
if [[ ! -o interactive ]]; then
    return
fi

compctl -K _jina jina

_jina() {
  local words completions
  read -cA words

  if [ "${#words}" -eq 2 ]; then
    completions="$(jina commands)"
  else
    completions="$(jina completions ${words[2,-2]})"
  fi

  reply=(${(ps:
:)completions})
}

# session-wise fix
ulimit -n 4096
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

# JINA_CLI_END

