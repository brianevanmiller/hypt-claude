---
name: "hypt-status"
description: "Quick deployment status check — is my site up? Read-only, no fixes attempted. Use when the user wants a read-only deployment status check, including `/status`, `hypt:status`."
metadata:
  short-description: "Deployment Status"
---
<!-- Generated from plugin/commands/status.md. Do not edit by hand. Run `node scripts/sync-codex-support.mjs` instead. -->

# hypt-status — Deployment Status

## Context

Before starting, gather context by running:

- Run `git branch --show-current` to capture Branch.

- Latest commit: `git log --oneline -1`
- PR status: `gh pr view --json number,title,url,state 2>/dev/null || echo "No PR found"`

## Instructions

This is a **read-only** status check. Do NOT modify files, switch branches, stash changes, create PRs, or attempt fixes. Just report what you see.

### Step 1: Detect deployment platform

Check for deployment platform indicators in this order:

```bash
ls vercel.json .vercel/ 2>/dev/null && echo "PLATFORM=vercel"
ls netlify.toml _redirects 2>/dev/null && echo "PLATFORM=netlify"
ls fly.toml 2>/dev/null && echo "PLATFORM=fly"
ls render.yaml 2>/dev/null && echo "PLATFORM=render"
ls railway.json railway.toml 2>/dev/null && echo "PLATFORM=railway"
```

Use the first match. If no config file is found, fall back to the **GitHub Deployments API**.

---

### Step 2: Check production deployment

Look up the latest production deployment regardless of current branch:

**Vercel:**
```bash
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
gh api "repos/$REPO/deployments?environment=Production&per_page=1" --jq '.[0] | {id, sha, created_at, description}'
```

**Netlify / Generic:**
```bash
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
gh api "repos/$REPO/deployments?per_page=1" --jq '.[0] | {id, sha, environment, created_at, description}'
```

Then get the deployment status:
```bash
gh api "repos/$REPO/deployments/<DEPLOYMENT_ID>/statuses" --jq '.[0] | {state, target_url, description}'
```

If no deployments are found at all, report "No deployments found" and skip to the summary.

---

### Step 3: Health check

If a production URL was found (`target_url` from the deployment status, or `environment_url`):

```bash
curl -sL -o /dev/null -w "%{http_code}" "<PRODUCTION_URL>"
```

A `200` means healthy. Any other status code — report it but do NOT attempt to fix.

---

### Step 4: Check preview deployment (if on a feature branch with a PR)

If the current branch is NOT `main` and a PR exists:

```bash
gh pr checks --json name,state,link --jq '.[] | select(.name | test("vercel|Vercel|netlify|Netlify|deploy|Deploy"; "i"))'
```

Or via the GitHub Deployments API:
```bash
SHA=$(git rev-parse HEAD)
gh api "repos/$REPO/deployments?sha=$SHA&per_page=1" --jq '.[0] | {id, environment, created_at}'
```

Then get status and health check the preview URL the same way as production.

---

### Step 5: Report

Print a clean summary. Keep it simple — this is designed for non-technical users.

**If production only:**
```
Site Status
───────────
Production: ✓ Live (HTTP 200)
URL:        <production_url>
Platform:   <detected platform>
Last deploy: <relative time, e.g. "2 hours ago">
Commit:     <short sha> — <message>
```

**If production is unhealthy:**
```
Site Status
───────────
Production: ✗ Down (HTTP <code>)
URL:        <production_url>
Platform:   <detected platform>
Last deploy: <relative time>
Commit:     <short sha> — <message>

Run /deploy for diagnosis and auto-fix.
```

**If there's also a preview:**
```
Site Status
───────────
Production: ✓ Live (HTTP 200)
URL:        <production_url>

Preview:    ✓ Live (HTTP 200)  — PR #<number>
URL:        <preview_url>

Platform:   <detected platform>
Last deploy: <relative time>
```

**If a deployment is pending or in progress**, report it as-is without polling:
```
Production: ⏳ Deploying...
```

**If no deployments found:**
```
Site Status
───────────
No deployments found for this repository.

Run /deploy to set up and verify your first deployment.
```

When something is unhealthy, always end with: `Run /deploy for diagnosis and auto-fix.`
