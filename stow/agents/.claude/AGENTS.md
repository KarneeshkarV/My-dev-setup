# Global agent instructions

These rules apply to any AI coding agent operating on this machine (Claude Code, Codex, Opencode, etc.). Project-level `AGENTS.md` / `CLAUDE.md` may add to them but should not relax them.

## Package manager policy (supply-chain hardening — MANDATORY)

- ALWAYS use **pnpm** for JavaScript/TypeScript installs. Do not use npm or yarn unless a project's tooling makes pnpm impossible. Bun is a fallback only when pnpm cannot be made to work; explain the reason before switching.
- ALWAYS install with `minimumReleaseAge` = **2 weeks (1209600 seconds / "14d")**. This blocks installing package versions younger than 14 days and is the primary defense against fresh-publish supply-chain attacks (Shai-Hulud, Mini Shai-Hulud, and similar worm campaigns that rely on malicious versions reaching victims before the registry yanks them).
- Set it in this order of preference:
  1. Project `.npmrc` — `minimum-release-age=20160` (minutes).
  2. Project `package.json#pnpm.minimumReleaseAge` — `1209600` (seconds).
  3. User-global `~/.npmrc` as a backstop for unconfigured projects.
- Respect existing project values. If a repo pins a value `< 14d`, flag it to the user and propose raising — do not silently overwrite.
- If a single install legitimately needs a fresher package (security fix), use a one-off `--allow-new` / `--minimum-release-age=0` on that command, name the package, and explain why. Never disable the policy globally or in committed config.

## npx is restricted

- Do not run `npx <pkg>` for arbitrary or unfamiliar packages. npx bypasses release-age policy and was the primary delivery vector for the Mini Shai-Hulud worm.
- Prefer `pnpm dlx <pkg>` (honors `minimumReleaseAge`) or install the tool locally as a devDependency.
- The `~/.npm/_npx` cache should be considered untrusted; if you need to clear it, `rm -rf ~/.npm/_npx`.

## Python

- Use `uv` instead of plain `python -m pip` / `venv`.

## When this machine has been exposed

If a supply-chain scanner (`npx supply-chain-attack` or similar) has flagged this machine, assume tokens that touched it (GitHub, npm, AI providers, cloud, CI/CD, deploy) are exposed and rotate them before doing further work on sensitive repos.
