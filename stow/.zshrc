# --- PATH Setup ---
export PATH="$HOME/Softwares:$PATH"
export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"
export PATH="$HOME/.local/scripts:$PATH"

# --- Environment Variables ---
export GOPATH="$HOME/go"
# --- Aliases ---
alias bat="batcat"
alias vim="nvim"
alias python="python3"
alias notify='curl -d "done" http://192.168.0.107/notify'

# --- Function ----
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
[ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
eval "$(zoxide init --cmd cd zsh)"
