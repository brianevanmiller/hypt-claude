---
description: "Diagnose and fix bugs — triage, research, plan, and deliver a tested fix"
allowed-tools: ["Bash", "Read", "Edit", "Write", "Grep", "Glob", "Agent", "Skill"]
---

# /fix — Diagnose and Fix Bugs

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
- PR status: !`gh pr view --json number,url 2>/dev/null || echo "No PR yet"`
- Build status: !`bun run build 2>&1 | tail -5 || echo "No build script"`
- Test status: !`bun test 2>&1 | tail -5 || echo "No test script"`
- Recent commits: !`git log --oneline -5`

## Instructions

This skill diagnoses bugs and delivers tested fixes. It handles everything from simple one-liner fixes to complex multi-file bugs that need planning and regression tests.

Works for both technical users ("null pointer in auth middleware at line 42") and non-technical users ("my app shows a blank page when I click login").

---

### Step 0: Understand the bug

If the user has already described the bug clearly, restate it in technical terms and ask them to confirm:

> **Understanding:** [technical restatement of the bug]. Is that right?

If the description is vague or unclear, ask:

> Can you tell me more about what's going wrong? For example:
> - What were you doing when it happened?
> - What did you expect to happen vs what actually happened?
> - Did it work before? If so, when did it stop?
> - Any error messages you can share?

Wait for confirmation before proceeding.

---

### Step 1: Triage — research the codebase

Launch 2-3 Agent calls **in parallel** (single message, multiple tool calls) to investigate the bug.

**Agent 1 — Error trace:**
> You are investigating a bug report. The bug is: [bug description].
>
> Your job is to find evidence of the error:
> - Run the build: `bun run build 2>&1` — look for related errors
> - Run tests: `bun test 2>&1` — look for failing tests
> - Search for error messages or related strings in the codebase using Grep
> - Check recent commits that might have introduced the bug: `git log --oneline -20`
> - If the bug mentions a specific page/route/endpoint, find the file that handles it
>
> Report: what errors you found, which files are involved, and any recent commits that look related.

**Agent 2 — Code investigation:**
> You are investigating the root cause of a bug. The bug is: [bug description].
>
> Your job is to trace the code path and find the root cause:
> - Find the files most likely involved (use Grep and Glob)
> - Read those files and trace the data/control flow
> - Identify where the behavior deviates from what's expected
> - Look for: null/undefined access, wrong conditionals, missing error handling, race conditions, stale state, type mismatches
>
> Report: the root cause (or your best hypothesis), the specific file(s) and line(s) involved, and what the fix should be.

**Agent 3 — Context gathering (only if the bug is vague or involves complex interactions):**
> You are gathering context about a bug. The bug is: [bug description].
>
> Your job is to find background context:
> - Search docs/ for any relevant documentation or design decisions
> - Check `git log --all --oneline -- <affected files>` for history on the affected files
> - Look for related GitHub issues or PR discussions: `gh issue list --search "<keywords>" 2>/dev/null`
> - Check if similar bugs have been fixed before: `git log --all --oneline --grep="fix" --grep="<keywords>" --all-match`
>
> Report: any relevant context that helps understand why the bug exists and what to watch out for when fixing it.

Skip Agent 3 if the bug is clearly described and the first two agents should be sufficient.

---

### Step 2: Classify complexity

Based on agent findings, classify the bug as **simple** or **involved**.

**Simple** — all of these must be true:
- Root cause is identified with high confidence
- Fix touches ≤3 files
- Fix is a localized change (null check, typo, missing import, wrong comparison, off-by-one, missing await, wrong variable)
- No architectural or data model changes needed
- No new files need to be created

**Involved** — any of these is true:
- Root cause is unclear or uncertain
- Fix touches 4+ files
- Fix requires new code paths (error handling, validation, middleware)
- Fix involves database schema or migration changes
- Fix could affect multiple features (shared utility, auth, data layer)
- The bug is a symptom of a deeper design problem
- Meaningful regression risk exists

**Err on the side of "simple" for borderline cases.** The cost of over-planning a simple fix is higher than under-planning.

Present the classification to the user:

> **Bug identified:** [1-sentence root cause]
> **Affected files:** [list of files]
> **Classification:** Simple / Involved
>
> [For simple:] I'll fix this directly, verify it builds and passes tests, and save.
> [For involved:] This needs a systematic approach. I'll do deeper research, write a bugfix plan, create regression tests, and implement the fix with full review.

---

### Step 3a: Simple fix path

**1. Apply the fix:**
Read the affected files, then use the Edit tool to apply targeted fixes. Keep changes minimal — fix the bug, nothing else.

