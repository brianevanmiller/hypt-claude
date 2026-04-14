---
name: hypt
description: >
  Hyptrain shipping workflow orchestrator. Routes user requests to the appropriate
  hypt skill. Use when the user says "start", "new project", "get started",
  "I have an idea", "save", "commit", "push", "review", "review my work",
  "check my diff", "check this for me", "look at what I built", "is this ready",
  "did I do this right", "check for problems", "look this over",
  "touchup", "polish", "tests", "unit tests", "close", "merge", "ship it",
  "done", "deploy", "is it live", "prototype", "build this feature",
  "implement this plan", "review plan", "critique plan", "check my plan",
  "set up CI", "add CI", "fix", "bug", "broken", "not working",
  "something's wrong", "error", "crash", "issue", or "debug".
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
| Deploy, check deployment, is it live | `hypt:deploy` |
| Review plan, critique plan, check my plan, plan review, plan critic | `hypt:plan-critic` |
| Prototype, build this feature, implement this plan | `hypt:prototype` |
| "Fix", bug, broken, not working, something's wrong, error, crash, issue, debug | `hypt:fix` |
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
8. `hypt:deploy` — verify deployment is healthy
9. `hypt:close` — merge PR and wrap up

Skills can be used individually or as part of the full prototype workflow.
