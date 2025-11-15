#!/usr/bin/env zsh

base_dirs=(~/Desktop/projects ~/Desktop/work ~/Desktop/personal ~/Desktop/Notes/)

selected=$(
  find "${base_dirs[@]}" \
    -mindepth 1 \
    -maxdepth 1 \
    -type d \
  | fzf
)

# if nothing picked, bail
if [[ -z "$selected" ]]; then
  exit 0
fi

# normalize session name
selected_name=$(basename "$selected" | tr '.,: ' '____')

echo "selected: $selected"
echo "session name: $selected_name"

switch_to() {
  if [[ -z "$TMUX" ]]; then
    tmux attach-session -t "$selected_name"
  else
    tmux switch-client -t "$selected_name"
  fi
}

if tmux has-session -t="$selected_name" 2>/dev/null; then
  switch_to
else
  tmux new-session -ds "$selected_name" -c "$selected"
  switch_to
  tmux send-keys -t "$selected_name" "ready-tmux" C-m
fi