**2. Verify the fix:**

Run type checks (if TypeScript):
```bash
bunx tsc --noEmit 2>&1
```

Run the build:
```bash
bun run build 2>&1
```

Run existing tests:
```bash
bun test 2>&1
```

If any of these fail, fix the issues and re-verify.

**3. Save:**
Invoke the Skill tool with skill: "hypt:save"

This commits, pushes, and creates a PR.

**4. Present summary:**

```
Bug fixed!

## [Bug Title]
- **Root cause:** [1 sentence]
- **Fix:** [1 sentence describing the change]
- **Files changed:** [list]
- **PR:** [url]
- **Build:** passing
- **Tests:** passing

Verify the fix and say `/close` when you're ready to merge.
```

---

### Step 3b: Involved fix path

**1. Deep research:**

Launch 2-3 additional Agent calls to investigate edge cases and historical context:

**Agent — Edge case analysis:**
> Root cause of the bug is: [root cause from Step 1].
> Affected files: [list].
>
> Investigate edge cases:
> - What other inputs or states could trigger similar issues in the same code path?
> - Are there related code paths that might have the same underlying problem?
> - What are the boundary conditions for the fix?
> - Read the affected files and their callers/callees to understand the blast radius.
>
> Report: edge cases to test, related code that might need fixes, and any additional risk factors.

**Agent — Historical context:**
> The bug is in: [affected files].
>
> Investigate the history:
> - `git log --oneline -20 -- [affected files]` — recent changes
> - `git log --all --oneline --grep="fix" -- [affected files]` — previous fixes in these files
> - Read any related docs in docs/ directory
>
> Report: why the code looks the way it does, any previous fixes that were attempted, and any design constraints to respect.

**2. Write the bugfix plan:**

Create the directory if needed:
```bash
mkdir -p docs/bugfixes
```

Write a bugfix plan to `docs/bugfixes/YYYY-MM-DD-<bug-name>.md` using today's date and a kebab-case bug name:

```markdown
# Bugfix: <Bug Title>

## Bug Report

<What the user reported, in their words>

## Root Cause Analysis

<Technical explanation of why the bug happens. Reference specific files and line numbers.
Explain the chain of events that leads to the broken behavior.>

## Reproduction Steps

1. <Step to reproduce>
2. <Step to reproduce>
3. Expected: <what should happen>
   Actual: <what happens instead>

## Fix Approach

<Narrative explanation of what needs to change and why.>

### Changes

| File | Change | Reason |
|------|--------|--------|
| path/to/file.ts:NN | Description of change | Why this fixes the bug |

## Risk Assessment

- **Regression risk:** Low / Medium / High
- **Areas to watch:** <Related code paths that could be affected>
- **Edge cases to test:**
  - <Edge case 1>
  - <Edge case 2>

## Verification

- [ ] Bug scenario no longer reproduces
- [ ] Edge cases pass
- [ ] Existing tests still pass
- [ ] Build compiles cleanly
```

Commit the bugfix plan:
```bash
git add docs/bugfixes/ && git commit -m "docs: add bugfix plan for <bug-name>" && git push
```

**3. Create regression tests:**

Invoke the Skill tool with skill: "hypt:unit-tests"

Before invoking, state clearly in the conversation:

> This is a **bugfix**. The bug is: [description]. The bugfix plan is at `docs/bugfixes/YYYY-MM-DD-<bug-name>.md`.
> Write regression tests that:
> 1. Reproduce the original bug scenario (this test should FAIL right now — the fix hasn't been applied yet)
> 2. Confirm the fix works once applied
> 3. Cover edge cases from the Risk Assessment section
>
> Use the `describe('bugfix: <title>')` naming convention.

After unit-tests completes, some tests may be failing (the regression tests that reproduce the bug). That's expected and correct — they'll pass after the fix is applied.

**4. Implement via prototype:**

Invoke the Skill tool with skill: "hypt:prototype"

Before invoking, state clearly in the conversation:

> This is a **bugfix plan**, not a feature plan. The plan is at `docs/bugfixes/YYYY-MM-DD-<bug-name>.md`.
> Implement the fix described in the plan. This is bugfix mode — leaner workflow with regression-focused reviews.

Prototype will detect bugfix mode from the plan path and content, then run its leaner bugfix workflow (skip plan-critic, one review round, bugfix doc update instead of feature synopsis).

---

### Step 4: Final summary (involved path)

After prototype completes, it will present its own summary. Add:

```
The full bugfix documentation is at docs/bugfixes/<filename>.md

Verify the fix and say `/close` when you're ready to merge.
```
