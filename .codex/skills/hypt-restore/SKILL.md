---
name: "hypt-restore"
description: "Restore app to a previous working version — rollback deployments, revert code, guide database recovery. Use when the user wants to rollback, revert, or restore the app to a previous working version, including `/restore`, `hypt:restore`."
metadata:
  short-description: "Restore to a Previous Working Version"
---
<!-- Generated from plugin/commands/restore.md. Do not edit by hand. Run `node scripts/sync-codex-support.mjs` instead. -->

# hypt-restore — Restore to a Previous Working Version

When this workflow needs repo-local helper binaries, resolve the repo root first:

```bash
REPO_ROOT="$(git rev-parse --show-toplevel)"
```
## Context

Before starting, gather context by running:

- Run `git branch --show-current` to capture Branch.

- Latest commit on main: `git log main --oneline -1 2>/dev/null || git log --oneline -1`
- Recent merges to main: `git log main --oneline --merges -5 2>/dev/null || echo "No merge history"`
- PR status: `gh pr view --json number,title,url,state 2>/dev/null || echo "No PR found"`
- Platform: `ls vercel.json .vercel/ 2>/dev/null && echo "PLATFORM=vercel"; ls netlify.toml _redirects 2>/dev/null && echo "PLATFORM=netlify"; ls fly.toml 2>/dev/null && echo "PLATFORM=fly"; ls render.yaml 2>/dev/null && echo "PLATFORM=render"; ls railway.json railway.toml 2>/dev/null && echo "PLATFORM=railway"; echo "done"`

## Instructions

This skill restores your app to a previous working version when something has gone wrong in production. It is designed for emergencies — when a recent deploy broke the site and you need to get back to what was working before.

**Default behavior:** Roll back to the last known-good deployment — typically the state of `main` before the most recent PR merge.

**If the user specifies a target:** Roll back to exactly what they ask for — a specific commit, PR, tag, or deployment.

---

### Step 1: Understand what to restore

Check if the user specified a target. The user might say:

- Nothing (default) — restore to the version before the latest merge/deploy
- A PR number — "restore to before PR #12"
- A commit SHA — "restore to abc1234"
- A tag or version — "restore to v0.5.0"
- A time reference — "restore to yesterday" or "restore to before this morning's deploy"
- "database" or "data" — they need database recovery guidance (skip to Step 6)

**If no target is specified (default):**

Find the last known-good commit on main — the merge commit before the most recent one:

```bash
# Get the two most recent merge commits on main (or regular commits if no merges)
git fetch origin main 2>/dev/null
MERGES=$(git log origin/main --oneline --merges -2 2>/dev/null)
if [ -z "$MERGES" ]; then
  # No merge commits — use regular commit history
  MERGES=$(git log origin/main --oneline -5 2>/dev/null)
fi
echo "$MERGES"
```

The second merge commit (or the commit before the latest) is the restore target. If you can only find one commit, tell the user there's no previous version to restore to.

**If a target is specified:**

Resolve it to a commit SHA:
```bash
# For PR number:
gh pr view <NUMBER> --json mergeCommit --jq '.mergeCommit.oid'

# For tag:
git rev-parse <TAG>

# For time reference — find the last deploy before that time:
git log origin/main --oneline --before="<DATE>" -1
```

**Present the restore target to the user before proceeding:**

```
Restore target identified:

  Current (broken):  <sha_short> — <message>
  Restore to:        <sha_short> — <message>
  Commits to revert: <count>

Proceeding with restore...
```

If the user is in a YOLO/pipeline context (autonomous mode), proceed immediately. Otherwise, ask: "Proceed with restore?" and wait for confirmation.

---

### Step 2: Detect deployment platform

Use the platform detected in the Context section. If no platform config was found, fall back to the GitHub Deployments API.

Route to the appropriate rollback method:
- **Vercel** → Step 3a
- **Netlify** → Step 3b
- **Fly.io** → Step 3c
- **Render / Railway** → Step 3d
- **GitHub Deployments (generic)** → Step 3e

---

### Step 3a: Vercel rollback

Vercel supports instant rollback to a previous deployment. This is the fastest path — no rebuild required.

