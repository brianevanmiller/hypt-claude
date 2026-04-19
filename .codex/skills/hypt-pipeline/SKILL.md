---
name: "hypt-pipeline"
description: "Full development pipeline — detect stage, research, plan, build, review, test, and save PR. Does NOT merge. Use when the user says \"run pipeline\", \"review and test\", or \"get this PR-ready\". Use when the user wants the full development pipeline run without merging, including `/pipeline`, `hypt:pipeline`."
metadata:
  short-description: "Full Development Pipeline (No Merge)"
---
<!-- Generated from plugin/skills/pipeline/SKILL.md. Do not edit by hand. Run `node scripts/sync-codex-support.mjs` instead. -->

# hypt-pipeline — Full Development Pipeline (No Merge)

## Context

Before starting, gather context by running:

- Run `git branch --show-current` to capture Branch.

- PR status: `gh pr view --json number,title,url,state,mergeStateStatus,reviewDecision 2>/dev/null || echo "NO_PR"`
- Uncommitted changes: `git status --short 2>/dev/null`
- Recent commits on branch: `git log --oneline -10 2>/dev/null`
- Has unit tests: `find . -maxdepth 4 \( -name "*.test.*" -o -name "*.spec.*" -o -name "__tests__" -o -path "*/test/*" -o -path "*/tests/*" \) -not -path "./node_modules/*" -not -path "./.git/*" 2>/dev/null | head -5`
- Merge status vs main: `git log main..HEAD --oneline 2>/dev/null | wc -l | tr -d ' '`
- Plan files: `ls docs/*.md docs/**/*.md TODO.md TODOS.md docs/roadmap.md docs/todos/backlog.md 2>/dev/null | head -5`

## Instructions

This skill runs the full development pipeline — from whatever state the branch is in, all the way to a reviewed, tested PR that is ready to merge. It does **not** merge or close the PR. That is the caller's responsibility.

Use subagents liberally throughout — offload research, parallel analysis, and independent tasks to subagents to keep the main context clean and move fast. Auto-compact context whenever it gets long.

---

### Step 1: Detect current stage

Read the Context section above and determine which stage applies:

**Stage A — Starting from scratch (no PR, no meaningful commits on branch)**
The user provided a feature request, bug description, or idea. There's no PR and no implementation yet (or only a fresh branch with no real commits ahead of main).

**Stage B — Mid-implementation (commits exist, PR may or may not exist)**
There are commits on the branch with real code changes. A PR may or may not exist. Code hasn't been fully reviewed yet.

**Stage C — Review-ready (PR exists, code is implemented, needs review/merge)**
A PR exists and the implementation looks complete. Just needs review polish and merge.

**Stage D — Ready to merge (PR exists, reviews look clean, checks passing)**
The PR is in a mergeable state — reviews are done, checks are passing. Just needs to be closed out.

Announce which stage you detected and proceed to the corresponding step.

---

### Step 2A: From scratch — research, plan, and build

Only if Stage A was detected.

**Research the codebase first.** Use subagents to understand:
- The project structure, tech stack, and patterns in use
- The database schema if relevant (look for migrations, schema files, Prisma/Drizzle schemas, Supabase types)
- Related existing code that the feature will interact with

**Create a plan.** Write a concise implementation plan with checkable items. Choose the plan file location:
- If the project already has `docs/roadmap.md`, `TODO.md`, `TODOS.md`, or `docs/todos/backlog.md`, append the plan there under a new section.
- Otherwise, create `docs/<YYYY-MM-DD>-<slug>-plan.md`.

The plan should:
- Break the work into discrete steps
- Note any files that need to be created or modified
- Call out edge cases and error handling

**Review the plan with plan-critic.** Before building, run an automated plan review:

Use `$hypt-plan-critic`

Pass the plan file path AND the original user request. State clearly that this is pipeline mode:

> Review this plan in pipeline mode (fully autonomous, no user interaction).
> Plan file: `<path to the plan file you chose above>`
> Original request: [restate the user's original request/description here]

Plan-critic will review the plan, make its own calls on non-blocker issues, update the plan file directly, and return control. Do NOT wait for user confirmation — plan-critic in pipeline mode is fully autonomous.

**IMPORTANT: After plan-critic returns, IMMEDIATELY continue to the build step below. Do NOT stop or wait — the pipeline must keep moving.**

After plan-critic completes, re-read the plan (it may have been updated) and proceed. If plan-critic noted Open Questions in the plan file, these do not stop the pipeline — continue to build.

**Build it.** Use `$hypt-prototype`

When prototype asks for a plan, point it to the plan file you chose above or provide the plan directly. When prototype asks for user input at any step, make the autonomous choice — fix all review findings, skip nothing.

After prototype completes, continue to Step 3.

---

### Step 2B: Mid-implementation — get to review-ready

Only if Stage B was detected.

Save any uncommitted changes and ensure a PR exists:

Use `$hypt-save`

If $hypt-save reports "Nothing to save" and no PR exists yet, create one so the rest of the pipeline has something to work with:
```bash
git push -u origin HEAD
gh pr create --fill
```

Continue to Step 3.

---

### Step 2C/2D: Already review-ready or mergeable

If Stage C, continue to Step 3.
If Stage D, skip directly to Step 6.

---

### Step 3: Review-and-fix loop

Run review and touchup in a loop until the code is clean. Maximum 3 iterations to avoid infinite loops.

**Iteration pattern:**

1. Use `$hypt-review`
   - Fix ALL findings — urgent, medium, and low. Reply "all" when asked.
   - Skip unit test suggestions (handled separately in Step 4).
   - After fixes, save the changes:

     Use `$hypt-save`

2. Use `$hypt-touchup`
   - This catches PR bot comments, build issues, and remaining polish.

3. **Check if clean:** After touchup, assess whether there are remaining issues:
   - If touchup made changes or the review had urgent/medium findings, run another iteration.
   - If the review was clean (no urgent or medium findings) and touchup had nothing to fix, the code is ready. Exit the loop.

If after 3 iterations there are still issues, report what's remaining and continue anyway — don't get stuck in an infinite loop.

---

### Step 4: Unit tests (only if project has them)

Check the Context section — the "Has unit tests" field shows whether the project already has test files.

**If test files exist:** Use `$hypt-unit-tests`

After tests are added and passing, save the changes:

Use `$hypt-save`

**If no test files exist:** Skip this step entirely. Do not create a test infrastructure from scratch.

---

### Step 5: Documentation updates

Run the docs skill to update project documentation — check off completed backlog items, update READMEs if new features were added, refresh feature docs, and update dates/status indicators.

Use `$hypt-docs`

This ensures the PR includes documentation updates before it's finalized. If no docs need updating, the skill skips silently.

After docs completes, continue immediately to Step 6.

---

### Step 6: Final save

Run one last save to ensure everything is committed, pushed, and the PR description reflects all work:

Use `$hypt-save`

Confirm the pipeline is complete:

> Pipeline complete. PR is reviewed, tested, and ready.

---

## Handling blockers

Throughout this flow, only stop and ask the user if you encounter:

- **Security vulnerabilities** — auth bypass, exposed secrets, SQL injection, XSS, etc. that genuinely put users at risk
- **Destructive data operations** — migrations that drop data, irreversible state changes
- **Ambiguous requirements** — the feature request is genuinely unclear and you'd be guessing wrong
- **Persistent build/test failures** — after 2 attempts to fix, the same failure keeps recurring

For everything else — lint warnings, minor style choices, which approach to take — make the call yourself and keep going.
