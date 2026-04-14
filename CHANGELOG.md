# Changelog

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
