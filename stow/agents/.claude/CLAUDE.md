always talk in ASD-STE100 simplified technical english and say only what needs to be said. report only the elements needed for me to make the right decisions, explained clearly
## Package Managers & Environment
- This system uses Arch Linux + Omarchy with pnpm preferred over npm. use the omarchy skill if you are doing anything  Check package.json and lockfiles before assuming a package manager. and use uv instead of normal pythong
- Use bun if node is not working

## General Guidelines

- Never use the em dash "—". Use plain dash "-" instead.
- When writing commit messages, NEVER auto-add your agent name as co-author.
- Never manually modify `CHANGELOG.md` files or any files that are marked as auto-generated.
- When writing or substantially editing long Markdown files, put each full sentence on its own line.
  - Preserve normal Markdown structure, but avoid wrapping multiple sentences onto one physical line.
- When making technical decisions, do not give much weight to development cost.
  - Instead, prefer quality, simplicity, robustness, scalability, and long-term maintainability.
- When doing bug fixes, always start with reproducing the bug in an E2E setting as closely aligned with how an end user would experience it.
  - This makes sure you find the real problem so your fix will actually solve it.
- When end-to-end testing a product, be picky about the UI you see and be obsessed with pixel perfection.
  - If something clearly looks off, even if it is not directly related to what you are doing, try to get it fixed along the way.
- Apply that same high standard to engineering excellence: lint, test failures, and test flakiness.
  - If you see one, even if it is not caused by what you are working on right now, still get it fixed.


## pnpm policy (supply-chain hardening — MANDATORY)
- ALWAYS configure `minimumReleaseAge` = **2 weeks (1209600 seconds / "14d")** before running any `pnpm install`/`pnpm add`. This blocks installing package versions younger than 14 days, which is the primary defense against fresh-publish supply-chain attacks
- Never run `npx <pkg>` for unfamiliar packages — npx bypasses release-age 
# surgical changes
don't touch code unrelated to the request.
every changed line must trace back to what was asked.
# goal-driven execution
turn vague instructions into verifiable success criteria
before writing a single line.
# think before coding
state your assumptions. ask when unsure. 

## Sub-agents / Parallel Work 
When spawning sub-agents for review or audits, require each agent to print its findings to a file or back to the main thread before finishing; do not rely on in-agent state , and always try to parallelize work
