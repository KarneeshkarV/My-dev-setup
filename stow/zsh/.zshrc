
cdx() {
  if [[ "$1" == "update" ]]; then
    npm install -g @openai/codex@latest
  else
    codex \
      --model 'gpt-5-codex' \
      --full-auto \
      -c model_reasoning_summary_format=experimental \
      --search "$@"
  fi
}
# --- Aliases ---
alias bat="batcat"
alias ls="exa --icons --group-directories-first"
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
fab() {
  local url="$1"
  local out="$2"
  local selected_pattern
  local cmd

  # Prompt user to select a pattern using fzf
  # The <&1 ensures fzf reads from the terminal even if stdin is redirected
  # The --height option prevents fzf from taking the full screen if the list is short
  selected_pattern=$(fabric -l | fzf --height 40% <&1)

  # Exit if no pattern was selected (e.g., user pressed Esc or Ctrl+C)
  if [[ -z "$selected_pattern" ]]; then
    echo "No pattern selected. Aborting." >&2 # Send error message to stderr
    return 1 # Indicate failure
  fi

  # Build the base command array using the selected pattern
  cmd=(fabric "$url" -p="$selected_pattern" -s)

  # Conditionally add the output argument if a second argument was provided
  if [[ -n "$out" ]]; then
    cmd+=(-o="$out")
  fi

  # Optional: Print the command that will be run (for debugging)
  # echo "Running: noglob ${cmd[*]}"

  # Run the command
  # Using noglob prevents globbing expansion on the command arguments
  noglob "${cmd[@]}"
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
zclaude() {
export ANTHROPIC_BASE_URL=https://api.z.ai/api/anthropic
export ANTHROPIC_AUTH_TOKEN=
claude
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
dan_sum() {
  local url="$1"
  local out="$2"

  # base command
  local cmd=(fabric -y="$url" -p=dan_summarize -s)

  # only add -o if a second argument was provided
  if [[ -n "$out" ]]; then
    cmd+=(-o="$out")
  fi

  # run it
noglob  "${cmd[@]}"
}
rate_label() {
  local url="$1"
  local out="$2"

  # base command
  local cmd=(fabric -y="$url" -p=label_and_rate -s)

  # only add -o if a second argument was provided
  if [[ -n "$out" ]]; then
    cmd+=(-o="$out")
  fi

  # run it
noglob  "${cmd[@]}"
}
sum() {
  local url="$1"
  local out="$2"

  # base command
  local cmd=(fabric -y="$url" -p=summarize -s)

  # only add -o if a second argument was provided
  if [[ -n "$out" ]]; then
    cmd+=(-o="$out")
  fi

  # run it
noglob  "${cmd[@]}"
}
# --- External Tools ---
eval "$(starship init zsh)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH="$HOME/.local/scripts:$PATH"
# pnpm
export PNPM_HOME="/home/karneeshkar/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
export PATH="$HOME/.local/bin:$PATH"

# bun completions
[ -s "/home/karneeshkar/.bun/_bun" ] && source "/home/karneeshkar/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
eval "$(zoxide init --cmd cd zsh)"

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
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

