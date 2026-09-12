always talk in ASD-STE100 simplified technical english and say only what needs to be said. report only the elements needed for me to make the right decisions, explained clearly
Handle the task and verification yourself by default. Do not spawn subagents except for necessary independent reviews or when I explicitly ask you to.
## Package Managers & Environment
- This system is Arch Linux + Omarchy. Use the omarchy skill for desktop, Hyprland, waybar, walker, terminal, or theme config work.
- Check package.json and lockfiles before assuming a package manager. Use uv for Python, not pip or venv.
- JavaScript/TypeScript installs use pnpm. Bun is a fallback only when pnpm cannot be made to work; say why before you switch.

## General Guidelines

- Never use the em dash character (U+2014). Use plain dash "-" instead.
- When writing commit messages, NEVER auto-add your agent name as co-author.
- Never manually modify `CHANGELOG.md` files or any files that are marked as auto-generated.
- When writing or substantially editing long Markdown files, put each full sentence on its own line.
  - Preserve normal Markdown structure, but avoid wrapping multiple sentences onto one physical line.
- When making technical decisions, do not give much weight to development cost.
  - Instead, prefer quality, simplicity, robustness, scalability, and long-term maintainability.
- For a non-trivial bug, reproduce it end to end first, the way a user would hit it.
  - This makes sure you find the real problem so your fix will actually solve it.
- When you test a UI end to end, hold it to a pixel-level standard.
- Report lint errors, test failures, and flaky tests you see, even when your change did not cause them.
  - Fix one in the same change when it blocks the task or the fix is small. Otherwise tell me and let me decide.

## Scope of changes

- Change only what the request needs. Every changed line must trace back to what was asked.
- Turn a vague instruction into success criteria you can verify, and tell me what they are.
- State the assumptions you made. Ask me only when a wrong assumption would make the work unsafe or useless.

## pnpm policy (supply-chain hardening - MANDATORY)
- ALWAYS install with `minimumReleaseAge` = 2 weeks (1209600 seconds / "14d"). This blocks package versions younger than 14 days and is the primary defense against fresh-publish supply-chain attacks (Shai-Hulud and similar worms).
  - Set it in project `.npmrc` as `minimum-release-age=20160` (minutes), or `package.json#pnpm.minimumReleaseAge` as `1209600` (seconds), or `~/.npmrc` as a backstop.
  - Respect an existing project value. If a repo pins less than 14d, flag it and propose raising it. Do not silently overwrite.
  - For one install that legitimately needs a fresher package, use a one-off `--minimum-release-age=0` on that command, name the package, and say why. Never disable the policy in committed config.
- Do not run `npx <pkg>` for arbitrary or unfamiliar packages. npx bypasses the release-age policy. Use `pnpm dlx <pkg>` or install the tool as a devDependency.
- If a supply-chain scanner has flagged this machine, assume every token that touched it (GitHub, npm, AI providers, cloud, CI/CD, deploy) is exposed. Rotate before further work on sensitive repos.

This machine is headless and I treat it like a remote VPS. When you start a dev server or web UI, expose it over Tailscale and give me the URL.
