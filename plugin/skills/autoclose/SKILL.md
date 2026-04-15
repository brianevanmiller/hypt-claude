---
name: autoclose
description: >
  Autonomous close — merge PR, deploy check, version bump, and release without
  confirmation. Used by /yolo and /go after their own confirmation handling.
allowed-tools: ["Bash", "Read", "Edit", "Grep", "Glob", "Skill"]
version: "1.0.0"
author: "Brian Miller"
license: "MIT"
---

# hypt:autoclose — Merge PR and Wrap Up (No Confirmation)

## Preamble (run silently before the skill)

```bash
_UPD=$(~/.claude/plugins/marketplaces/hypt-claude/bin/hypt-update-check 2>/dev/null || true)
echo "${_UPD:-UP_TO_DATE}"
```

- If output contains `UPGRADE_AVAILABLE <old> <new>`: Silently run `bash ~/.claude/plugins/marketplaces/hypt-claude/install.sh` then briefly tell the user: "hypt updated to v{new}. Restart Claude Code when convenient to use the latest version." Then continue with the skill normally.
- If output contains `JUST_UPGRADED <old> <new>`: Briefly say "Running hypt v{new} (updated from v{old})." then continue.
- Otherwise: continue silently — say nothing about updates.

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

### Step 2: Check off completed items in project docs

Before merging, scan project documentation for checklist items that were completed by this PR and mark them done.

**Find what was shipped:**
```bash
gh pr view --json title,body,files --jq '{title, body, files: [.files[].path]}' 2>/dev/null
```

Also read the recent commit messages:
```bash
git log --oneline -10
```

**Scan for documentation files with checklists:**
```bash
find . -maxdepth 3 -name "*.md" -not -path "./.git/*" -not -path "./node_modules/*" | xargs grep -l "\- \[ \]" 2>/dev/null
```

This typically includes files like:
- `docs/todos/backlog.md` — project backlog
- `TODOS.md` or `TODO.md` — root-level to-dos
- `docs/roadmap.md` or similar — project roadmap
- `thoughts/todo.md` — working plans

**For each file found**, read it and compare unchecked items (`- [ ]`) against the PR title, body, commit messages, and files changed. An item is considered completed if:
- The PR title or body explicitly references it (e.g., "add dark mode" matches `- [ ] Add dark mode support`)
- The commits clearly implement what the item describes
- The files changed correspond directly to the item's scope

Use semantic matching — don't require exact string matches. For example, a PR titled "feat: add user authentication" should match `- [ ] User auth / login flow`.

**Check off matched items** by editing the file to change `- [ ]` to `- [x]` for each completed item.

**If any items were checked off**, commit the changes:
```bash
git add -A docs/ TODOS.md TODO.md thoughts/todo.md 2>/dev/null
git diff --cached --quiet || git commit -m "docs: mark completed items from PR"
git push -u origin HEAD 2>/dev/null
```

If no items match, move on silently — don't mention it in the output.

### Step 3: Suggest next tasks and update backlog

Before merging, surface what to work on next and optionally track it in the project backlog.

Invoke the Skill tool with skill: "hypt:suggestions"

Wait for it to complete before continuing. If it adds backlog items, they'll be committed and included in the PR before merge.

### Step 4: Polish PR before merge

Before merging, make sure the PR title and description accurately represent all the work in this branch.

**Gather the full picture:**
```bash
# All commits on this branch vs main
git log origin/main..HEAD --oneline --no-merges
# Summary of all files changed
git diff origin/main..HEAD --stat
# Current PR info
gh pr view --json title,body --jq '{title, body}' 2>/dev/null
```

**Evaluate the current PR title:**
- If it's just the branch name, auto-generated, or doesn't reflect the work: update it
- Use conventional commit style: `feat: ...`, `fix: ...`, `chore: ...`
- Keep it under 70 characters

**Regenerate the PR body** from all commits and files changed. Use this format:

```
## Summary
<2-4 bullet points summarizing what this PR does overall, written from the user's perspective>

## Changes
<one bullet per logical change, concise — group related commits>

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

**Update the PR:**
```bash
gh pr edit --title "<polished title>" --body "$(cat <<'EOF'
<generated body>
EOF
)"
```

### Step 5: Ensure PR exists, then merge

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

### Step 6: Check deployment

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
gh api "repos/$REPO/deployments/<ID>/statuses" --jq '.[0] | {state, target_url, description}' 2>/dev/null
```

**Note:** After merging, prefer Method 2 (GitHub Deployments API) for production deployment status, since PR check runs may not update after merge. You are now on `main` after `git checkout main && git pull` from Step 5.

**Check for Vercel team access block:**

If any deployment status description matches the Vercel team access detection criteria (`TEAM_ACCESS`, `not a member`, or `contributing access`), this means Vercel is blocking auto-deploys because the commit author isn't a seated team member (free plan limitation). Do NOT treat this as a build failure.

Instead:
- Inform the user: "Vercel blocked the auto-deploy — commit author isn't a team member. Deploying via CLI bypass..."
- Run the bypass script directly:
  ```bash
  BYPASS_URL=$(~/.claude/plugins/marketplaces/hypt-claude/bin/hypt-vercel-bypass --prod 2>&1)
  BYPASS_EXIT=$?
  echo "EXIT=$BYPASS_EXIT URL=$BYPASS_URL"
  ```
- If exit 0: use `BYPASS_URL` as the production deployment URL for the close summary below.
- If exit 1: report the error from the script output and stop.
- If exit 2: not actually blocked — continue with normal deployment status reporting.

Report whatever you find:
- **Preview URL**: The deployment URL for this specific PR/branch
- **Production URL**: The main deployment URL (if this was merged to main)

If no deployment info is available, say:
> Deployment info not available. Check your deployment dashboard for status.

### Step 7: Review CI for the new feature

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

### Step 8: Version bump and release

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

### Step 9: Final summary

```
Closed!
- PR #X merged to main
- Released: v<NEW_VERSION> (<release URL>)
- Completed: <N items checked off in docs / no items matched>
- Backlog: <N items added to docs/todos/backlog.md / no changes>
- Preview: <url or "checking...">
- Production: <url or "checking...">
- Branch cleaned up
```
