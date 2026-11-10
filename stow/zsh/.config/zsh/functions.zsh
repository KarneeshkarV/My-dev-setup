# --- Functions ---
t3_serve() {
    t3 serve --host "$(tailscale ip -4)"
}

# Start qBittorrent with downloads in ~/NAS. "qtorrent del" removes the container.
qtorrent() {
    local container_name="qtorrent"
    local config_dir="$HOME/.config/qtorrent"
    local download_dir="$HOME/NAS"
    local webui_port=8081
    local conf_file="$config_dir/qBittorrent/qBittorrent.conf"
    local tailscale_ip username password started=0 i

    if ! command -v docker >/dev/null 2>&1; then
        print -u2 "Docker is not installed."
        return 1
    fi

    if ! docker info >/dev/null 2>&1; then
        print -u2 "Docker is not running. Start Docker and try again."
        return 1
    fi

    # Teardown. Config and downloads stay on disk.
    if [[ "$1" == (del|rm|delete|remove|stop) ]]; then
        if docker rm -f "$container_name" >/dev/null 2>&1; then
            print "Removed container '$container_name'. Config and downloads kept."
        else
            print -u2 "No container named '$container_name'."
            return 1
        fi
        return 0
    fi

    mkdir -p "$config_dir" "$download_dir" || return 1

    if ! docker inspect -f '{{.State.Running}}' "$container_name" 2>/dev/null | grep -qx true; then
        docker rm -f "$container_name" >/dev/null 2>&1 || true
        docker run -d \
            --name "$container_name" \
            --restart unless-stopped \
            -e PUID="$(id -u)" \
            -e PGID="$(id -g)" \
            -e TZ="${TZ:-Asia/Kolkata}" \
            -e WEBUI_PORT="$webui_port" \
            -p "${webui_port}:${webui_port}" \
            -p 6881:6881 \
            -p 6881:6881/udp \
            -v "$config_dir:/config" \
            -v "$download_dir:/downloads" \
            lscr.io/linuxserver/qbittorrent:latest || return 1
        started=1
    fi

    username="$(grep -a '^WebUI.Username=' "$conf_file" 2>/dev/null | tail -n 1 | cut -d= -f2-)"
    [[ -z "$username" ]] && username="admin"

    # qBittorrent prints a per-session temporary password in the log, but only
    # while no permanent password is set in the config.
    for i in {1..30}; do
        password="$(docker logs "$container_name" 2>&1 |
            sed -n 's/.*temporary password is provided for this session: //p' | tail -n 1)"
        [[ -n "$password" ]] && break
        if grep -qa '^WebUI.Password_PBKDF2=' "$conf_file" 2>/dev/null; then
            password="(the one you set in the WebUI)"
            break
        fi
        (( started )) || break
        sleep 1
    done
    [[ -z "$password" ]] && password="(unknown - run: docker logs $container_name)"

    tailscale_ip="$(tailscale ip -4 2>/dev/null | head -n 1)"
    print "qBittorrent is running. Downloads: $download_dir"
    if [[ -n "$tailscale_ip" ]]; then
        print "Open: http://${tailscale_ip}:${webui_port}"
    else
        print "Open: http://localhost:${webui_port}"
    fi
    print "Username: $username"
    print "Password: $password"
}

# Codex wrapper
cdx() {
    if [[ "$1" == "update" ]]; then
        mise upgrade codex
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


# ===== Hosts =====
THINKAR_HOST="thinkar@192.168.0.115"
THINKAR_KEY="$HOME/.ssh/thinkar_key"

# ===== Omen / Cents SSH =====
# omen() and cents() are defined in ~/.secrets (not in git) because they
# contain private host names. ~/.zshrc sources ~/.secrets before this file.

# Run tmux-s on Omen and stay in zsh
otmux-s() {
    ssh -t omen "/home/karneeshkar/.local/scripts/tmux-s; exec zsh"
}

# ===== Thinkar SSH =====
thinkar() {
    ssh -i "$THINKAR_KEY" "$THINKAR_HOST"
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
    local DIR="$HOME/.claude"
    local ACTIVE=".credentials.json"
    local SLOT1=".credentials.har.json"
    local SLOT2=".credentials.val.json"
    local STATE=".credentials.cycle"
    local TMP=".credentials.cycle.tmp.$$"

    [[ ! -f "$DIR/$ACTIVE" ]] && { echo "Error: $ACTIVE not found"; return 1 }

    local mode=""
    if [[ -f "$DIR/$SLOT1" && -f "$DIR/$SLOT2" ]]; then
        # 3-way rotate: active <- har, har <- val, val <- (old active)
        mv "$DIR/$ACTIVE" "$DIR/$TMP" || return 1
        mv "$DIR/$SLOT1"  "$DIR/$ACTIVE" || { mv "$DIR/$TMP" "$DIR/$ACTIVE"; return 1 }
        mv "$DIR/$SLOT2"  "$DIR/$SLOT1"  || return 1
        mv "$DIR/$TMP"    "$DIR/$SLOT2"  || return 1
        mode="rotated"
    elif [[ -f "$DIR/$SLOT1" ]]; then
        mv "$DIR/$ACTIVE" "$DIR/$TMP"    || return 1
        mv "$DIR/$SLOT1"  "$DIR/$ACTIVE" || { mv "$DIR/$TMP" "$DIR/$ACTIVE"; return 1 }
        mv "$DIR/$TMP"    "$DIR/$SLOT1"  || return 1
        mode="swapped har"
    elif [[ -f "$DIR/$SLOT2" ]]; then
        mv "$DIR/$ACTIVE" "$DIR/$TMP"    || return 1
        mv "$DIR/$SLOT2"  "$DIR/$ACTIVE" || { mv "$DIR/$TMP" "$DIR/$ACTIVE"; return 1 }
        mv "$DIR/$TMP"    "$DIR/$SLOT2"  || return 1
        mode="swapped val"
    else
        echo "Error: no backup credentials found"; return 1
    fi

    local idx=0
    [[ -f "$DIR/$STATE" ]] && idx=$(<"$DIR/$STATE")
    echo $(( (idx + 1) % 3 )) > "$DIR/$STATE"

    local tier=$(grep -o '"subscriptionType":"[^"]*"' "$DIR/$ACTIVE" 2>/dev/null | head -1 | cut -d'"' -f4)
    echo "$mode; active tier: ${tier:-unknown}"
}

# Claude with default Anthropic backend
cl() {
    case "$1" in
        update) bun i -g @anthropic-ai/claude-code ;;
        cycle)  cl_cycle ;;
        *)      claude "$@" ;;
    esac
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

# Connect Waynergy to Zen with an optional peer IP address.
way() {
    command waynergy -c "${1:-192.168.0.107}" -p 24800 -N zen -b wlr -E
}

gssh () {
        local line
        line=$(
        gcloud compute instances list \
            --filter="status=RUNNING" \
            --format="table[no-heading](name,zone,machineType.basename(),networkInterfaces[0].networkIP)" |
        column -t |
        fzf --prompt="VM > "
    )  || return
        read -r name zone _ _ <<< "$line"
        gcloud compute ssh "$name" --zone="$zone"
}
