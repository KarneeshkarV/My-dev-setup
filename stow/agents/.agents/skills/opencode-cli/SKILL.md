---
name: opencode-cli
description: Drive OpenCode CLI agents headlessly with `opencode run` — pick a model (DeepSeek V4 Flash/Pro by default, or any provider/model from `opencode models`), pick or define an agent, delegate to subagents, and check run status, sessions, tokens, and cost. Use when the user wants to hand a coding, review, or analysis task to OpenCode, run OpenCode in a script or CI, define a custom OpenCode agent, or inspect what an OpenCode run did and what it cost. Even to explore use opencode to explore the codebase
metadata:
  short-description: Run and inspect OpenCode agents
---

# OpenCode CLI

Use this skill to delegate work to OpenCode agents from the command line and to inspect what those runs did.

Verified against opencode **1.18.18** on this machine. Flag availability drifts between versions — when exactness matters, run `opencode run --help` instead of trusting this file.

## Headless Quick Start

`opencode run` is the non-interactive entrypoint: one prompt, printed result, exit.

```bash
opencode run "Explain this codebase"
opencode run -m deepseek/deepseek-v4-flash "List TODO comments"
```

Key flags:

- `-m, --model provider/model` — model id; omit to use the configured default.
- `--variant <low|high|max>` — provider-side reasoning effort. Use for "think harder".
- `--agent <name>` — which agent persona runs the task.
- `--format default|json` — `json` emits NDJSON events (see Checking Status).
- `--auto` — auto-approve every permission that is not explicitly denied. Required for
  unattended runs that write files or shell out. Treat as a real grant, not a convenience flag.
- `-c, --continue` / `-s, --session <id>` — resume; `--fork` branches instead of mutating.
- `--dir <path>` — run against a directory without `cd`.
- `-f, --file <path>` — attach files to the message.
- `--title <text>` — name the session so `opencode session list` stays readable.
- `--thinking` — show reasoning blocks.
- `--attach <url>` — send the run to an already-running `opencode serve` instead of spawning one.

Without `--auto`, a run that needs an unapproved tool blocks waiting for approval. In a script
that means a hang, not an error — always pair unattended runs with `--auto` or a timeout.

## Choosing a Model

List what is actually available and authenticated before assuming an id exists:

```bash
opencode models              # all ids, provider/model form
opencode models deepseek     # one provider
opencode providers list      # which providers have credentials
```

### DeepSeek V4 (the default pairing)

| Model | Id | Variants | Context | Usecase|
|---|---|---|---|---|
| Flash | `deepseek/deepseek-v4-flash` | `low`, `high`, `max` | 1M | Default use case  |
| Pro | `deepseek/deepseek-v4-pro` | `high`, `max` | 1M | Only when the task is big  |

Both the models do have vision so do not tell them visual verification , let them do the work then you check the output 
- **Flash** — the workhorse. Search, summarize, mechanical edits, test triage, high-volume or
  fan-out work. Cheap enough to run speculatively.
- **Pro** — roughly 3x the price. Use when the task is genuinely hard: multi-file refactors,
  root-cause debugging, design review, anything where a wrong answer costs more than the tokens.

The same ids exist under other routes (`opencode/…`, `opencode-go/…`, `openrouter/deepseek/…`)
with different billing. Prefer the plain `opencode-go/` ids unless the user has a reason otherwise.

Any other id from `opencode models` works identically — nothing in this skill is DeepSeek-specific.
Match the model to the job: cheap/fast for breadth, strong for depth, and let the user's stated
budget or provider preference override the default.
### Agents delegating to agents

A primary agent reaches `mode: subagent` agents through its `task` tool. Ask for it in the prompt:

```bash
opencode run --auto -m deepseek/deepseek-v4-flash \
  "Delegate to the 'scout' subagent: which python file defines the parser? Then report its answer."
```

This is the cheap fan-out pattern: a Pro-backed primary that plans and verifies, delegating
mechanical lookups to Flash-backed subagents. For coarse parallelism, just run several
`opencode run` processes against different `--dir` values and collect their JSON.

## Checking Status

### During a run

`--format json` streams newline-delimited events to stdout: `step_start`, `text`, `tool` events,
and a final `step_finish` carrying token counts and cost.

```bash
opencode run --format json -m deepseek/deepseek-v4-flash "..." \
  | tee run.ndjson \
  | jq -r 'select(.type=="text") | .part.text'

jq 'select(.type=="step_finish") | {tokens: .part.tokens, cost: .part.cost}' run.ndjson
```

For a background run, redirect to a file and tail it — the NDJSON is the progress indicator.

### After a run

```bash
opencode session list                        # id, title, last-updated
opencode export <sessionID> > session.json   # full transcript as JSON
opencode export <sessionID> --sanitize       # redact secrets before sharing
opencode session delete <sessionID>
```

### Usage and cost

```bash
opencode stats                          # all time
opencode stats --days 7 --models        # per-model breakdown
opencode stats --project ""             # current project only
opencode stats --tools 10               # top tools
```

### Live status over HTTP

For long-running or remote work, run a server and query it:

```bash
opencode serve --port 4096              # prints: listening on http://127.0.0.1:4096
opencode run --attach http://127.0.0.1:4096 -m deepseek/deepseek-v4-flash "..."
```

```bash
curl -s localhost:4096/api/health                      # {"healthy":true}
curl -s localhost:4096/api/session | jq '.data[]'      # sessions, cost, tokens, model
curl -s localhost:4096/api/session/active              # what is running now
curl -sN localhost:4096/event                          # SSE event stream
curl -X POST localhost:4096/session/<id>/abort         # stop a runaway session
```

Two API generations coexist: unprefixed routes (`/session`) return bare JSON, `/api/*` routes
wrap payloads in `{"data": …}`. Note that **single-object GETs** such as `/api/session/{id}` and
`/session/{id}/message` return a *type-shape summary* rather than values when the payload is
large — use `opencode export <sessionID>` when you need real transcript content.

`opencode serve` warns when `OPENCODE_SERVER_PASSWORD` is unset; set it (with
`-u/-p` on the client) for anything not bound to loopback.

## Recommended Patterns

Read-only analysis — no writes possible, cheap:

```bash
opencode run -m deepseek/deepseek-v4-flash --agent plan \
  "Analyze this repo for correctness bugs. Do not edit files."
```

Unattended implementation with a receipt:

```bash
opencode run --auto -m deepseek/deepseek-v4-pro --variant high --format json \
  --title "fix-auth-bug" "Implement the fix, run focused tests, summarize changed files." \
  > run.ndjson
git diff        # always inspect the diff yourself
```

Follow-up in the same context:

```bash
opencode run -c "Now add a regression test for that fix."
opencode run -s <sessionID> --fork "Try a different approach instead."
```

After any run that changed code, inspect `git diff` and run the project's own verification
before reporting the task done. The agent's summary is a claim, not evidence.

## Troubleshooting

- **Run hangs with no output** — a permission prompt is waiting. Add `--auto`, or wrap in `timeout`.
- **`--agent X` hangs** — X is `mode: subagent`; change to `mode: all`/`primary` or delegate via `task`.
- **Unknown model** — check `opencode models` and `opencode providers list` for credentials.
- **Noisy stderr in CI** — version-manager banners (e.g. mise) print to stderr; capture stdout only.
- **Environment questions** — `opencode debug info`, `opencode debug paths`, `opencode debug config`.

Sessions, logs, and auth live under `~/.local/share/opencode`; config under `~/.config/opencode`.

ALWAYS check on the agents work if it taking more than 5 or 10 minutes based on the size of the task.
