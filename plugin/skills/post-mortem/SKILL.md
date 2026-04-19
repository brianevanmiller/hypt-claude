---
name: post-mortem
description: >
  Analyze what went wrong after a restore — review recent changes to main,
  create a post-mortem document, update backlog with findings, and suggest
  next steps. Runs automatically after /restore.
allowed-tools: ["Bash", "Read", "Edit", "Write", "Grep", "Glob", "Agent", "Skill"]
version: "1.0.0"
author: "Brian Miller"
license: "MIT"
---

# hypt:post-mortem — Post-Restore Incident Analysis

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
- Current date: !`date +%Y-%m-%d`
- Recent merges to main (last 10): !`git log origin/main --oneline --merges -10 2>/dev/null || git log main --oneline --merges -10 2>/dev/null || echo "No merge history"`
- Recent commits to main (last 10): !`git log origin/main --oneline -10 2>/dev/null || git log main --oneline -10 2>/dev/null || echo "No commit history"`
- Latest revert commit: !`git log origin/main --oneline --grep="Revert" -1 2>/dev/null || echo "No revert found"`
- Existing post-mortems: !`ls docs/post-mortem/*.md 2>/dev/null || echo "None"`
- Backlog file: !`ls docs/todos/backlog.md 2>/dev/null || echo "No backlog"`
- Deployment platform: !`ls vercel.json .vercel/ 2>/dev/null && echo "PLATFORM=vercel"; ls netlify.toml _redirects 2>/dev/null && echo "PLATFORM=netlify"; ls fly.toml 2>/dev/null && echo "PLATFORM=fly"; ls render.yaml 2>/dev/null && echo "PLATFORM=render"; echo "done"`

## Instructions

This skill runs after `/restore` to document what went wrong. It is designed for non-technical users — write in plain language, avoid jargon, and focus on what happened and what to do next.

---

### Step 1: Identify what was reverted

Find the problematic changes that were just rolled back. Use the Context section above and dig deeper:

```bash
# Find the revert commit (just pushed by /restore)
REVERT_SHA=$(git log origin/main --oneline --grep="Revert" -i -1 --format="%H" 2>/dev/null)
if [ -z "$REVERT_SHA" ]; then
  # No revert commit — restore may have used platform rollback (Vercel/Netlify promotion)
  REVERT_SHA=""
  echo "NO_REVERT_COMMIT — platform rollback was used"
fi
```

**If a revert commit exists**, find the original problematic commit(s):

```bash
# The revert message usually references the original commit
git log "$REVERT_SHA" -1 --format="%B" 2>/dev/null

# Get the commit(s) that were reverted — look at what changed
# The parent of the revert is the state after the bad merge
# Two commits back is the last known-good state
git log origin/main --oneline -5 2>/dev/null
```

**If no revert commit** (platform rollback was used), identify the problematic deploy by looking at recent commits on main:

```bash
# The most recent merge/commit on main is likely the one that broke things
BROKEN_SHA=$(git log origin/main --oneline -1 --format="%H" 2>/dev/null)
git log "$BROKEN_SHA" -1 --format="%B" 2>/dev/null
git diff "$BROKEN_SHA"^.."$BROKEN_SHA" --stat 2>/dev/null
```

**Important:** Regardless of which path above was taken (revert commit found or platform rollback), you should now have identified the problematic commit SHA. Use this SHA (referred to as `BROKEN_SHA` below) for the rest of the analysis.

Determine:
- **What PR/commit caused the issue** — PR number, title, author if available
- **What files were changed** — the diff stat
- **When it was merged** — timestamp

```bash
# Try to find the associated PR
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null)
if [ -n "$REPO" ]; then
  # Search for PRs merged recently
  gh pr list --state merged --limit 5 --json number,title,mergedAt,author --jq '.[] | "\(.number) \(.title) \(.mergedAt) \(.author.login)"' 2>/dev/null
fi
```

---

### Step 2: Analyze what likely went wrong

Read the actual code changes from the problematic commit to understand the failure:

```bash
# Get the full diff of the problematic changes
git show "$BROKEN_SHA" --stat 2>/dev/null
git show "$BROKEN_SHA" 2>/dev/null | head -200
```

Use a subagent to analyze the diff if it's large. Look for common failure patterns:

- **Build failures** — syntax errors, missing imports, broken build config
- **Runtime errors** — null references, missing environment variables, broken API calls
- **Data issues** — bad migrations, schema mismatches, missing seed data
- **Deployment config** — wrong environment settings, missing secrets, platform config errors
- **Dependency issues** — incompatible versions, missing packages, lockfile conflicts
- **UI/UX breaks** — broken layouts, missing assets, wrong routes

**Classify the root cause as "obvious" or "involved":**

**Obvious** — the root cause is clearly visible in the diff:
- A syntax error, missing import, or typo
- A clearly wrong conditional or variable reference
- A missing environment variable that's referenced in the new code
- A build config change with an obvious mistake
- A single file change with a clear logic error

**Involved** — the root cause is NOT clear from the diff alone:
- Multiple files changed and the interaction between them could be the issue
- The diff looks correct but the deploy still broke (runtime/environment issue)
- The changes involve infrastructure, deployment config, or external services
- Database migration or schema changes that could have side effects
- The error could be in how the code interacts with production data or state
- Multiple possible causes and it's unclear which one is the actual culprit

