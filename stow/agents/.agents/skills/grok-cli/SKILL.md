---
description: Use Grok Build CLI from Codex, especially headless/scripted runs with `grok -p` or `grok --single`, model selection for Grok 4.5 and Composer 2.5, deep reasoning via `--effort`/`--reasoning-effort`, JSON output, session resume/continue, auto-approval, worktrees, and checking local Grok CLI flags.
metadata:
    github-path: grok-cli
    github-ref: refs/heads/main
    github-repo: https://github.com/KarneeshkarV/grok-cli-skill
    github-tree-sha: f90127d3a2d721eed8047c02f1f3846dfa854e02
name: grok-cli
---
# Grok CLI

Use this skill when the user wants Codex to delegate a coding, analysis, or automation task to Grok Build, run Grok in headless mode, choose between Grok models, or explain Grok CLI flags.

## Headless Quick Start

Headless mode is `-p` / `--single`. It sends one prompt, prints to stdout, and exits.

```bash
grok -p "Explain this codebase"
grok --single "List TODO comments" --output-format json
grok --prompt-file prompt.md --output-format streaming-json
```

Use `--no-auto-update` in CI/scripts if update checks would pollute logs or block automation:

```bash
grok --no-auto-update -p "Explain this repo" --output-format plain
```

Use `--cwd <PATH>` instead of `cd` when a script needs an explicit working directory:

```bash
grok --cwd /path/to/repo -p "Run the test suite and summarize failures"
```

## Model Selection

Known model ids from the local Grok CLI environment used to author this skill:

- `grok-4.5`: default; flagship model for coding, agentic tasks, and reasoning.
- `grok-composer-2.5-fast`: Composer 2.5 model available through Grok Build.

Prefer checking the installed CLI before relying on a model id:

```bash
grok models
grok --help
```

Run Grok 4.5 in headless deep mode:

```bash
grok -m grok-4.5 --effort high -p "Deeply analyze this repo and identify the highest-risk bugs."
```

Run Composer 2.5 in headless deep mode:

```bash
grok -m grok-composer-2.5-fast --effort high -p "Implement the requested change, then run focused verification."
```

`--effort <LEVEL>` is the documented CLI flag for reasoning effort; the installed binary also accepts `--reasoning-effort <EFFORT>` with alias `--effort`. Prefer `--effort high` for "deep" unless the user asks for lower cost or latency.

## Output Formats

Use `--output-format` for automation:

- `plain`: readable final answer; default.
- `json`: one JSON object at the end.
- `streaming-json`: newline-delimited JSON events while the run progresses.

Examples:

```bash
grok -p "Return a risk list for this codebase" --output-format plain
grok -p "Return a JSON summary of failing tests" --output-format json
grok -p "Explain the architecture" --output-format streaming-json
```

For constrained JSON with the installed CLI, use `--json-schema <SCHEMA>`. It implies `--output-format json`.

```bash
grok -p "Classify this repo" --json-schema '{"type":"object","properties":{"language":{"type":"string"},"risk":{"type":"string"}},"required":["language","risk"]}'
```

## Session Control

Headless sessions are stored under `~/.grok/sessions`.

Use a new named session id when repeatability matters:

```bash
grok -s 00000000-0000-4000-8000-000000000001 -p "Start a repo audit"
```

Resume or continue:

```bash
grok -r <session-id> -p "Continue from the last findings and propose fixes"
grok -c -p "Continue the most recent session in this directory"
```

When resuming, use `--fork-session` to branch instead of mutating the original session. Pair it with `--session-id <UUID>` to name the fork.

## Permissions And Tools

Default permission behavior may ask before tool calls. For automation where tool execution is expected and approved, use:

```bash
grok --always-approve -p "Run tests, fix failures, and summarize changes"
```

`--always-approve` is also accepted as `--yolo` per docs, but prefer the explicit name in scripts. The installed binary also exposes `--permission-mode <MODE>` with possible values:

- `default`
- `acceptEdits`
- `auto`
- `dontAsk`
- `bypassPermissions`
- `plan`

Constrain tools when needed:

