# --- Functions ---

# Codex wrapper
check_limits(){
curl -s localhost:8080/account-limits | jq -r '.accounts[] | "\(.email): \(.limits | to_entries | map(select(.value.remaining != "100%" and .value.remaining != "N/A")) | length) models have limits below 100%"'
}
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

# SSH to Thinkar machine
thinkar() {
    ssh -i ~/.ssh/thinkar_key thinkar@192.168.0.115
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
cl_anti(){

      rm -rf ~/.claude/settings.json
      cp ~/.claude/settings.anti.json ~/.claude/settings.json
      bunx antigravity-claude-proxy start
  }

cl_native(){
      rm -rf ~/.claude/settings.json
      cp ~/.claude/settings.native.json ~/.claude/settings.json
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
        *.tar.bz2)   tar xjf "$1"       ;;
        *.tar.gz)    tar xzf "$1"       ;;
        *.tar.xz)    tar xJf "$1"       ;;
        *.tar.zst)   tar --zstd -xf "$1" ;;
        *.bz2)       bunzip2 "$1"       ;;
        *.rar)       unrar x "$1"       ;;
        *.gz)        gunzip "$1"        ;;
        *.tar)       tar xf "$1"        ;;
        *.tbz2)      tar xjf "$1"       ;;
        *.tgz)       tar xzf "$1"       ;;
        *.zip)       unzip "$1"         ;;
        *.Z)         uncompress "$1"    ;;
        *.7z)        7z x "$1"          ;;
        *.zst)       unzstd "$1"        ;;
        *)           echo "'$1' cannot be extracted" ;;
    esac
}

# Find and kill process by port
killport() {
    local port="${1:?Port required}"
    fuser -k "${port}/tcp" 2>/dev/null && echo "Killed process on port $port" || echo "No process on port $port"
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
tasks() {
  local listId="${1:-MTYzNzYwMzkyMjM2OTk5MjUxMDk6MDow}"
  local nowEpoch now5h
  nowEpoch=$(date +%s)
  now5h=$(( nowEpoch + 5 * 3600 ))

  local tasksJson
  tasksJson=$(gog tasks list "$listId" --json)

  # Helper function to format dates with relative labels
  format_task_date() {
    local epoch=$1
    local duedate=$2
    local today_start=$(date -d "today 00:00:00" +%s)
    local tomorrow_start=$(date -d "tomorrow 00:00:00" +%s)
    local yesterday_start=$(date -d "yesterday 00:00:00" +%s)

    local formatted_date
    if [[ "$duedate" =~ T00:00:00\.000Z$ ]]; then
      # All-day task - show relative date
      if (( epoch >= today_start && epoch < tomorrow_start )); then
        formatted_date="Today ($(TZ='Asia/Kolkata' date -d "@$epoch" '+%b %d'))"
      elif (( epoch >= tomorrow_start && epoch < tomorrow_start + 86400 )); then
        formatted_date="Tomorrow ($(TZ='Asia/Kolkata' date -d "@$epoch" '+%b %d'))"
      elif (( epoch >= yesterday_start && epoch < today_start )); then
        formatted_date="Yesterday ($(TZ='Asia/Kolkata' date -d "@$epoch" '+%b %d'))"
      else
        formatted_date=$(TZ='Asia/Kolkata' date -d "@$epoch" '+%a %b %d, %Y')
      fi
    else
      # Task with specific time
      formatted_date=$(TZ='Asia/Kolkata' date -d "@$epoch" '+%a %b %d, %Y %I:%M %p IST')
    fi
    echo "$formatted_date"
  }

  # Past/Overdue tasks (in red)
  local pastTasks
  pastTasks=$(echo "$tasksJson" | jq --arg s "$nowEpoch" -r '
    .tasks[]
    | select(.status == "needsAction")
    | select(.due != null)
    | ( .due | sub("\\.[0-9]{3}Z$"; "Z") | fromdate ) as $d
    | select($d < ($s|tonumber))
    | "\($d)|\(.due)|\(.title)"' | while IFS='|' read -r epoch duedate title; do
      local formatted_date=$(format_task_date "$epoch" "$duedate")
      echo "\e[31m${formatted_date}  ${title}\e[0m"
    done)

  # Upcoming tasks (in blue) - next 3 tasks, regardless of time
  local upcomingTasks
  upcomingTasks=$(echo "$tasksJson" | jq --arg s "$nowEpoch" -r '
    [.tasks[]
    | select(.status == "needsAction")
    | select(.due != null)
    | ( .due | sub("\\.[0-9]{3}Z$"; "Z") | fromdate ) as $d
    | select($d >= ($s|tonumber))
    | {epoch: $d, due: .due, title: .title}]
    | sort_by(.epoch)
    | .[:3][]
    | "\(.epoch)|\(.due)|\(.title)"' | while IFS='|' read -r epoch duedate title; do
      local formatted_date=$(format_task_date "$epoch" "$duedate")
      echo "\e[34m${formatted_date}  ${title}\e[0m"
    done)

  # Display results
  if [[ -n "$pastTasks" ]]; then
    echo "\e[1;31m=== OVERDUE TASKS ===\e[0m"
    echo "$pastTasks"
  fi

  if [[ -n "$upcomingTasks" ]]; then
    [[ -n "$pastTasks" ]] && echo ""
    echo "\e[1;34m=== UPCOMING (Next 3 Tasks) ===\e[0m"
    echo "$upcomingTasks"
  fi

  if [[ -z "$pastTasks" && -z "$upcomingTasks" ]]; then
    echo "No upcoming or overdue tasks."
  fi
}
bench() {
    local n="${1:-10}"
    shift
    for i in $(seq 1 "$n"); do
        time ( eval "$@" ) 2>&1
    done | grep real | awk '{sum+=$2; count++} END {print "Average:", sum/count "s"}'
}
# Quick file backup
bak() {
    cp "$1" "$1.bak.$(date +%Y%m%d_%H%M%S)"
}

# Find files quickly
ff() {
    find . -type f -iname "*$1*" 2>/dev/null
}

# Find directories quickly (named fdir to avoid conflict with fd-find)
fdir() {
    find . -type d -iname "*$1*" 2>/dev/null
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
