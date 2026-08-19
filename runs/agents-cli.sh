#!/usr/bin/env bash

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source distro utilities
source "$PROJECT_ROOT/lib/distro-utils.sh"

# Initialize distro detection
init_distro

# AI coding agent CLIs, all resolved through the mise registry
AGENT_CLIS=(claude codex opencode pi)

BIN_DIR="$HOME/.local/bin"

echo "Installing AI agent CLIs..."

# --- mise: the version manager every agent CLI is installed through ---
if ! command_exists mise; then
    echo "Installing mise..."
    case "$DISTRO" in
        arch)
            install_packages mise
            ;;
        debian)
            curl -fsSL https://mise.run | sh
            export PATH="$HOME/.local/bin:$PATH"
            ;;
    esac
else
    echo "mise already installed"
fi

if ! command_exists mise; then
    echo -e "${RED}mise not available. Cannot install agent CLIs.${NC}"
    exit 1
fi

mise --version

# --- Install each agent CLI globally ---
for cli in "${AGENT_CLIS[@]}"; do
    echo "Installing $cli..."
    # Agent CLIs ship fixes daily, so the release-age hold does not apply here
    MISE_MINIMUM_RELEASE_AGE=0 mise use -g "$cli@latest"
done

# --- Wrapper shims that update the CLI to latest on every launch ---
mkdir -p "$BIN_DIR"

for cli in "${AGENT_CLIS[@]}"; do
    shim="$BIN_DIR/$cli"
    cat > "$shim" <<EOF
#!/bin/bash
export MISE_MINIMUM_RELEASE_AGE=0
mise use -g "$cli" || exit 1
exec mise x "$cli" -- "$cli" "\$@"
EOF
    chmod +x "$shim"
    echo "Shim written: $shim"
done

# --- Verify ---
echo "Agent CLI installation complete!"
for cli in "${AGENT_CLIS[@]}"; do
    if command_exists "$cli"; then
        printf '%-10s %s\n' "$cli" "$("$cli" --version 2>/dev/null | head -1)"
    else
        echo -e "${YELLOW}$cli not on PATH. Add $BIN_DIR to PATH.${NC}"
    fi
done
