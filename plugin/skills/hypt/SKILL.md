---
name: hypt
description: >
  Hyptrain shipping workflow orchestrator. Routes user requests to the appropriate
  hypt skill. Use when the user says "start", "new project", "get started",
  "I have an idea", "save", "commit", "push", "review", "review my work",
  "check my diff", "check this for me", "look at what I built", "is this ready",
  "did I do this right", "check for problems", "look this over",
  "touchup", "polish", "tests", "unit tests", "close", "merge", "ship it",
  "done", "deploy", "status", "is my site up", "is it live",
  "restore", "rollback", "revert", "go back", "undo deploy", "previous version",
  "it's broken revert", "undo last deploy", "restore database", "restore data",
  "prototype", "build this feature",
  "implement this plan", "review plan", "critique plan", "check my plan",
  "yolo", "yolo it", "just ship it", "take it all the way",
  "go", "go mode", "ship with confirmation", "auto but confirm",
  "run pipeline", "review and test", "get this PR-ready",
  "autoclose", "auto merge", "merge without asking",
  "set up CI", "add CI", "fix", "bug", "broken", "not working",
  "something's wrong", "error", "crash", "issue", "debug",
  "suggestions", "backlog", "what should I work on next", "what's next",
  "change backlog preference", "update docs", "refresh docs", "check docs",
  "documentation", or "scan docs".
allowed-tools: "Skill"
version: "1.0.0"
author: "Brian Miller"
license: "MIT"
compatible-with: claude-code
tags: [shipping, workflow, deploy, review, testing, prototype]
---

# HYPT — Hyptrain Shipping Workflow

Complete shipping workflow for Claude Code. Routes user intent to the right skill automatically.

## Preamble (run silently before routing)

```bash
_UPD=$(~/.claude/plugins/marketplaces/hypt-claude/bin/hypt-update-check 2>/dev/null || true)
echo "${_UPD:-UP_TO_DATE}"
```

- If output contains `UPGRADE_AVAILABLE <old> <new>`: Silently run `bash ~/.claude/plugins/marketplaces/hypt-claude/install.sh` then briefly tell the user: "hypt updated to v{new}. Restart Claude Code when convenient to use the latest version." Then continue with routing normally.
- If output contains `JUST_UPGRADED <old> <new>`: Briefly say "Running hypt v{new} (updated from v{old})." then continue.
- Otherwise: continue silently — say nothing about updates.

## Routing Rules

When the user's request matches a shipping workflow action, invoke the appropriate hypt skill using the Skill tool as your FIRST action. Do NOT answer directly, do NOT use other tools first.

| User says | Invoke |
|-----------|--------|
| "Start", new project, get started, set up, onboarding, "I have an idea" | `hypt:start` |
| "Save", commit, push, create PR | `hypt:save` |
| Thorough code review, check my diff, review my work, check this for me, look at what I built, is this ready, did I do this right, check for problems, look this over | `hypt:review` |
| Quick polish, touchup, pre-merge check, fix PR comments | `hypt:touchup` |
| Unit tests, add tests, test coverage, write tests | `hypt:unit-tests` |
| Close, merge, ship it, "done", "we're good" | `hypt:close` |
| "Suggestions", "what should I work on next", "backlog", "next tasks", "what's next", "change backlog preference" | `hypt:suggestions` |
| Deploy, check deployment, fix deployment | `hypt:deploy` |
| "Status", is it live, is my site up, site status, check my site | `hypt:status` |
| "Restore", rollback, revert, go back, undo deploy, previous version, undo last deploy, restore database | `hypt:restore` |
| Review plan, critique plan, check my plan, plan review, plan critic | `hypt:plan-critic` |
| Prototype, build this feature, implement this plan | `hypt:prototype` |
| "Fix", bug, broken, not working, something's wrong, error, crash, issue, debug | `hypt:fix` |
| "Yolo", "yolo it", "just ship it", "take it all the way", full auto ship | `hypt:yolo` |
| "Go", "go mode", "ship with confirmation", "auto but confirm", "do everything but ask before merge" | `hypt:go` |
| "Run pipeline", "review and test", "get this PR-ready" | `hypt:pipeline` |
| "Autoclose", "auto merge", "merge without asking" | `hypt:autoclose` |
| "Update docs", "refresh docs", "check docs", "documentation", "scan docs" | `hypt:docs` |
| Set up CI, add CI, automatic testing, ci setup | `hypt:ci-setup` |

## Workflow

The typical flow is:

0. `hypt:start` — onboarding: describe your idea, set up accounts, create a plan
1. `hypt:ci-setup` — set up automatic lint + test CI (optional, runs at end of start)
2. `hypt:prototype` — review plan, implement, review, test, and deliver
3. `hypt:fix` — diagnose and fix bugs (triage, research, plan, test, deliver)
4. `hypt:save` — commit, push, create PR
5. `hypt:review` — thorough code review with parallel subagents
6. `hypt:touchup` — quick polish pass
7. `hypt:unit-tests` — add tests for PR changes
8. `hypt:status` — quick read-only deployment status check
9. `hypt:deploy` — verify deployment is healthy, fix trivial issues
10. `hypt:restore` — restore to a previous working version (rollback deployments, revert code, database recovery guidance)
11. `hypt:docs` — scan and update project documentation (runs automatically in pipeline and close)
12. `hypt:suggestions` — suggest next tasks and update project backlog (runs automatically in close)
13. `hypt:close` — merge PR and wrap up (asks for confirmation before merge)

Skills can be used individually or as part of the full prototype workflow.

### Composition skills

- `hypt:pipeline` — full development pipeline (research → plan → build → review → test → save PR). Does not merge.
- `hypt:autoclose` — autonomous close (merge, deploy check, version bump, release) without confirmation. Used internally by /yolo and /go.

### Shortcuts

- `hypt:go` = `hypt:pipeline` + confirmation gate + `hypt:autoclose` — autonomous pipeline, confirms before merge
- `hypt:yolo` = `hypt:pipeline` + `hypt:autoclose` — fully autonomous, no confirmation at any step
