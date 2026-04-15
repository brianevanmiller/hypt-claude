<!-- Generated from plugin/skills and plugin/commands. Do not edit by hand. Run `node scripts/sync-codex-support.mjs` instead. -->
# AGENTS.md

## Codex Support

This repo exposes repo-local Codex skills under `.codex/skills/`. Use them automatically when the user asks for the matching workflow, and prefer the router skill `hypt` only when the request is broad enough that the correct workflow still needs to be chosen.

## Available Skills

- hypt: Hyptrain shipping workflow orchestrator. Routes user requests to the appropriate hypt skill. Use when the user says "start", "new project", "get started", "I have an idea", "save", "commit", "push", "review", "review my work", "check my diff", "check this for me", "look at what I built", "is this ready", "did I do this right", "check for problems", "look this over", "touchup", "polish", "tests", "unit tests", "close", "merge", "ship it", "done", "deploy", "status", "is my site up", "is it live", "restore", "rollback", "revert", "go back", "undo deploy", "previous version", "it's broken revert", "undo last deploy", "restore database", "restore data", "prototype", "build this feature", "implement this plan", "review plan", "critique plan", "check my plan", "yolo", "yolo it", "just ship it", "take it all the way", "go", "go mode", "ship with confirmation", "auto but confirm", "run pipeline", "review and test", "get this PR-ready", "autoclose", "auto merge", "merge without asking", "set up CI", "add CI", "fix", "bug", "broken", "not working", "something's wrong", "error", "crash", "issue", "debug", "suggestions", "backlog", "what should I work on next", "what's next", "change backlog preference", "update docs", "refresh docs", "check docs", "documentation", or "scan docs". Use when the user asks for a general shipping workflow, `/hypt`, or a vague request that should be routed to the right hypt workflow, including `/hypt`, `hypt`. (aliases: `/hypt`, `hypt`; file: `.codex/skills/hypt/SKILL.md`)
- hypt-start: Onboarding for new projects — understand your idea, set up accounts, and create a build plan. Use when the user wants project onboarding, setup help, or an implementation plan for a new app idea, including `/start`, `hypt:start`. (aliases: `/start`, `hypt:start`; file: `.codex/skills/hypt-start/SKILL.md`)
- hypt-prototype: End-to-end prototype: implement plan, review, test, and deliver a working build. Use when the user wants a plan implemented into a working prototype end to end, including `/prototype`, `hypt:prototype`. (aliases: `/prototype`, `hypt:prototype`; file: `.codex/skills/hypt-prototype/SKILL.md`)
- hypt-save: Save all changes — commit, push, and create/update PR automatically. Use when the user wants to commit, push, or create or update a PR, including `/save`, `hypt:save`. (aliases: `/save`, `hypt:save`; file: `.codex/skills/hypt-save/SKILL.md`)
- hypt-review: Thorough PR review with parallel subagents — auto-fixes urgent issues. Use when the user wants a PR review, diff review, or readiness check, including `/review`, `hypt:review`. (aliases: `/review`, `hypt:review`; file: `.codex/skills/hypt-review/SKILL.md`)
- hypt-touchup: Quick pre-merge polish — fix PR comments, build issues, and update docs. Use when the user wants quick polish before merge, including PR feedback, docs, and build fixes, including `/touchup`, `hypt:touchup`. (aliases: `/touchup`, `hypt:touchup`; file: `.codex/skills/hypt-touchup/SKILL.md`)
- hypt-unit-tests: Create or extend unit tests for PR changes — lean by default, thorough for critical paths. Use when the user wants tests added or extended for the current PR, including `/unit-tests`, `hypt:unit-tests`. (aliases: `/unit-tests`, `hypt:unit-tests`; file: `.codex/skills/hypt-unit-tests/SKILL.md`)
- hypt-fix: Diagnose and fix bugs — triage, research, plan, and deliver a tested fix. Use when the user wants a bug diagnosed and fixed, including `/fix`, `hypt:fix`. (aliases: `/fix`, `hypt:fix`; file: `.codex/skills/hypt-fix/SKILL.md`)
- hypt-deploy: Verify deployment is healthy — detect platform, check status, fix trivial issues. Use when the user wants deployment verification or minor deploy issue handling, including `/deploy`, `hypt:deploy`. (aliases: `/deploy`, `hypt:deploy`; file: `.codex/skills/hypt-deploy/SKILL.md`)
- hypt-status: Quick deployment status check — is my site up? Read-only, no fixes attempted. Use when the user wants a read-only deployment status check, including `/status`, `hypt:status`. (aliases: `/status`, `hypt:status`; file: `.codex/skills/hypt-status/SKILL.md`)
- hypt-restore: Restore app to a previous working version — rollback deployments, revert code, guide database recovery. Use when the user wants to rollback, revert, or restore the app to a previous working version, including `/restore`, `hypt:restore`. (aliases: `/restore`, `hypt:restore`; file: `.codex/skills/hypt-restore/SKILL.md`)
- hypt-docs: Scan and update project documentation — check off completed items, update README tables, feature docs, dates, and references. Used by /pipeline and /close, or standalone via "update docs". Use when the user wants to scan and update project documentation, including checklists, READMEs, feature docs, and dates, including `/docs`, `hypt:docs`. (aliases: `/docs`, `hypt:docs`; file: `.codex/skills/hypt-docs/SKILL.md`)
- hypt-close: Check off completed items, suggest next tasks, update backlog, confirm before merge, verify deployment, and release. Use when the user wants to wrap up a PR, confirm merge readiness, verify deployment, and release, including `/close`, `hypt:close`. (aliases: `/close`, `hypt:close`; file: `.codex/skills/hypt-close/SKILL.md`)
- hypt-suggestions: Suggest next tasks and track them in your project backlog. Use when the user wants next-task suggestions or backlog updates, including `/suggestions`, `hypt:suggestions`. (aliases: `/suggestions`, `hypt:suggestions`; file: `.codex/skills/hypt-suggestions/SKILL.md`)
- hypt-plan-critic: Dynamic plan review — adapts to task complexity, uses parallel subagents for larger plans. Use when the user wants a plan critiqued before implementation, including `/plan-critic`, `hypt:plan-critic`. (aliases: `/plan-critic`, `hypt:plan-critic`; file: `.codex/skills/hypt-plan-critic/SKILL.md`)
- hypt-go: Autonomous ship with final confirmation — research, plan, build, review, then ask before merging. Use when the user wants the full shipping pipeline with an explicit merge confirmation gate, including `/go`, `hypt:go`. (aliases: `/go`, `hypt:go`; file: `.codex/skills/hypt-go/SKILL.md`)
- hypt-yolo: Full autonomous ship — from idea or mid-PR all the way to merged, no hand-holding. Use when the user wants the full shipping pipeline to run autonomously through merge, including `/yolo`, `hypt:yolo`. (aliases: `/yolo`, `hypt:yolo`; file: `.codex/skills/hypt-yolo/SKILL.md`)
- hypt-pipeline: Full development pipeline — detect stage, research, plan, build, review, test, and save PR. Does NOT merge. Use when the user says "run pipeline", "review and test", or "get this PR-ready". Use when the user wants the full development pipeline run without merging, including `/pipeline`, `hypt:pipeline`. (aliases: `/pipeline`, `hypt:pipeline`; file: `.codex/skills/hypt-pipeline/SKILL.md`)
- hypt-autoclose: Autonomous close — merge PR, deploy check, version bump, and release without confirmation. Used by /yolo and /go after their own confirmation handling. Use when the user wants merge, deploy verification, version bump, and release without confirmation, including `/autoclose`, `hypt:autoclose`. (aliases: `/autoclose`, `hypt:autoclose`; file: `.codex/skills/hypt-autoclose/SKILL.md`)
- hypt-ci-setup: Set up lightweight CI — runs unit tests automatically on every commit via GitHub Actions. Use when the user wants lightweight CI added for linting and unit tests, including `/ci-setup`, `hypt:ci-setup`. (aliases: `/ci-setup`, `hypt:ci-setup`; file: `.codex/skills/hypt-ci-setup/SKILL.md`)

