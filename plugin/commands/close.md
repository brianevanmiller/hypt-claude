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

### Step 2: Ensure PR exists, then merge

Check if a PR exists for this branch:
```bash
gh pr view --json number,url 2>/dev/null
```

If no PR exists, create one:
```bash
git push -u origin HEAD
gh pr create --fill
```

Then merge:
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

### Step 6: Version bump and release

After merging, automatically bump the version and create a GitHub release.

**Get the latest release version:**
```bash
gh release view --json tagName --jq '.tagName' 2>/dev/null
```

If no releases exist, start from `v0.1.0`. Otherwise, parse the tag (e.g. `v0.5.0`) into major.minor.patch.

**Determine bump type from the PR:**

Use the PR title and commit messages (already available from earlier steps) to decide:

| PR content | Bump | Example |
|-----------|------|---------|
| Bug fixes, chore, docs, small tweaks, touchups, config changes | **Patch** | v0.5.0 → v0.5.1 |
| New features, new skills/commands, significant enhancements, breaking changes | **Minor** | v0.5.0 → v0.6.0 |

**If ambiguous** (e.g. a mix of features and fixes, or unclear scope), ask the user:

> Version bump: the current release is `v0.5.0`. Should the next version be:
> 1. **v0.5.1** (patch — bug fixes / small changes)
> 2. **v0.6.0** (minor — new features / enhancements)

Wait for the user's response before continuing.

**Update version files and create release:**

```bash
# Update VERSION file (no v prefix)
echo "<NEW_VERSION>" > VERSION

# Update plugin.json version field
# Use sed or edit the file to set "version": "<NEW_VERSION>"
```

**Update changelog:**

After determining the new version, update `CHANGELOG.md` at the repo root. If it doesn't exist, create it with a header.

Get the previous release tag to scope the changes:
```bash
PREV_TAG=$(gh release list --limit 1 --json tagName --jq '.[0].tagName' 2>/dev/null)
```

Generate the entry by reading the PR title and commits since the previous tag:
```bash
git log ${PREV_TAG}..HEAD --oneline --no-merges 2>/dev/null
```

Write a new entry at the top of CHANGELOG.md (below the header), using this format:

```markdown
## v<NEW_VERSION> — <YYYY-MM-DD>

- <One-line summary of the PR that was just merged>
- <Any other notable changes from the commits, if multiple>
```

Keep entries concise — one bullet per logical change, no commit hashes, no author names. Write from the user's perspective (what changed), not the developer's (what files were touched).

Then commit, push, and release:
```bash
git add VERSION plugin/.claude-plugin/plugin.json CHANGELOG.md
git commit -m "chore: bump version to v<NEW_VERSION>"
git push origin main
gh release create v<NEW_VERSION> --title "v<NEW_VERSION>" --generate-notes
```

Capture the release URL from the output.

### Step 7: Final summary

```
Closed!
- PR #X merged to main
- Released: v<NEW_VERSION> (<release URL>)
- Preview: <url or "checking...">
- Production: <url or "checking...">
- Branch cleaned up
```
