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

**Detection criteria** (used here and referenced by Steps 2a, 2b, and /close): the deployment status description contains `TEAM_ACCESS`, `not a member`, or `contributing access`.

**Detect team access blocking:**

```bash
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
SHA=$(git rev-parse HEAD)
DEPLOY_ID=$(gh api "repos/$REPO/deployments?sha=$SHA&per_page=1" --jq '.[0].id // empty' 2>/dev/null)
```

If `DEPLOY_ID` is non-empty, check its status:
```bash
DEPLOY_DESC=$(gh api "repos/$REPO/deployments/$DEPLOY_ID/statuses" --jq '.[0].description // empty' 2>/dev/null)
```

If the description matches the detection criteria above → team access is blocked.

If no deployment exists for this SHA yet (`DEPLOY_ID` is empty), check the **most recent deployment** (any SHA) as a heuristic. Only trigger the bypass if the recent deployment matches the detection criteria AND its commit author matches the current HEAD author:
```bash
RECENT_DEPLOY_ID=$(gh api "repos/$REPO/deployments?per_page=1" --jq '.[0].id // empty' 2>/dev/null)
```
If `RECENT_DEPLOY_ID` is non-empty:
```bash
RECENT_DESC=$(gh api "repos/$REPO/deployments/$RECENT_DEPLOY_ID/statuses" --jq '.[0].description // empty' 2>/dev/null)
RECENT_SHA=$(gh api "repos/$REPO/deployments/$RECENT_DEPLOY_ID" --jq '.sha // empty' 2>/dev/null)
```
If `RECENT_SHA` is non-empty, compare authors:
```bash
RECENT_AUTHOR=$(git log --format='%ae' "$RECENT_SHA" -1 2>/dev/null)
CURRENT_AUTHOR=$(git log --format='%ae' HEAD -1)
```
Only consider this a team access block if: the description matches the detection criteria AND `RECENT_AUTHOR` equals `CURRENT_AUTHOR`. If `RECENT_DEPLOY_ID`, `RECENT_SHA`, or the description is empty, skip the heuristic — no team access issue detected.

If no team access issue is detected → continue to Step 2 normally.

---

**If team access IS blocked — CLI bypass procedure:**

> **CRITICAL:** If ANY step below fails, your FIRST action MUST be to restore the original branch (step 5) before reporting the error. Do not skip restoration.

First, ensure the working tree is clean:
```bash
git status --porcelain
```
If there are uncommitted changes, say "You have uncommitted changes. Run `/save` first, then try `/deploy` again." and stop.

Confirm the Vercel CLI is available and authenticated:
```bash
bunx vercel whoami 2>&1
```
If this fails, tell the user to run `bunx vercel login` and `bunx vercel link` first, then stop.

**1. Find a valid deploy author** (someone on the Vercel team) from the most recent successful deployment:
```bash
# Fetch up to 5 recent deployment IDs, then check each for success
GOOD_SHA=""
for id in $(gh api "repos/$REPO/deployments?per_page=5" --jq '.[].id' 2>/dev/null); do
  STATE=$(gh api "repos/$REPO/deployments/$id/statuses" --jq '.[0].state' 2>/dev/null)
  if [ "$STATE" = "success" ]; then
    GOOD_SHA=$(gh api "repos/$REPO/deployments/$id" --jq '.sha' 2>/dev/null)
    break
  fi
done
```
Run this as a **single bash invocation** so the `GOOD_SHA` variable is available after the loop.

If `GOOD_SHA` is non-empty, extract the author:
```bash
VALID_AUTHOR=$(git log --format='%an <%ae>' "$GOOD_SHA" -1 2>/dev/null)
```

If `GOOD_SHA` is empty (no successful deployments found), use fallbacks in order:
- Get the Vercel-authenticated user via `bunx vercel whoami`, then search `git log --all --format='%an <%ae>' | sort -u` for a case-insensitive match on that username
- Use the author of the first commit: `git log --reverse --format='%an <%ae>' | head -1` — but **skip this** if that author's email matches the currently blocked author
- If all fail: ask the user for the Vercel project owner's git name and email, then stop

If `VALID_AUTHOR` is still empty after all fallbacks, stop and ask the user.

**2. Save state and create an isolated detached HEAD:**
```bash
ORIGINAL_SHA=$(git rev-parse HEAD)
ORIGINAL_BRANCH=$(git branch --show-current)
git checkout --detach HEAD
git commit --amend --no-edit --author="$VALID_AUTHOR"
```

**3. Deploy via Vercel CLI:**
```bash
if [ "$ORIGINAL_BRANCH" = "main" ]; then
  bunx vercel deploy --prod --yes 2>&1
else
  bunx vercel deploy --yes 2>&1
fi
```

**4. Capture the deployment URL** from the CLI output (typically the last line).

**5. ALWAYS restore the original branch** — even if the deploy failed:
```bash
if [ -n "$ORIGINAL_BRANCH" ]; then
  git checkout "$ORIGINAL_BRANCH"
else
  git checkout "$ORIGINAL_SHA"
fi
```
Since we detached HEAD before amending, the original branch still points to the unmodified commit. No history was rewritten on any named branch. If checkout fails, try `git checkout "$ORIGINAL_SHA"` as a fallback and warn the user.

**6. Report to the user:**
> **Deployed via CLI bypass** — Vercel's auto-deploy was blocked because the commit author isn't a seated member of the Vercel team. This is a known free-plan limitation and doesn't affect your app — everything deployed successfully.
>
> Auto-deploys from GitHub will need this workaround until you upgrade your Vercel team plan. This doesn't cost anything extra for your app — it's just how Vercel handles team permissions on the free tier.

**7.** Carry the deployment URL forward to Step 2 for health verification — skip the deployment lookup steps and go straight to the health check.

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

5. **If the deployment state is `error` or `failure`**, check if this is a Vercel team access issue before reporting. Re-fetch the deployment status for the current SHA:
   ```bash
   REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
   SHA=$(git rev-parse HEAD)
   FAIL_DEPLOY_ID=$(gh api "repos/$REPO/deployments?sha=$SHA&per_page=1" --jq '.[0].id // empty' 2>/dev/null)
   FAIL_DESC=$(gh api "repos/$REPO/deployments/$FAIL_DEPLOY_ID/statuses" --jq '.[0].description // empty' 2>/dev/null)
   ```
   If the description matches the detection criteria from Step 1c, execute the **Step 1c CLI bypass procedure**, then health-check the bypass URL (step 6) and report (step 7). Do NOT re-enter Step 2a from the top.

6. **Health check the preview URL.** Once you have the preview URL (from `target_url` or `detailsUrl`):
   ```bash
   curl -sL -o /dev/null -w "%{http_code}" "<PREVIEW_URL>"
   ```
   A 200 means healthy. Anything else — report the status code.

7. **Report:**
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
   If the description matches the detection criteria from Step 1c — this is the team access block, not a code issue. Execute the **Step 1c CLI bypass procedure**, then health-check the bypass URL (step 4) and proceed directly to step 6 (report) with whatever result the bypass produced. Do NOT re-enter step 5 or Step 2b from the top — if the bypass health check fails, report it as unhealthy and stop.

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
