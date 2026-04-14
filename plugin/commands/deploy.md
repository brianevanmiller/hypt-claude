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

Run this step if the branch IS `main`, OR if the branch is not `main` but has no PR (redirected from Step 2a).

1. Pull latest main. If not already on `main`, stash any local changes first so the checkout succeeds, then switch:
   ```bash
   git stash --include-untracked 2>/dev/null || true
   git fetch origin main && git checkout main && git pull origin main
   ```

2. Find the latest production deployment using the detected platform:

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

   Investigate the build error. Check deployment logs if available:
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