**First, check for Vercel team access blocks** (free plan limitation). Run the bypass script:

```bash
BYPASS_URL=$("$REPO_ROOT"/bin/hypt-vercel-bypass --prod 2>&1)
BYPASS_EXIT=$?
echo "EXIT=$BYPASS_EXIT"
echo "URL=$BYPASS_URL"
```

Handle exit codes:
- **Exit 0** — bypass deployed successfully. Use `BYPASS_URL` as the production URL and skip to Step 5 (health check). Report: "Deployed via CLI bypass — Vercel's auto-deploy was blocked because the commit author isn't a seated team member."
- **Exit 1** — error. Report the error and fall through to manual steps below.
- **Exit 2** — not blocked. Continue with normal Vercel rollback below.

Check if the Vercel CLI is available:
```bash
command -v vercel >/dev/null 2>&1 && echo "VERCEL_CLI=true" || echo "VERCEL_CLI=false"
```

**If Vercel CLI is available:**

List recent production deployments and find the deployment URL matching the restore target:
```bash
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
gh api "repos/$REPO/deployments?environment=Production&per_page=5" \
  --jq '.[] | "\(.id) \(.sha[0:7]) \(.created_at) \(.description // "no description")"'
```

Get the deployment URL for the restore target:
```bash
# Find the deployment ID matching the restore target SHA
TARGET_DEPLOY_ID=$(gh api "repos/$REPO/deployments?environment=Production&per_page=5" \
  --jq ".[] | select(.sha | startswith(\"$RESTORE_TARGET_SHA\")) | .id" 2>/dev/null | head -1)
TARGET_DEPLOY_URL=$(gh api "repos/$REPO/deployments/$TARGET_DEPLOY_ID/statuses" \
  --jq '.[0].target_url // empty' 2>/dev/null)
```

If the deployment URL was found, promote it:
```bash
vercel promote "$TARGET_DEPLOY_URL" --yes 2>&1
PROMOTE_EXIT=$?
if [ "$PROMOTE_EXIT" -ne 0 ]; then
  echo "PROMOTE_FAILED — falling back to git revert"
fi
```

If `vercel promote` fails or no deployment URL was found, fall through to Step 4 (git revert).

**If Vercel CLI is NOT available, guide the user:**

> **Quick Vercel rollback (no CLI needed):**
> 1. Go to your Vercel dashboard → **Deployments**
> 2. Find the deployment from **<restore_target_date>** (commit `<sha_short>`)
> 3. Click the **"..."** menu → **Promote to Production**
> 4. This takes effect instantly — no rebuild needed
>
> Or I can do a git revert instead (creates a new commit that undoes the changes). Want me to proceed with that?

If the user wants the git revert, proceed to Step 4. After successful Vercel rollback, skip to Step 5 (health check).

---

### Step 3b: Netlify rollback

Netlify keeps every deploy and supports instant rollback from the dashboard.

> **Netlify rollback:**
> 1. Go to your Netlify dashboard → **Deploys**
> 2. Find the deploy from **<restore_target_date>** (commit `<sha_short>`)
> 3. Click into it → **Publish deploy**
> 4. This takes effect instantly
>
> Or I can do a git revert to roll back the code. Want me to proceed with that?

If the user wants the git revert, proceed to Step 4. Otherwise skip to Step 5.

---

### Step 3c: Fly.io rollback

Fly.io supports releasing a previous machine image:

```bash
fly releases -a <app-name> 2>/dev/null | head -10
```

If Fly CLI is available and releases are visible, guide the user to the right release. Otherwise, fall through to Step 4 (git revert).

---

### Step 3d: Render / Railway rollback

These platforms auto-deploy from git. The fastest restore path is a git revert.

Tell the user:
> Render/Railway auto-deploys from git. I'll revert the code on main, which will trigger a new deploy with the previous working version.

Proceed to Step 4.

---

### Step 3e: Generic / GitHub Deployments

For unknown platforms, use the git revert approach (Step 4).

---

### Step 4: Git revert (universal fallback)

This creates a new commit on `main` that undoes the problematic changes. It is safe — no history is rewritten.

