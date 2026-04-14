---
description: "Verify deployment is healthy — detect platform, check status, fix trivial issues"
allowed-tools: ["Bash", "Read", "Grep", "Glob", "Edit", "Write"]
---

# /deploy — Verify Deployment

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
- Latest commit: !`git log --oneline -1`
- PR status: !`gh pr view --json number,title,url,state 2>/dev/null || echo "No PR found"`

## Instructions

### Step 1: Detect context

```bash
BRANCH=$(git branch --show-current)
```

If the branch is `main`, this is a **production** deploy check. Otherwise, check for a PR first — if a PR exists it's a **preview** deploy check; if no PR exists, fall through to **production** deploy (Step 2b).

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

Vercel's GitHub integration blocks deployments when the commit author isn't a seated team member (free plan limitation). The `hypt-vercel-bypass` script detects and bypasses this automatically.

**Run the bypass script:**

```bash
BRANCH=$(git branch --show-current)
if [ "$BRANCH" = "main" ]; then
  BYPASS_URL=$(~/.claude/plugins/marketplaces/hypt-claude/bin/hypt-vercel-bypass --prod 2>&1)
else
  BYPASS_URL=$(~/.claude/plugins/marketplaces/hypt-claude/bin/hypt-vercel-bypass 2>&1)
fi
BYPASS_EXIT=$?
echo "EXIT=$BYPASS_EXIT"
echo "URL=$BYPASS_URL"
```

**Handle exit codes:**

- **Exit 0** — bypass deployed successfully. `BYPASS_URL` contains the deployment URL. Report to the user:
  > **Deployed via CLI bypass** — Vercel's auto-deploy was blocked because the commit author isn't a seated team member. This is a known free-plan limitation and doesn't affect your app — everything deployed successfully.

  Carry the deployment URL forward to Step 2 for health verification — skip the deployment lookup steps and go straight to the health check.

- **Exit 1** — error. `BYPASS_URL` contains the error message (prefixed with `ERROR:`). Report the error to the user and stop.

- **Exit 2** — not blocked (no bypass needed). Continue to Step 2 normally.

---

### Step 2a: Feature branch (preview)

If the branch is NOT `main`:

1. Check for a PR:
   ```bash
   gh pr view --json number,url,statusCheckRollup 2>/dev/null
   ```
   If no PR exists, **skip to Step 2b** (production deploy). Ignore any local uncommitted or changed files — they are not relevant. The user just wants to verify that the latest `main` is deployed to production.

2. If a PR exists, ensure changes are pushed:
   ```bash
   git status --porcelain
   ```
   If there are unpushed commits or uncommitted changes, say:
   > You have uncommitted or unpushed changes. Run `/save` first, then try `/deploy` again.
   
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
   If the description matches the detection criteria from Step 1c (`TEAM_ACCESS`, `not a member`, or `contributing access`), run the bypass script (`~/.claude/plugins/marketplaces/hypt-claude/bin/hypt-vercel-bypass`), then health-check the bypass URL (step 6) and report (step 7). Do NOT re-enter Step 2a from the top.

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

Run this step if the branch IS `main`, OR if the branch is not `main` but has no PR (redirected from Step 2a).

1. Pull latest main. If not already on `main`, stash any local changes first so the checkout succeeds, then switch:
   ```bash
   git stash --include-untracked 2>/dev/null || true
   git fetch origin main && git checkout main && git pull origin main
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
   If the description matches the detection criteria from Step 1c (`TEAM_ACCESS`, `not a member`, or `contributing access`) — this is the team access block, not a code issue. Run the bypass script (`~/.claude/plugins/marketplaces/hypt-claude/bin/hypt-vercel-bypass --prod`), then health-check the bypass URL (step 4) and proceed directly to step 6 (report) with whatever result the bypass produced. Do NOT re-enter step 5 or Step 2b from the top — if the bypass health check fails, report it as unhealthy and stop.

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
