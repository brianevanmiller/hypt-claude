---
description: "Merge PR, verify deployment, and suggest next tasks"
allowed-tools: ["Bash", "Read", "Grep", "Glob", "Skill"]
---

# /close — Merge PR and Wrap Up

## Context

- PR status: !`gh pr view --json number,title,url,state,mergeStateStatus 2>/dev/null || echo "No PR found"`
- Recent commits: !`git log --oneline -5`
- Branch: !`git branch --show-current`

## Instructions

### Step 1: Run touchup if needed

Check if a recent commit contains `chore: touchup` in the message:
```bash
git log --oneline -10 | grep "chore: touchup"
```

If NOT found, run the touchup skill first:
- Invoke the Skill tool with skill: "hypt:touchup"
- Wait for it to complete before continuing

### Step 2: Merge the PR

```bash
gh pr merge --squash --delete-branch
```

If merge fails:
- If checks are failing: report which checks failed and stop. Tell the user to fix the issues and run `/close` again.
- If there are merge conflicts: report the conflicts and stop.
- If the PR is not in a mergeable state: report why and stop.

After successful merge, switch to main and pull:
```bash
git checkout main && git pull
```

### Step 3: Check deployment

Detect the deployment platform:
```bash
ls vercel.json .vercel/ 2>/dev/null && echo "PLATFORM=vercel"
ls netlify.toml _redirects 2>/dev/null && echo "PLATFORM=netlify"
ls fly.toml 2>/dev/null && echo "PLATFORM=fly"
ls render.yaml 2>/dev/null && echo "PLATFORM=render"
ls railway.json railway.toml 2>/dev/null && echo "PLATFORM=railway"
```

Try to find deployment status and URLs using the detected platform:

**Method 1 — GitHub check runs:**
```bash
gh pr view --json statusCheckRollup --jq '.statusCheckRollup[] | select(.name | test("vercel|netlify|deploy|Vercel|Netlify"; "i")) | {name, status: .status, conclusion: .conclusion, url: .detailsUrl}' 2>/dev/null
```

**Method 2 — GitHub Deployments API:**
```bash
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
gh api "repos/$REPO/deployments?per_page=3" --jq '.[] | {environment, id}' 2>/dev/null
```
Then get status for each:
```bash
gh api "repos/$REPO/deployments/<ID>/statuses" --jq '.[0] | {state, target_url}' 2>/dev/null
```

Report whatever you find:
- **Preview URL**: The deployment URL for this specific PR/branch
- **Production URL**: The main deployment URL (if this was merged to main)

If no deployment info is available, say:
> Deployment info not available. Check your deployment dashboard for status.

### Step 4: Suggest next tasks

Look at these sources to suggest what to work on next:

1. Read `TODOS.md` if it exists — find unchecked items
2. Look at the PR that was just merged — what logically comes next?
3. Check for open issues: `gh issue list --limit 5 2>/dev/null`

Suggest 2-3 concrete next tasks. Keep them actionable and specific:

```
What's next? Here are some suggestions:

1. [Task description] — [why it makes sense now]
2. [Task description] — [why it makes sense now]
3. [Task description] — [why it makes sense now]

Start a new workspace and pick one to work on!
```

### Step 5: Review CI for the new feature

After merging, briefly assess whether the feature that was just shipped warrants any CI additions. This is NOT about adding everything — only suggest changes that directly protect against regressions in the new feature.

**Check what was built:**

Use the PR number from the Context section (captured before merge) to retrieve the PR info:
```bash
gh pr view <PR_NUMBER> --json title,body --jq '"\(.title)
\(.body)"' 2>/dev/null
```

Read the merged PR title/body and recent commits to understand what was shipped.

**Evaluate against these high-value CI additions only:**

| What was shipped | Worth adding to CI? | Why |
|-----------------|-------------------|-----|
| Database migrations or schema changes | **Yes** — suggest Supabase migration validation | Schema breaks are silent and catastrophic |
| Auth logic, RLS policies, or permission changes | **Yes** — suggest auth/RLS integration tests | Security regressions are the worst kind of bug |
| Payment or transaction flows | **Yes** — suggest transaction integration tests | Money bugs erode trust instantly |
| New API routes or server actions | **Maybe** — only if they handle user input | Input validation bugs are common |
| UI components, styling, layout | **No** — skip | Visual bugs are caught in QA, not CI |
| Config changes, env vars, docs | **No** — skip | Low regression risk |

**If there's a high-value suggestion**, present it briefly:

> **CI suggestion:** Now that [feature] is live, it'd be worth adding [specific test type] to CI. This would catch [specific risk] automatically. Want me to set that up? (Just run `/hypt` and ask to set up CI in a new workspace)

Keep it to ONE suggestion max. If nothing is high-value, say nothing about CI — don't clutter the close summary.

### Step 6: Final summary

```
Closed!
- PR #X merged to main
- Preview: <url or "checking...">
- Production: <url or "checking...">
- Branch cleaned up
```
