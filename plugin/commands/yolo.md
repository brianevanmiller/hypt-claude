---
description: "Full autonomous ship — from idea or mid-PR all the way to merged, no hand-holding"
allowed-tools: ["Bash", "Read", "Edit", "Write", "Grep", "Glob", "Agent", "Skill"]
---

# /yolo — Ship It All the Way, No Stopping

## Preamble (run silently before the skill)

```bash
_UPD=$(~/.claude/plugins/marketplaces/hypt-builder/bin/hypt-update-check 2>/dev/null || true)
echo "${_UPD:-UP_TO_DATE}"
GSTACK_AVAILABLE=$(test -f ~/.claude/skills/gstack/SKILL.md && echo "true" || echo "false")
echo "GSTACK: $GSTACK_AVAILABLE"
```

- If output contains `UPGRADE_AVAILABLE <old> <new>`: Silently run `bash ~/.claude/plugins/marketplaces/hypt-builder/install.sh` then briefly tell the user: "hypt updated to v{new}. Restart Claude Code when convenient to use the latest version." Then continue with the skill normally.
- If output contains `JUST_UPGRADED <old> <new>`: Briefly say "Running hypt v{new} (updated from v{old})." then continue.
- Otherwise: continue silently — say nothing about updates.
- `GSTACK` line: note silently whether gstack is available. Do not mention this to the user.

## Context

- Branch: !`git branch --show-current`
- PR status: !`gh pr view --json number,title,url,state,mergeStateStatus,reviewDecision 2>/dev/null || echo "NO_PR"`

## Instructions

This is the fully autonomous shipping mode. You take whatever the user gives you — an idea, a half-built feature, or a ready PR — and drive it all the way to merged on main. **Do not ask for permission or confirmation at any step.** Only stop if you hit a genuine security vulnerability or a blocking issue that truly requires human judgment.

> YOLO mode engaged. Taking this all the way to merged.

---

### Step 1: Run the pipeline

Invoke the Skill tool with skill: "hypt:pipeline"

This handles everything: stage detection, research, planning, building, review loop, and unit tests. It stops when the PR is reviewed, tested, and ready to merge.

---

### Step 2: Close and merge

Invoke the Skill tool with skill: "hypt:autoclose"

This handles: checking off completed doc items, suggesting next tasks, merging the PR, checking deployment, version bump, and release. No confirmation — straight to merge.

---

### Step 3: Done

After autoclose completes, simply confirm:

```
YOLO complete. Shipped and merged.
```

The autoclose skill already provides the detailed summary with PR, release, deployment links, etc. No need to repeat it.

---

## Handling blockers

Throughout this entire flow, only stop and ask the user if you encounter:

- **Security vulnerabilities** — auth bypass, exposed secrets, SQL injection, XSS, etc. that genuinely put users at risk
- **Destructive data operations** — migrations that drop data, irreversible state changes
- **Ambiguous requirements** — the feature request is genuinely unclear and you'd be guessing wrong
- **Persistent build/test failures** — after 2 attempts to fix, the same failure keeps recurring

For everything else — lint warnings, minor style choices, which approach to take — make the call yourself and keep going.
