# Changelog

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
