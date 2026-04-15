---
name: "hypt-yolo"
description: "Full autonomous ship — from idea or mid-PR all the way to merged, no hand-holding. Use when the user wants the full shipping pipeline to run autonomously through merge, including `/yolo`, `hypt:yolo`."
metadata:
  short-description: "Ship It All the Way, No Stopping"
---
<!-- Generated from plugin/commands/yolo.md. Do not edit by hand. Run `node scripts/sync-codex-support.mjs` instead. -->

# hypt-yolo — Ship It All the Way, No Stopping

## Context

Before starting, gather context by running:

- Run `git branch --show-current` to capture Branch.

- PR status: `gh pr view --json number,title,url,state,mergeStateStatus,reviewDecision 2>/dev/null || echo "NO_PR"`

## Instructions

This is the fully autonomous shipping mode. You take whatever the user gives you — an idea, a half-built feature, or a ready PR — and drive it all the way to merged on main. **Do not ask for permission or confirmation at any step.** Only stop if you hit a genuine security vulnerability or a blocking issue that truly requires human judgment.

> YOLO mode engaged. Taking this all the way to merged.

---

### Step 1: Run the pipeline

Use `$hypt-pipeline`

This handles everything: stage detection, research, planning, building, review loop, and unit tests. It stops when the PR is reviewed, tested, and ready to merge.

---

### Step 2: Close and merge

Use `$hypt-autoclose`

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
