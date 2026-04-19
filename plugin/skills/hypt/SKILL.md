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
  "post-mortem", "postmortem", "incident report", "what went wrong",
  "prototype", "build this feature",
  "implement this plan", "review plan", "critique plan", "check my plan",
  "yolo", "yolo it", "just ship it", "take it all the way",
  "go", "go mode", "ship with confirmation", "auto but confirm",
  "run pipeline", "review and test", "get this PR-ready",
  "autoclose", "auto merge", "merge without asking",
  "set up CI", "add CI", "fix", "bug", "broken", "not working",
  "something's wrong", "error", "crash", "issue", "debug",
  "suggestions", "backlog", "what should I work on next", "what's next",
  "change backlog preference", "todo", "add todo", "add to backlog",
  "update backlog", "update roadmap", "add to my list", "track this",
  "add to the list", "new task", "add task",
  "update docs", "refresh docs", "check docs",
  "documentation", "scan docs", "test my site", "QA", "design review",
  "security check", "security audit", "office hours", "investigate",
  "root cause", "retro", "benchmark", "design system", "browse",
  "post-mortem", "postmortem", "incident report", "what went wrong".
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
_UPD=$(~/.claude/plugins/marketplaces/hypt-builder/bin/hypt-update-check 2>/dev/null || true)
echo "${_UPD:-UP_TO_DATE}"
GSTACK_AVAILABLE=$(test -f ~/.claude/skills/gstack/SKILL.md && echo "true" || echo "false")
echo "GSTACK: $GSTACK_AVAILABLE"
```

- If output contains `UPGRADE_AVAILABLE <old> <new>`: Silently run `bash ~/.claude/plugins/marketplaces/hypt-builder/install.sh` then briefly tell the user: "hypt updated to v{new}. Restart Claude Code when convenient to use the latest version." Then continue with routing normally.
- If output contains `JUST_UPGRADED <old> <new>`: Briefly say "Running hypt v{new} (updated from v{old})." then continue.
- Otherwise: continue silently — say nothing about updates.
- `GSTACK` line: note silently whether gstack is available. Do not mention this to the user.

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
| "Todo", "add todo", "add to backlog", "update backlog", "update roadmap", "add to my list", "track this", "add to the list", "new task", "add task" | `hypt:todo` |
| "Suggestions", "what should I work on next", "backlog", "next tasks", "what's next", "change backlog preference" | `hypt:suggestions` |
| Deploy, check deployment, fix deployment | `hypt:deploy` |
| "Status", is it live, is my site up, site status, check my site | `hypt:status` |
| "Restore", rollback, revert, go back, undo deploy, previous version, undo last deploy, restore database | `hypt:restore` |
| "Post-mortem", postmortem, incident report, what went wrong | `hypt:post-mortem` |
| Review plan, critique plan, check my plan, plan review, plan critic | `hypt:plan-critic` |
| Prototype, build this feature, implement this plan | `hypt:prototype` |
| "Fix", bug, broken, not working, something's wrong, error, crash, issue, debug | `hypt:fix` |
| "Yolo", "yolo it", "just ship it", "take it all the way", full auto ship | `hypt:yolo` |
| "Go", "go mode", "ship with confirmation", "auto but confirm", "do everything but ask before merge" | `hypt:go` |
| "Run pipeline", "review and test", "get this PR-ready" | `hypt:pipeline` |
| "Autoclose", "auto merge", "merge without asking" | `hypt:autoclose` |
| "Update docs", "refresh docs", "check docs", "documentation", "scan docs" | `hypt:docs` |
| Set up CI, add CI, automatic testing, ci setup | `hypt:ci-setup` |

### Extended routes (when gstack is available)

If `GSTACK` is `true`, also route these requests:

| User says | Invoke | Brief mention |
|-----------|--------|---------------|
| "test my site", "does it work", "QA", "test in browser" | Skill: `qa` | "Using gstack QA tools to test your app in a real browser..." |
| "design review", "make it prettier", "visual check", "how does it look" | Skill: `design-review` | "Using gstack design review to check visual quality..." |
| "security check", "is it secure", "security audit", "OWASP" | Skill: `cso` | "Using gstack security officer to run a security audit..." |
| "brainstorm deeper", "office hours", "rethink this", "is this the right product" | Skill: `office-hours` | "Using gstack office hours for deeper product thinking..." |
| "investigate", "root cause", "dig deeper into this bug" | Skill: `investigate` | "Using gstack investigate for systematic root-cause analysis..." |
| "retro", "weekly review", "how did the week go" | Skill: `retro` | "Using gstack retro for your weekly engineering retrospective..." |
| "benchmark", "performance check", "how fast is my site" | Skill: `benchmark` | "Using gstack benchmark to measure your app's performance..." |
| "design system", "brand", "build a design" | Skill: `design-consultation` | "Using gstack design consultation to build your design system..." |
| "show me design options", "design variants" | Skill: `design-shotgun` | "Using gstack to generate design variants..." |
| "open browser", "browse", "open my site" | Skill: `browse` | "Opening your app in a browser..." |

If `GSTACK` is `false` and the user asks for any of the above capabilities:

> "That feature works best with gstack — a free companion tool that adds visual QA, design review, and security audits to your workflow. I can:
>
> A) Install gstack now (free, takes about 30 seconds)
> B) Skip it — [provide a manual alternative for the specific request, e.g., 'you can check the preview URL yourself']"

If the user chooses A, run:
```bash
git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup
```
Then set `GSTACK_AVAILABLE=true` and route to the appropriate gstack skill.

### Escalation rules (when gstack is available)

For **review** requests when `GSTACK` is `true`:
- If diff is ≤200 lines AND does not touch auth/payment/database code → invoke `hypt:review`
- If diff is >200 lines OR touches auth/payment/database → invoke Skill: `review` (gstack's deeper review). Say: "This is a larger change — using gstack's deep review with specialist modules..."

For **bug/fix** requests when `GSTACK` is `true`:
- If the user says "quick fix", "small bug", or the description is clearly simple → invoke `hypt:fix`
- If the user says "investigate", "root cause", or the bug sounds complex/unclear → invoke Skill: `investigate` (gstack). Say: "This needs deeper investigation — using gstack's systematic debugging..."
- If hypt:fix classifies a bug as "involved" (Step 2), it will delegate to gstack:investigate automatically

For **ship/save** requests (always use hypt regardless of gstack):
- "save", "commit", "push" → always `hypt:save` (incremental, non-coder friendly)
- "ship", "create PR" when no PR exists → `hypt:save` (creates PR)
- "ship" when PR already exists with all reviews done → `hypt:close`

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
10a. `hypt:post-mortem` — analyze what went wrong after a restore (runs automatically after /restore)
11. `hypt:docs` — scan and update project documentation (runs automatically in pipeline and close)
12. `hypt:todo` — add or update items in your project's tracking file (backlog, roadmap, todos)
13. `hypt:suggestions` — suggest next tasks, group related items, and offer /yolo or /go activation (runs automatically in close)
14. `hypt:close` — merge PR and wrap up (asks for confirmation before merge)

Skills can be used individually or as part of the full prototype workflow.

### Composition skills

- `hypt:pipeline` — full development pipeline (research → plan → build → review → test → save PR). Does not merge.
- `hypt:autoclose` — autonomous close (merge, deploy check, version bump, release) without confirmation. Used internally by /yolo and /go.

### Shortcuts

- `hypt:go` = `hypt:pipeline` + confirmation gate + `hypt:autoclose` — autonomous pipeline, confirms before merge
- `hypt:yolo` = `hypt:pipeline` + `hypt:autoclose` — fully autonomous, no confirmation at any step
