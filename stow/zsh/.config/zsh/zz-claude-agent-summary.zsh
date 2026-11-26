# Disable Claude Code agent summary timers without changing other Bun programs.
claude() {
    local claude_agent_summary_hook="$HOME/.local/share/no-agent-summary.js"
    local -x BUN_OPTIONS="${BUN_OPTIONS-}"
    case " $BUN_OPTIONS " in
        *" --preload=$claude_agent_summary_hook "*|*" --preload $claude_agent_summary_hook "*) ;;
        *) BUN_OPTIONS="${BUN_OPTIONS:+$BUN_OPTIONS }--preload=$claude_agent_summary_hook" ;;
    esac
    local -x CC_AGENT_SUMMARY_LOG="${CC_AGENT_SUMMARY_LOG:-${XDG_RUNTIME_DIR:-/tmp}/no-agent-summary.log}"
    command claude "$@"
}
