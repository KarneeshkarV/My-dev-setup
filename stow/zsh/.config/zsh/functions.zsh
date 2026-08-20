# --- Functions ---

# Check the LiteLLM gateway models with one prompt. Choose a target with fzf;
# the "All models" entry sends all requests concurrently.
_modelcheck_request() {
    local target="$1"
    local prompt="$2"
    local url model payload response curl_status output image_file opener out_file
    # Only set for targets whose body is not JSON; see the tts case below.
    local -a curl_out
    # Per-target ceiling. The chat models answer in seconds, but ERNIE is a
    # diffusion server with batching_max_size=1: one 1024x1024 image is ~90s of
    # denoising plus ~10s of prompt enhancement *on an idle GPU*, and every
    # request already queued ahead of it adds another ~100s. 120s could not pass
    # even unloaded, so give it room to sit through a realistic backlog.
    local max_time=120

    url="${LITELLM_BASE_URL%/}"
    case "$target" in
        qwen-8b)
            model="qwen3-8b"
            payload=$(jq -cn --arg model "$model" --arg prompt "$prompt" \
                '{model: $model, messages: [{role: "user", content: $prompt}], max_tokens: 100}')
            url="$url/v1/chat/completions"
            ;;
        qwen3.6-35b)
            model="qwen3.6-35b"
            payload=$(jq -cn --arg model "$model" --arg prompt "$prompt" \
                '{model: $model, messages: [{role: "user", content: $prompt}], max_tokens: 512}')
            url="$url/v1/chat/completions"
            ;;
        gemma-4e4b)
            model="gemma-4-e4b"
            payload=$(jq -cn --arg model "$model" --arg prompt "$prompt" \
                '{model: $model, messages: [{role: "user", content: $prompt}], max_tokens: 50}')
            url="$url/v1/chat/completions"
            ;;
        ernie-image)
            model="ernie-image"
            payload=$(jq -cn --arg model "$model" --arg prompt "$prompt" \
                '{model: $model, prompt: $prompt, n: 1, size: "1024x1024", response_format: "b64_json"}')
            url="$url/v1/images/generations"
            max_time=1200
            ;;
        docling)
            # Not a LiteLLM model: Docling is fronted by dockling-proxy, so
            # this goes to DOCLING_BASE_URL and converts a tiny page end to end
            # rather than just pinging /health — a proxy pointed at a dead pod
            # still answers, it just 404s.
            model="docling (proxy)"
            # `check <url>` converts that page; anything else (including the
            # default "hi") falls back to a tiny known-good page.
            local source_url="$prompt"
            [[ "$source_url" == http://* || "$source_url" == https://* ]] ||
                source_url="https://example.com"
            payload=$(jq -cn --arg url "$source_url" \
                '{sources: [{kind: "http", url: $url}],
                  options: {to_formats: ["md"], do_ocr: false}}')
            url="${DOCLING_BASE_URL%/}/v1/convert/source"
            ;;
        reranker)
            # The reranker shares the Docling pod but is published through
            # LiteLLM, not dockling-proxy (which routes everything non-TTS to
            # Docling itself), so this one goes to the gateway.
            model="qwen3-reranker"
            payload=$(jq -cn --arg model "$model" \
                '{model: $model,
                  query: "What is the capital of France?",
                  documents: ["Paris is the capital and largest city of France.",
                              "The Nile is the longest river in Africa."]}')
            url="$url/v1/rerank"
            ;;
        tts)
            # Qwen3-TTS answers with raw WAV bytes, not JSON, so this one
            # streams to a file: a $(...) capture mangles the audio, and the
            # only meaningful check is whether real audio came back.
            model="qwen3-tts"
            # Voices are the pod's own speaker set, not the OpenAI names;
            # override with TTS_VOICE to check a specific one.
            payload=$(jq -cn --arg model "$model" --arg input "$prompt" \
                --arg voice "${TTS_VOICE:-priyanka}" \
                '{model: $model, input: $input, voice: $voice}')
            url="$url/v1/audio/speech"
            out_file="$HOME/.cache/modelcheck/tts-$(date +%Y%m%d-%H%M%S).wav"
            mkdir -p -- "${out_file:h}" || return 1
            curl_out=(--output "$out_file")
            # Cold engines and a LatentSync render sharing the card push a
            # short line well past the seconds a warm pod takes.
            max_time=300
            ;;
        *)
            print -u2 -- "Unknown model target: $target"
            return 2
            ;;
    esac

    print -- "=== $model ==="
    print -- "Sending: ${source_url:-$prompt}"
    response=$(curl --fail-with-body --silent --show-error --connect-timeout 5 --max-time "$max_time" \
        -X POST "$url" "${curl_out[@]}" \
        -H "Authorization: Bearer $LITELLM_API_KEY" \
        -H 'Content-Type: application/json' \
        -d "$payload")
    curl_status=$?
    if (( curl_status == 0 )); then
        if [[ "$target" == ernie-image ]]; then
            # Keep the images somewhere durable rather than $TMPDIR: a check
            # worth waiting minutes for is worth being able to look at later.
            mkdir -p -- "$HOME/.cache/modelcheck" || return 1
            image_file="$HOME/.cache/modelcheck/ernie-$(date +%Y%m%d-%H%M%S).png"
            print -r -- "$response" | jq -r '.data[0].b64_json // empty' |
                base64 --decode >| "$image_file"
            # A 200 with no b64_json still writes an empty file, so size is the
            # real test of whether an image came back.
            if [[ ! -s "$image_file" ]]; then
                rm -f -- "$image_file"
                print -u2 -- 'Image response did not contain valid b64_json.'
                print -P "%F{red}✗ Not Working%f"
                return 1
            fi
            print -P "%F{white}Image saved to $image_file ($(du -h -- "$image_file" | cut -f1))%f"
            # Open it in the host viewer when one exists; never let a missing or
            # unhappy viewer turn a successful generation into a failed check.
            for opener in wslview xdg-open open; do
                if (( $+commands[$opener] )); then
                    "$opener" "$image_file" >/dev/null 2>&1 &!
                    break
                fi
            done
        elif [[ "$target" == docling ]]; then
            # A 200 is not enough: docling reports per-document failure in the
            # body, and an empty conversion means the pipeline is broken.
            output=$(print -r -- "$response" | jq -r '.document.md_content // empty' 2>/dev/null)
            if [[ -z "$output" ]]; then
                print -u2 -- "Convert returned no markdown: $(print -r -- "$response" | jq -r '.status // "unparsable"')"
                print -P "%F{red}✗ Not Working%f"
                return 1
            fi
            print -P "%F{white}$(print -r -- "$output" | head -c 200)%f"
        elif [[ "$target" == tts ]]; then
            # A 200 with an empty body still creates the file, so the RIFF
            # header is the real test, not the exit status.
            if [[ ! -s "$out_file" || "$(head -c 4 -- "$out_file")" != RIFF ]]; then
                print -u2 -- "No WAV audio returned: $(head -c 200 -- "$out_file")"
                rm -f -- "$out_file"
                print -P "%F{red}✗ Not Working%f"
                return 1
            fi
            print -P "%F{white}Audio saved to $out_file ($(du -h -- "$out_file" | cut -f1))%f"
        elif [[ "$target" == reranker ]]; then
            # The relevant document must win, not merely come back — a wrong
            # ranking means the model is loaded but useless.
            output=$(print -r -- "$response" | jq -r '.results[0].index // empty' 2>/dev/null)
            if [[ "$output" != 0 ]]; then
                print -u2 -- "Expected document 0 (Paris) to rank first, got: ${output:-no results}"
                print -P "%F{red}✗ Not Working%f"
                return 1
            fi
            print -P "%F{white}Paris ranked first, score $(print -r -- "$response" | jq -r '.results[0].relevance_score // "?"')%f"
        else
            output=$(print -r -- "$response" | jq -r '.choices[0].message.content // .choices[0].text // empty' 2>/dev/null)
            [[ -n "$output" ]] && print -P "%F{white}${output}%f"
        fi
        print -P "%F{green}✓ Working%f"
    else
        # --fail-with-body sent the error body to the file, not to $response.
        if [[ -n "$out_file" && -s "$out_file" ]]; then
            print -u2 -- "$(head -c 200 -- "$out_file")"
            rm -f -- "$out_file"
        fi
        print -P "%F{red}✗ Not Working%f"
    fi
    return "$curl_status"
}

