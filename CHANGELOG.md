# Changelog

## v0.19.0 — 2026-04-16

- Add `/restore` command — roll back to a previous working version when production breaks
- Platform-aware rollback: instant Vercel promotion, Netlify publish, Fly.io release, or universal git revert
- Database recovery guidance for Supabase (PITR, daily backups, selective table restore) and generic ORMs (Prisma, Drizzle, Knex)
- Auto-detects restore target from merge history, or accepts specific commit/PR/tag/time targets
- Health checks after restore with deployment polling, reassuring non-coder-friendly output

## v0.18.0 — 2026-04-16

- Dynamic plan-critic adapts review depth to task complexity — quick inline check for small tasks, 2 parallel subagents (research thoroughness + plan completeness) for larger tasks
- New autonomous pipeline mode for plan-critic — fully non-interactive, updates plan directly and returns control
- Generalized review checklists work for any plan type (features, bugfixes, refactors), not just new-app prototypes
- Pipeline Step 2A now calls plan-critic instead of weak self-review, and prototype passes original request for context

## v0.17.0 — 2026-04-16

- Add Codex CLI global install support — the installer auto-detects Claude Code and Codex CLI, installing adapted skill files to `~/.hypt/skills/` with a global instruction block in `~/.codex/instructions.md`
- New `hypt-codex-adapt` script transforms SKILL.md files for Codex (strips frontmatter, remaps paths, replaces tool references)
- Support Claude-only, Codex-only, and both-installed scenarios with idempotent installation

## v0.16.0 — 2026-04-15

- Add repo-native Codex support by generating `.codex/skills` and `AGENTS.md` from the Claude plugin sources
- Add deterministic Codex sync checks, safe generated-file handling, and CI enforcement for stale skill output
- Expand the security scanner to cover Codex instruction surfaces and record follow-up Codex/testing work in the backlog

## v0.15.0 — 2026-04-15

- Use `/save` skill consistently throughout `/pipeline` and `/prototype` — every checkpoint now rebases on main, writes proper commit messages, and updates the PR description
- Update README with all 17 commands, workflow composition diagram for `/go` and `/yolo`, and security scanner section

## v0.14.0 — 2026-04-15

- Add AI prompt security scanner for CI — detects prompt injection, invisible Unicode, shell injection, tool poisoning, and structural anomalies
- GitHub Actions workflow blocks PRs with CRITICAL/HIGH/MEDIUM findings and posts scan results as PR comments
- Self-contained bash scanner with 16 self-tests, zero external dependencies

## v0.13.0 — 2026-04-15

- Add `/go` command — autonomous pipeline with confirmation before merge
- Add `/yolo` command — fully autonomous pipeline + merge, no stopping
- Extract shared `hypt:pipeline` skill to eliminate duplication between /go and /yolo
- Split close into `hypt:close` (confirmation gate) and `hypt:autoclose` (autonomous)
- Move `/fix` to a first-class command
- `/close` now asks for confirmation before merging (safer default)

## v0.12.1 — 2026-04-14

- Fix bypass detection so non-authors of the latest commit can trigger the Vercel team access bypass

## v0.12.0 — 2026-04-14

- Add `/status` command — lightweight deployment status check for non-coder users
- Read-only: reports whether the site is up without switching branches, stashing, or attempting fixes
- Checks both production and preview deployments with health checks
- Points users to `/deploy` when issues are found

## v0.11.2 — 2026-04-14

- `/deploy` now restores stashed changes after the deploy check completes — returns you to your original branch and working tree

## v0.11.1 — 2026-04-14

- `/deploy` now stashes uncommitted changes instead of blocking — no more "run `/save` first" interruptions

## v0.11.0 — 2026-04-14

- Add `/suggestions` skill — analyzes your PR and suggests prioritized next tasks (security, bugs, features, etc.)
- `/close` now runs suggestions before merge and optionally tracks them in `docs/todos/backlog.md`
- Backlog preference system — choose "always update", "always ask", or "skip" via `hypt-config`

## v0.10.1 — 2026-04-14

- Add auto-update check to `/start` — now all skills check for hypt updates before running

## v0.10.0 — 2026-04-14

- `/start` is now idempotent — detects fully onboarded projects and exits early with next-step suggestions
- Partial-resume support — if the plan exists but setup is incomplete, skips idea questions and repairs only what's missing
- Install scripts and README now guide AI agents to run `/start` after installation

## v0.9.2 — 2026-04-14

- Add MIT license to the project

## v0.9.1 — 2026-04-14

- Add update-check preamble to `/deploy` and `/close` for consistency with all other skills
- Extract Vercel team access bypass into standalone `bin/hypt-vercel-bypass` script

## v0.9.0 — 2026-04-14

- `/deploy` now falls through to production when no PR exists — non-coder users can deploy latest `main` from any branch
- Ignores local uncommitted changes when checking production deployment status

## v0.8.0 — 2026-04-14

- Auto-bypass Vercel TEAM_ACCESS_REQUIRED in `/deploy` and `/close` — detects when Vercel blocks deployments on free plans and deploys via CLI with a temporary author swap on a detached HEAD
- Hardened bypass with dirty-tree checks, detached HEAD isolation, empty-variable guards, and fallback author chain

## v0.7.0 — 2026-04-14

- Auto-generate CHANGELOG.md as part of `/close` version bump

## v0.6.0 — 2026-04-14

- Auto-version-bump and GitHub release creation in `/close`
- Auto-create PR in `/close` if one doesn't exist yet

## v0.5.0 — 2026-04-14

- Add `/fix` skill for autonomous bug fixing
- Add `/ci-setup` skill for lightweight CI setup
- Restructure commands into skills architecture

## v0.4.0 — 2026-04-14

- Auto-update system with background session checks
- Non-coder review triggers for plan review skills

## v0.3.0 — 2026-04-13

- Add `/ci-setup` skill with `/start` and `/close` integration

## v0.2.0 — 2026-04-13

- Initial shipping workflow commands

## v0.1.0 — 2026-04-13

- Initial release