## Trigger Rules

- Use `hypt` for vague shipping workflow requests, `/hypt`, or when the user wants hypt to route them to the right workflow.
- Use the specific `hypt-*` skill when the user explicitly names a workflow, uses a legacy Claude alias, or clearly describes that workflow.
- Treat legacy Claude aliases as synonyms for the generated Codex skills.

## Legacy Alias Map

- `/hypt` -> `hypt`
- `hypt` -> `hypt`
- `/start` -> `hypt-start`
- `hypt:start` -> `hypt-start`
- `/prototype` -> `hypt-prototype`
- `hypt:prototype` -> `hypt-prototype`
- `/save` -> `hypt-save`
- `hypt:save` -> `hypt-save`
- `/review` -> `hypt-review`
- `hypt:review` -> `hypt-review`
- `/touchup` -> `hypt-touchup`
- `hypt:touchup` -> `hypt-touchup`
- `/unit-tests` -> `hypt-unit-tests`
- `hypt:unit-tests` -> `hypt-unit-tests`
- `/fix` -> `hypt-fix`
- `hypt:fix` -> `hypt-fix`
- `/deploy` -> `hypt-deploy`
- `hypt:deploy` -> `hypt-deploy`
- `/status` -> `hypt-status`
- `hypt:status` -> `hypt-status`
- `/restore` -> `hypt-restore`
- `hypt:restore` -> `hypt-restore`
- `/docs` -> `hypt-docs`
- `hypt:docs` -> `hypt-docs`
- `/close` -> `hypt-close`
- `hypt:close` -> `hypt-close`
- `/suggestions` -> `hypt-suggestions`
- `hypt:suggestions` -> `hypt-suggestions`
- `/plan-critic` -> `hypt-plan-critic`
- `hypt:plan-critic` -> `hypt-plan-critic`
- `/go` -> `hypt-go`
- `hypt:go` -> `hypt-go`
- `/yolo` -> `hypt-yolo`
- `hypt:yolo` -> `hypt-yolo`
- `/pipeline` -> `hypt-pipeline`
- `hypt:pipeline` -> `hypt-pipeline`
- `/autoclose` -> `hypt-autoclose`
- `hypt:autoclose` -> `hypt-autoclose`
- `/ci-setup` -> `hypt-ci-setup`
- `hypt:ci-setup` -> `hypt-ci-setup`