```bash
grok -p "Inspect only; do not edit" --tools read,grep --disallowed-tools write,bash
grok -p "Run a safe audit" --allow "read:*" --deny "write:*"
```

Use `--sandbox <PROFILE>` when the environment has Grok sandbox profiles configured. Use `--disable-web-search` when the task must avoid web access.

## Prompt Inputs

Choose the prompt source based on size and structure:

```bash
grok -p "Short prompt"
grok --prompt-file prompt.md
grok --prompt-json '[{"type":"text","text":"Analyze this."}]'
```

Use `--verbatim` when the prompt must be passed exactly as given. Use `--rules <TEXT>` to append extra instructions, or `--system-prompt-override <TEXT>` only when the user explicitly asks to replace the agent system prompt.

## Worktrees

For implementation tasks that should not touch the current checkout, start in a Grok-managed worktree:

```bash
grok -w feature-audit --ref main -m grok-4.5 --effort high -p "Implement the change and run tests"
```

Use `grok worktree <list|show|rm|gc>` to inspect or clean Grok worktrees.

## Recommended Patterns

For read-only analysis:

```bash
grok -m grok-4.5 --effort high --disable-web-search -p "Analyze this repository for correctness bugs. Do not edit files."
```

For implementation:

```bash
grok -m grok-composer-2.5-fast --effort high --always-approve --check -p "Implement the requested change, run focused tests, and summarize changed files."
```

For CI or machine parsing:

```bash
grok --no-auto-update -m grok-4.5 --effort high -p "Review this diff and return JSON findings" --output-format json
```

After running Grok for code changes, inspect the diff and run relevant verification before reporting completion.

## Local Flag Reference

When exact flag availability matters, prefer the installed binary over this static reference:

```bash
grok --help
grok inspect --json
```

The local CLI used to author this skill included these top-level options:

- `[PROMPT]`: initial prompt for an interactive session when not using headless mode.
- `--agent <NAME>`: agent name or definition file path.
- `--agents <JSON>`: inline subagent definitions as JSON.
- `--allow <RULE>`: permission allow rule.
- `--always-approve`: auto-approve tool executions.
- `--best-of-n <N>`: run headless task N ways in parallel and pick the best.
- `-c, --continue`: continue the most recent session for the current working directory.
- `--check`: append a self-verification loop to the prompt in headless mode.
- `--cwd <CWD>`: working directory.
- `--debug`: enable debug logging.
- `--deny <RULE>`: permission deny rule.
- `--disable-web-search`: disable web search and fetch tools.
- `--disallowed-tools <TOOLS>`: remove built-in tools, comma-separated.
- `--fork-session`: fork when resuming or continuing.
- `-m, --model <MODEL>`: model id to use.
- `--no-auto-update`: skip background update checks in scripts, CI, and ACP.
- `--output-format <plain|json|streaming-json>`: headless output format.
- `-p, --single <PROMPT>`: single-turn headless prompt.
- `--permission-mode <MODE>`: permission mode.
- `--prompt-file <PATH>`: single-turn prompt from a file.
- `--prompt-json <JSON>`: single-turn prompt as JSON content blocks.
- `-r, --resume [<SESSION_ID>]`: resume a session by id, or most recent if omitted.
- `--reasoning-effort <EFFORT>` / `--effort <EFFORT>`: reasoning effort.
- `-s, --session-id <SESSION_ID>`: specific UUID for a new conversation, or a fork id with `--fork-session`.
- `--sandbox <PROFILE>`: sandbox profile; also reads `GROK_SANDBOX`.
- `--tools <TOOLS>`: built-in tools to allow, comma-separated.
- `-w, --worktree [<WORKTREE>]`: start in a new git worktree.
- `--worktree-ref <REF>` / `--ref <REF>`: branch, tag, or commit for the worktree base.

Useful subcommands include `grok agent stdio`, `grok completions`, `grok dashboard`, `grok export`, `grok import`, `grok inspect`, `grok login`, `grok mcp`, `grok models`, `grok plugin`, `grok sessions`, `grok setup`, `grok update`, `grok version`, `grok worktree`, and `grok wrap`.