```bash
# Stash any local changes
STASH_COUNT_BEFORE=$(git stash list 2>/dev/null | wc -l)
git stash --include-untracked 2>/dev/null || true
STASH_COUNT_AFTER=$(git stash list 2>/dev/null | wc -l)
if [ "$STASH_COUNT_AFTER" -gt "$STASH_COUNT_BEFORE" ]; then
  RESTORE_STASHED=true
else
  RESTORE_STASHED=false
fi

ORIGINAL_BRANCH=$(git branch --show-current)

# Switch to main and pull latest
git checkout main 2>/dev/null
git pull origin main 2>/dev/null
```

Now revert the problematic commits. First, determine the revert strategy by checking if the commit is a merge commit:

```bash
# Check if the target commit to revert is a merge commit
PARENT_COUNT=$(git cat-file -p HEAD | grep -c "^parent")
echo "PARENT_COUNT=$PARENT_COUNT"
```

Choose the right revert strategy:
- **If reverting a single merge commit** (`PARENT_COUNT >= 2`): use `git revert -m 1 <sha> --no-edit`
- **If reverting a single regular commit** (squash merge or direct commit, `PARENT_COUNT == 1`): use `git revert <sha> --no-edit` (no `-m` flag)
- **If reverting multiple commits**: revert them one at a time from newest to oldest

```bash
# For a single merge commit:
git revert -m 1 "$REVERT_SHA" --no-edit

# For a single regular commit (squash merge):
git revert "$REVERT_SHA" --no-edit

# For multiple commits — revert newest to oldest:
git revert --no-edit "$NEWEST_SHA"
git revert --no-edit "$NEXT_SHA"
# ... etc
```

**If the revert has conflicts** (non-zero exit code):

```bash
REVERT_EXIT=$?
if [ "$REVERT_EXIT" -ne 0 ]; then
  CONFLICT_FILES=$(git diff --name-only --diff-filter=U 2>/dev/null)
  echo "CONFLICT_FILES:"
  echo "$CONFLICT_FILES"
fi
```

1. Check which files are conflicted
2. For simple conflicts (non-overlapping changes), resolve them by editing the file to keep the reverted version, then `git add <file>` and `git revert --continue`
3. If conflicts are complex, abort and tell the user:
   ```bash
   git revert --abort
   ```
   > The revert has merge conflicts that need manual resolution. Conflicting files: <list>
   >
   > Want me to try to resolve these, or would you prefer to handle it?

After successful revert, push to main:

```bash
git push origin main 2>&1
PUSH_EXIT=$?
if [ "$PUSH_EXIT" -ne 0 ]; then
  echo "PUSH_FAILED"
fi
```

**If push fails**, report the error to the user and stop. Do NOT proceed to health check — the revert is not live. Common causes: branch protection rules, network issues, or authentication problems.

Then restore the user's working state:

```bash
if ! git checkout "$ORIGINAL_BRANCH" 2>/dev/null; then
  echo "WARNING: Could not switch back to $ORIGINAL_BRANCH"
fi
if [ "$RESTORE_STASHED" = "true" ]; then
  git stash pop 2>/dev/null || echo "WARNING: Could not restore stashed changes"
fi
```

---

### Step 5: Health check

Wait for the new deployment to complete, then verify the site is up.

```bash
# Get the production URL
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
DEPLOY_ID=$(gh api "repos/$REPO/deployments?environment=Production&per_page=1" --jq '.[0].id // empty' 2>/dev/null)
PROD_URL=$(gh api "repos/$REPO/deployments/$DEPLOY_ID/statuses" --jq '.[0].target_url // empty' 2>/dev/null)
```

**If no production URL found**, check for a homepage in package.json or vercel.json:
```bash
if [ -z "$PROD_URL" ]; then
  PROD_URL=$(node -e "try { const p = require('./package.json'); console.log(p.homepage || ''); } catch(e) {}" 2>/dev/null)
fi
if [ -z "$PROD_URL" ]; then
  PROD_URL=$(node -e "try { const v = require('./vercel.json'); console.log(v.alias?.[0] || ''); } catch(e) {}" 2>/dev/null)
fi
```

If still no URL found, report "Production URL not found — check your deployment platform dashboard" and skip the health check.

