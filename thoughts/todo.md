# Plan: Add hypt:post-mortem Skill

## Goal

Add a new `hypt:post-mortem` skill that runs automatically after `/restore` completes. It analyzes recent changes to `main` to identify what went wrong, creates a post-mortem document, updates backlog/todos with findings, and suggests the user start a new session to fix the issue.

## Design Decisions

1. **Skill, not command** — lives in `plugin/skills/post-mortem/SKILL.md`, invoked as `hypt:post-mortem`
2. **Auto-triggered by restore** — Step 8 added to `plugin/commands/restore.md` after the report
3. **Post-mortem doc format** — `docs/post-mortem/YYYY-MM-DD-<topic>-post-mortem.md`
4. **Date naming convention** — Add to docs skill so it recognizes this pattern
5. **Non-coder friendly** — output in plain language, no jargon
6. **Updates backlog** — adds findings to `docs/todos/backlog.md` under Bugs section
7. **Suggests next steps** — tells user to start new session with `/fix`, `/go`, or `/yolo`

## Tasks

- [x] 1. Create `plugin/skills/post-mortem/SKILL.md` with full skill implementation
- [x] 2. Add Step 8 to `plugin/commands/restore.md` to invoke post-mortem after restore
- [x] 3. Update `plugin/skills/docs/SKILL.md` to document YYYY-MM-DD-<topic>.md naming convention
- [x] 4. Add post-mortem routing to `plugin/skills/hypt/SKILL.md` router
- [x] 5. Add post-mortem to root `README.md` command table
- [x] 6. Add post-mortem to `plugin/README.md` skills table
- [x] 7. Add post-mortem integration test item to `docs/todos/backlog.md`
