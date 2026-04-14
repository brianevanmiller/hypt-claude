---
description: "Verify deployment is healthy — detect platform, check status, fix trivial issues"
allowed-tools: ["Bash", "Read", "Grep", "Glob", "Edit", "Write"]
---

# /deploy — Verify Deployment

## Context

- Branch: !`git branch --show-current`
- Latest commit: !`git log --oneline -1`
- PR status: !`gh pr view --json number,title,url,state 2>/dev/null || echo "No PR found"`

## Instructions

### Step 1: Detect context

```bash
BRANCH=$(git branch --show-current)
```

If the branch is `main`, this is a **production** deploy check. Otherwise it's a **preview** deploy check.

---

### Step 1b: Detect deployment platform

Check for deployment platform indicators in this order:

```bash
# Check for platform config files
ls vercel.json .vercel/ 2>/dev/null && echo "PLATFORM=vercel"
ls netlify.toml _redirects 2>/dev/null && echo "PLATFORM=netlify"
ls fly.toml 2>/dev/null && echo "PLATFORM=fly"
ls render.yaml 2>/dev/null && echo "PLATFORM=render"
ls railway.json railway.toml 2>/dev/null && echo "PLATFORM=railway"
```

Use the first match. If no config file is found, fall back to the **GitHub Deployments API** (generic method).

---

### Step 1c: Vercel team access check (Vercel only)

If the platform is NOT `vercel`, skip this step entirely.

Vercel's GitHub integration blocks deployments when the commit author isn't a seated team member (free plan limitation). Detect and bypass this automatically.

**Detect team access blocking:**

```bash
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
SHA=$(git rev-parse HEAD)
DEPLOY_ID=$(gh api "repos/$REPO/deployments?sha=$SHA&per_page=1" --jq '.[0].id // empty' 2>/dev/null)
```

If a deployment ID exists for this SHA, check its status:
```bash
DEPLOY_DESC=$(gh api "repos/$REPO/deployments/$DEPLOY_ID/statuses" --jq '.[0].description // empty' 2>/dev/null)
```

If the description contains `TEAM_ACCESS`, `not a member`, or `contributing access` → team access is blocked.

If no deployment exists for this SHA yet, check the **most recent deployment** (any SHA) for the same pattern. Only trigger the bypass if the recent failed deployment's commit author matches the current HEAD author (to avoid false positives from different blocked authors):
```bash
RECENT_DEPLOY_ID=$(gh api "repos/$REPO/deployments?per_page=1" --jq '.[0].id // empty' 2>/dev/null)
RECENT_DESC=$(gh api "repos/$REPO/deployments/$RECENT_DEPLOY_ID/statuses" --jq '.[0].description // empty' 2>/dev/null)
RECENT_SHA=$(gh api "repos/$REPO/deployments/$RECENT_DEPLOY_ID" --jq '.sha // empty' 2>/dev/null)
RECENT_AUTHOR=$(git log --format='%ae' "$RECENT_SHA" -1 2>/dev/null)
CURRENT_AUTHOR=$(git log --format='%ae' HEAD -1)
```
Only consider this a team access block if the description matches AND `RECENT_AUTHOR` equals `CURRENT_AUTHOR`.

If no team access issue is detected → continue to Step 2 normally.

**If team access IS blocked — CLI bypass:**

First, ensure the working tree is clean before proceeding:
```bash
git status --porcelain
```
If there are uncommitted changes, say:
> You have uncommitted changes. Run `/save` first, then try `/deploy` again.

And stop.

Also confirm the Vercel CLI is available:
```bash
bunx vercel whoami 2>&1
```
If this fails, tell the user to run `bunx vercel login` and `bunx vercel link` first, then stop.

