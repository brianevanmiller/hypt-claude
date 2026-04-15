---
description: "Autonomous ship with final confirmation — research, plan, build, review, then ask before merging"
allowed-tools: ["Bash", "Read", "Edit", "Write", "Grep", "Glob", "Agent", "Skill"]
---

# /go — Ship It, But Confirm Before Merge

## Preamble (run silently before the skill)

```bash
_UPD=$(~/.claude/plugins/marketplaces/hypt-claude/bin/hypt-update-check 2>/dev/null || true)
echo "${_UPD:-UP_TO_DATE}"
```

- If output contains `UPGRADE_AVAILABLE <old> <new>`: Silently run `bash ~/.claude/plugins/marketplaces/hypt-claude/install.sh` then briefly tell the user: "hypt updated to v{new}. Restart Claude Code when convenient to use the latest version." Then continue with the skill normally.
- If output contains `JUST_UPGRADED <old> <new>`: Briefly say "Running hypt v{new} (updated from v{old})." then continue.
- Otherwise: continue silently — say nothing about updates.

## Context

- Branch: !`git branch --show-current`
- PR status: !`gh pr view --json number,title,url,state,mergeStateStatus,reviewDecision 2>/dev/null || echo "NO_PR"`

## Instructions

This is the autonomous shipping mode with a safety net. The full pipeline runs autonomously — research, plan, build, review, test — but you **always ask for explicit confirmation before merging**.

> Go mode engaged. Taking this through the full pipeline — will confirm before merge.

---

### Step 1: Run the pipeline

Invoke the Skill tool with skill: "hypt:pipeline"

This handles everything: stage detection, research, planning, building, review loop, and unit tests. It stops when the PR is reviewed, tested, and ready to merge.

---

### Step 2: Confirmation gate

Before merging, present a clear summary and ask for confirmation.

Gather the current state:
```bash
gh pr view --json number,title,url,state,additions,deletions,files
```

Present the user with:

> **Ready to merge.** Here's a summary of what's shipping:
>
> - **PR:** #{number} — {title}
> - **URL:** {url}
> - **Changes:** +{additions} / -{deletions} across {file_count} files
> - **Review status:** {clean / findings addressed}
> - **Tests:** {passing / skipped / N/A}
>
> **Merge and close?** (yes/no)

Wait for the user's explicit confirmation. Do NOT proceed until they confirm.

- If the user says **yes** (or equivalent: "go", "ship it", "merge", "lgtm", "do it"): proceed to Step 3.
- If the user says **no** (or asks for changes): address their feedback, then return to Step 1 to re-run the relevant pipeline stages and come back to Step 2 again.

---

### Step 3: Close and merge

Invoke the Skill tool with skill: "hypt:autoclose"

This handles: checking off completed doc items, suggesting next tasks, merging the PR, checking deployment, version bump, and release.

---

### Step 4: Done

After autoclose completes, simply confirm:

```
Go complete. Shipped and merged.
```

The autoclose skill already provides the detailed summary with PR, release, deployment links, etc. No need to repeat it.

---

## Handling blockers

Throughout this entire flow (except the merge gate), only stop and ask the user if you encounter:

- **Security vulnerabilities** — auth bypass, exposed secrets, SQL injection, XSS, etc. that genuinely put users at risk
- **Destructive data operations** — migrations that drop data, irreversible state changes
- **Ambiguous requirements** — the feature request is genuinely unclear and you'd be guessing wrong
- **Persistent build/test failures** — after 2 attempts to fix, the same failure keeps recurring

For everything else — lint warnings, minor style choices, which approach to take — make the call yourself and keep going.