check() {
    local prompt="${*:-hi}"
    local choice target tmpdir result_status=0
    local -a choices targets pids

    (( $+commands[fzf] )) || { print -u2 -- 'check requires fzf.'; return 127; }
    (( $+commands[jq] )) || { print -u2 -- 'check requires jq.'; return 127; }

    choices=(
        'Qwen3 8B (LiteLLM)'
        'Qwen3.6 35B (LiteLLM)'
        'Gemma 4 E4B (LiteLLM)'
        'Ernie Image (LiteLLM)'
        'Docling (dockling-proxy)'
        'Qwen3 Reranker (LiteLLM)'
        'Qwen3 TTS (LiteLLM)'
        'All models (parallel)'
    )
    choice=$(printf '%s\n' "${choices[@]}" | fzf --prompt='Model check > ' --height=40% --reverse --border) || return

    case "$choice" in
        'Qwen3 8B'*) target=qwen-8b ;;
        'Qwen3.6 35B'*) target=qwen3.6-35b ;;
        'Gemma 4 E4B'*) target=gemma-4e4b ;;
        'Ernie Image'*) target=ernie-image ;;
        'Docling'*) target=docling ;;
        'Qwen3 Reranker'*) target=reranker ;;
        'Qwen3 TTS'*) target=tts ;;
        'All models'*)
            tmpdir=$(mktemp -d) || return 1
            targets=(qwen-8b qwen3.6-35b gemma-4e4b ernie-image docling reranker tts)
            for target in "${targets[@]}"; do
                _modelcheck_request "$target" "$prompt" >"$tmpdir/$target" 2>&1 &
                pids+=("$!")
            done
            local i
            for (( i = 1; i <= ${#targets}; i++ )); do
                wait "${pids[$i]}" || result_status=1
                target="${targets[$i]}"
                cat -- "$tmpdir/$target"
            done
            rm -rf -- "$tmpdir"
            return "$result_status"
            ;;
    esac

    _modelcheck_request "$target" "$prompt"
}

# Codex wrapper
check_limits(){
curl -s localhost:8080/account-limits | jq -r '.accounts[] | "\(.email): \(.limits | to_entries | map(select(.value.remaining != "100%" and .value.remaining != "N/A")) | length) models have limits below 100%"'
}
cdx() {
    if [[ "$1" == "update" ]]; then
        npm install -g --prefix "$HOME/.npm-global" @openai/codex@latest
        hash -r
        codex --version
    else
        codex --search --sandbox=danger-full-access -c sandbox_workspace_write.network_access=true "$@"
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