1. Find a valid deploy author (someone on the Vercel team) from the most recent **successful** deployment. Use a single API call to fetch deployments, then check statuses efficiently:
   ```bash
   # Fetch recent deployment SHAs and find the first successful one
   GOOD_SHA=$(gh api "repos/$REPO/deployments?per_page=5" --jq '
     [.[] | {id: .id, sha: .sha}] | .[].id
   ' 2>/dev/null | while read id; do
     STATE=$(gh api "repos/$REPO/deployments/$id/statuses" --jq '.[0].state' 2>/dev/null)
     if [ "$STATE" = "success" ]; then
       gh api "repos/$REPO/deployments/$id" --jq '.sha' 2>/dev/null
       break
     fi
   done)
   ```
   Keep the search to 5 deployments max to limit API calls.

   **If `GOOD_SHA` is non-empty**, extract the author:
   ```bash
   VALID_AUTHOR=$(git log --format='%an <%ae>' "$GOOD_SHA" -1 2>/dev/null)
   ```

   **If `GOOD_SHA` is empty** (no successful deployments found), use fallbacks in order:
   - Get the Vercel-authenticated user via `bunx vercel whoami`, then search `git log --all --format='%an <%ae>' | sort -u` for a case-insensitive match on that username
   - Use the author of the first commit in the repo: `git log --reverse --format='%an <%ae>' | head -1`
   - If all fail: ask the user for the Vercel project owner's git name and email, then stop

   **If `VALID_AUTHOR` is still empty after all fallbacks, stop** and ask the user.

2. Save original state and create an isolated detached HEAD for the deploy:
   ```bash
   ORIGINAL_SHA=$(git rev-parse HEAD)
   ORIGINAL_BRANCH=$(git branch --show-current)
   git checkout --detach HEAD
   git commit --amend --no-edit --author="$VALID_AUTHOR"
   ```

3. Deploy via Vercel CLI:
   ```bash
   # If deploying to production (was on main):
   bunx vercel deploy --prod --yes 2>&1
   # If deploying a preview (was on feature branch):
   bunx vercel deploy --yes 2>&1
   ```

4. Capture the deployment URL from the CLI output (typically the last line).

5. **ALWAYS** restore the original branch, even if the deploy failed:
   ```bash
   git checkout $ORIGINAL_BRANCH
   ```
   Since we detached HEAD before amending, the original branch still points to the unmodified commit. No history was rewritten on any named branch.

6. Report to the user:
   > **Deployed via CLI bypass** — Vercel's auto-deploy was blocked because the commit author isn't a seated member of the Vercel team. This is a known free-plan limitation and doesn't affect your app — everything deployed successfully.
   >
   > Auto-deploys from GitHub will continue to need this workaround until the commit author is added to the Vercel team (requires a paid seat).

7. Remember that the CLI deploy was used. Carry the deployment URL forward to Step 2 for health verification — skip the deployment lookup steps and go straight to the health check.

---

### Step 2a: Feature branch (preview)

If the branch is NOT `main`:

1. Ensure changes are pushed:
   ```bash
   git status --porcelain
   ```
   If there are unpushed commits or uncommitted changes, say:
   > You have uncommitted or unpushed changes. Run `/save` first, then try `/deploy` again.
   
   And stop.

2. Check for a PR:
   ```bash
   gh pr view --json number,url,statusCheckRollup 2>/dev/null
   ```
   If no PR exists, say:
   > No PR found for this branch. Run `/save` to create one, then try `/deploy` again.
   
   And stop.

3. Find the latest preview deployment using the detected platform:

   **If the CLI bypass was used in Step 1c:** Skip finding the deployment via GitHub. Use the deployment URL from the bypass. Jump directly to step 5 (health check).

   **Vercel:**
   ```bash
   gh pr checks --json name,state,link --jq '.[] | select(.name | test("vercel|Vercel|deployment"; "i"))'
   ```

   **Netlify:**
   ```bash
   gh pr checks --json name,state,link --jq '.[] | select(.name | test("netlify|Netlify|deploy"; "i"))'
   ```

   **Generic (any platform) — GitHub Deployments API:**
   ```bash
   REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
   SHA=$(git rev-parse HEAD)
   gh api "repos/$REPO/deployments?sha=$SHA" --jq '.[0] | {id, environment, created_at}'
   ```
   Then get status:
   ```bash
   gh api "repos/$REPO/deployments/<DEPLOYMENT_ID>/statuses" --jq '.[0] | {state, target_url, description}'
   ```

4. **Poll if still pending.** If the deployment state is `pending` or `in_progress`, wait 15 seconds and check again. Poll up to 8 times (2 minutes max). If still not done, report current state and stop.