**If a URL was found**, poll until the deployment is healthy (up to 2 minutes):

```bash
for i in $(seq 1 8); do
  HTTP_CODE=$(curl -sL -o /dev/null -w "%{http_code}" "$PROD_URL" 2>/dev/null)
  echo "Attempt $i: HTTP $HTTP_CODE"
  if [ "$HTTP_CODE" = "200" ]; then
    echo "HEALTHY"
    break
  fi
  if [ "$i" -lt 8 ]; then
    sleep 15
  fi
done
```

A `200` means healthy. If still not `200` after 8 attempts, report the last status code — the deployment may need more time or there may be a deeper issue.

---

### Step 6: Database restoration guidance

Provide this step if:
- The user specifically asked about data or database restoration
- The reverted commits contained migration files

**Check if reverted commits contained migrations:**
```bash
git diff --name-only <restore_target_sha>..HEAD -- "**/migrations/**" "**/migrate/**" "supabase/migrations/**" "prisma/migrations/**" "drizzle/**" 2>/dev/null
```

**Supabase database restoration:**

> **Supabase Database Recovery**
>
> Supabase provides Point-in-Time Recovery (PITR) on Pro plans and daily backups on all paid plans.
>
> **Option 1 — Dashboard restore (easiest):**
> 1. Go to your Supabase dashboard → **Database** → **Backups**
> 2. For PITR (Pro plan): Choose a timestamp before the bad deploy hit production
> 3. For daily backups: Choose the most recent backup before the issue
> 4. Click **Restore** — this replaces your current database with the backup
>
> **Option 2 — Download and inspect first:**
> 1. Go to **Database** → **Backups** → **Download** the backup
> 2. Review what changed before restoring
> 3. You can restore to a new project first to verify the backup looks right
>
> **Option 3 — Selective table restore (if only some tables were affected):**
> 1. Download the backup
> 2. Use `pg_restore --table=<table_name>` to restore specific tables
> 3. This avoids overwriting data in unaffected tables
>
> **Important:** If the reverted code ran migrations that created new tables or columns, those still exist in your database after the code revert. You may need to manually drop them or run a down migration if they cause issues.

**Generic database restoration (non-Supabase):**

Check for database config:
```bash
ls prisma/schema.prisma drizzle.config.* knexfile.* 2>/dev/null
```

> **Database Recovery Notes**
>
> The code has been reverted, but database changes (migrations, data modifications) are NOT automatically rolled back. If the reverted code included:
>
> - **Schema migrations** — Check if your ORM supports down migrations. For Prisma: `npx prisma migrate resolve` to mark migrations as rolled back. For Drizzle/Knex: run the down migration.
> - **Data modifications** — Restore from your database provider's backup system.
> - **New tables or columns** — These persist after a code revert. Drop them manually if they cause issues, or leave them if they're harmless.

---

### Step 7: Report

**Successful restore:**
```
Restore complete
────────────────
Restored to:  <sha_short> — <message>
Method:       <Vercel promotion / Netlify publish / Git revert>
Platform:     <detected platform>
Production:   <healthy (HTTP 200) / deploying... / URL not found>
URL:          <production_url>
Working tree: <restored on <branch> / clean>
```

If database guidance was provided, add:
```
Database:     Code reverted — see database recovery notes above
```

**If health check failed:**
```
Restore complete (with warnings)
─────────────────────────────────
Restored to:  <sha_short> — <message>
Method:       Git revert (pushed to main)
Production:   HTTP <code> — site may still be deploying

Check again in a few minutes with /status.
If the site is still down, the issue may predate this deploy.
```

**If restore failed:**
```
Restore failed
──────────────
Attempted:    Revert to <sha_short>
Error:        <what went wrong>

Next steps:
- Try specifying a different restore target: /restore <sha or PR number>
- Check the deployment logs on your platform's dashboard
- If data was affected, check your database backups immediately
```

Always end with a reassuring note for non-technical users when the restore succeeded:

> Your site has been restored to the previous working version. The broken changes have been safely reverted — no data was lost from the revert itself. If you need to re-attempt the feature that caused the issue, start a new branch and try again with `/go` or `/yolo`.