#### Step 2a: Escalate to /investigate (when the cause is involved)

**If the root cause is classified as "involved" AND `GSTACK` is `true`:**

Tell the user:
> The root cause isn't obvious from the code changes alone. Running a deeper investigation...

Invoke the Skill tool with skill: "investigate"

The investigate skill will do systematic root-cause analysis — checking logs, testing hypotheses, and using browser-based debugging if needed. After it completes, use its findings to enrich the post-mortem document in Step 3 (replace the "Likely Root Cause" section with the investigation's findings).

**If the root cause is classified as "involved" AND `GSTACK` is `false`:**

Note the uncertainty in the analysis. In the post-mortem document (Step 3), mark the root cause as "Suspected" rather than "Confirmed" and add a recommendation:

> **Note:** The root cause couldn't be definitively determined from the code diff alone. For deeper investigation, install gstack (`git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup`) and run `/investigate` in a new session.

**If the root cause is classified as "obvious":**

Continue to Step 3 with the findings — no escalation needed.

---

### Step 3: Create the post-mortem document

Create the `docs/post-mortem/` directory if it doesn't exist, then write the post-mortem:

```bash
mkdir -p docs/post-mortem
```

**File naming:** `docs/post-mortem/YYYY-MM-DD-<topic>-post-mortem.md`

- Use today's date from the Context section
- The `<topic>` should be a short, lowercase, hyphenated description (e.g., `broken-auth`, `build-failure`, `missing-env-vars`)
- Keep the topic under 5 words

**Document format:**

```markdown
# Post-Mortem: <Short Description>

**Date:** YYYY-MM-DD
**Severity:** <Critical (site down) / High (major feature broken) / Medium (partial breakage)>
**Restored via:** <Git revert / Vercel rollback / Netlify rollback / etc.>
**Root cause confidence:** <Confirmed / Suspected>

## What Happened

<2-3 sentence plain-language summary of what broke and how it was noticed.
Write for a non-coder — avoid technical jargon where possible.>

## What Changed

- **PR/Commit:** <#number — title> (or commit SHA if no PR)
- **Merged:** <date/time>
- **Files changed:** <count> files
- **Key changes:** <brief list of what the code changes did>

## Likely Root Cause

<Plain-language explanation of what went wrong in the code.
Be specific about which file or change likely caused the issue.
If uncertain, list the top 2-3 suspects with reasoning.

If /investigate was run, include its findings here — this will be more detailed
and confident than diff-only analysis.>

## Impact

- **Duration:** <how long the site was broken, if known — from merge time to restore>
- **Affected:** <what users/features were impacted>

## Action Items

- [ ] Fix the root cause identified above
- [ ] <Any additional specific fixes needed>
- [ ] Verify the fix doesn't reintroduce the issue
- [ ] Re-deploy and confirm site is healthy

## How to Fix

Start a new Claude Code session and run one of:

- `/go fix the most recent post-mortem issue` — does the research, plans, builds, and reviews, then asks before merging
- `/yolo fix the most recent post-mortem issue` — fully autonomous fix and ship
- `/fix` — just diagnose and fix the bug with more control over each step
```

Write the file using the Write tool.

---

### Step 4: Update backlog and todos

**Update `docs/todos/backlog.md`** (if it exists) — add the issue under the Bugs section:

Read the current backlog, then add a new unchecked item under `## Bugs` that describes the issue found in the post-mortem. Use the Edit tool.

Format: `- [ ] Fix <brief description of what broke> — see [post-mortem](../post-mortem/YYYY-MM-DD-<topic>-post-mortem.md)`

**Check for other todo/roadmap files** and update them if relevant:

```bash
find . -maxdepth 3 -name "*.md" -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./.context/*" -print0 2>/dev/null | xargs -0 grep -l -i "roadmap\|todo\|backlog" 2>/dev/null | head -5
```

If a roadmap or additional todo file exists and references the feature that broke, add a note about the regression.

---

### Step 5: Commit the post-mortem

```bash
git add docs/post-mortem/ docs/todos/backlog.md 2>/dev/null
git diff --cached --quiet || git commit -m "docs: add post-mortem for $(date +%Y-%m-%d) incident"
git push origin HEAD 2>/dev/null || git push -u origin HEAD 2>/dev/null || true
```

---

### Step 6: Report and suggest next steps

Present the post-mortem summary to the user in a friendly, non-technical way:

```
Post-mortem complete
────────────────────
Issue:     <one-line description of what broke>
Cause:     <one-line likely root cause>
Confidence: <Confirmed / Suspected>
Document:  docs/post-mortem/YYYY-MM-DD-<topic>-post-mortem.md
Backlog:   Updated with fix task
```

If `/investigate` was used, add:
```
Investigation: Deep root-cause analysis completed via gstack
```

Then suggest the fix workflow:

> **Want to fix this?** Start a new session and tell Claude:
>
> - `fix the most recent post-mortem issue` — Claude will diagnose and fix the bug step by step
>
> Or for more automation:
> - `/go fix the most recent post-mortem issue` — autonomous fix with confirmation before merge
> - `/yolo fix the most recent post-mortem issue` — fully autonomous fix and ship
>
> The post-mortem document has all the details Claude needs to understand what went wrong.