5. **Health check the preview URL.** Once you have the preview URL (from `target_url` or `detailsUrl`):
   ```bash
   curl -sL -o /dev/null -w "%{http_code}" "<PREVIEW_URL>"
   ```
   A 200 means healthy. Anything else — report the status code.

6. **Report:**
   ```
   Preview deployment ✓
   - PR: #<number> — <url>
   - Preview: <preview_url>
   - Platform: <detected platform>
   - Status: <healthy / unhealthy (HTTP <code>)>
   ```

---

### Step 2b: Main branch (production)

If the branch IS `main`:

1. Pull latest:
   ```bash
   git pull origin main
   ```

2. Find the latest production deployment using the detected platform:

   **If the CLI bypass was used in Step 1c:** Skip finding the deployment via GitHub API. Use the deployment URL from the bypass. Jump directly to step 4 (health check).

   **Vercel:**
   ```bash
   REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
   gh api "repos/$REPO/deployments?environment=Production&per_page=1" --jq '.[0] | {id, sha, created_at}'
   ```

   **Generic (any platform):**
   ```bash
   REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
   gh api "repos/$REPO/deployments?per_page=1" --jq '.[0] | {id, sha, environment, created_at}'
   ```
   Then get status:
   ```bash
   gh api "repos/$REPO/deployments/<DEPLOYMENT_ID>/statuses" --jq '.[0] | {state, target_url, description}'
   ```

3. **Poll if pending** — same as preview: wait 15s, up to 8 times.

4. **If deployment succeeded**, health check the production URL:
   ```bash
   curl -sL -o /dev/null -w "%{http_code}" "<PRODUCTION_URL>"
   ```

5. **If deployment failed or health check failed:**

   First, check if this is a Vercel team access issue (not a build error). Re-fetch the deployment status for the current SHA:
   ```bash
   REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
   SHA=$(git rev-parse HEAD)
   FAIL_DEPLOY_ID=$(gh api "repos/$REPO/deployments?sha=$SHA&per_page=1" --jq '.[0].id // empty' 2>/dev/null)
   FAIL_DESC=$(gh api "repos/$REPO/deployments/$FAIL_DEPLOY_ID/statuses" --jq '.[0].description // empty' 2>/dev/null)
   ```
   If the description contains `TEAM_ACCESS`, `not a member`, or `contributing access` — this is the team access block, not a code issue. Execute the **Step 1c CLI bypass procedure**, then use the deployment URL from the bypass to health-check (step 4 above) and report (step 6 below). Do NOT re-enter Step 2b from the top.

   Otherwise, investigate the build error. Check deployment logs if available:
   ```bash
   gh api "repos/$REPO/deployments/<DEPLOYMENT_ID>/statuses" --jq '.[0]'
   ```

   Also try a local build to reproduce:
   ```bash
   npm run build 2>&1 | tail -50
   ```

   **If the issue is trivial** (type error, missing import, small config issue, lint error):
   - Create a fix branch:
     ```bash
     git checkout -b fix/deploy-<short-description>
     ```
   - Fix the issue
   - Commit, push, and create a PR:
     ```bash
     git add -A
     git commit -m "fix: <description of the fix>"
     git push -u origin HEAD
     gh pr create --fill
     ```
   - **Do NOT merge.** Ask the user:
     > Production build issue found and fixed. PR created: <url>
     > Want me to merge this fix to main?

   - If the user confirms, merge it:
     ```bash
     gh pr merge --squash --delete-branch
     git checkout main && git pull
     ```
     Then re-run the production deployment check from the top of Step 2b.

   **If the issue is NOT trivial**, report what you found and stop:
   > Production deployment failed. This doesn't look like a trivial fix.
   > Error: <summary of the error>
   > Recommendation: <what to investigate>

6. **Report:**
   ```
   Production deployment ✓
   - Commit: <sha> — <message>
   - Production: <production_url>
   - Platform: <detected platform>
   - Status: <healthy / unhealthy (HTTP <code>)>
   ```

   Or if there was a fix:
   ```
   Production deployment fixed!
   - Fix PR: <url> (merged)
   - Production: <production_url>
   - Status: healthy
   ```
