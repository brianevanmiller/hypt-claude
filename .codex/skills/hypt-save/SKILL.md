---
name: "hypt-save"
description: "Save all changes — commit, push, and create/update PR automatically. Use when the user wants to commit, push, or create or update a PR, including `/save`, `hypt:save`."
metadata:
  short-description: "Commit, Push, Create PR"
---
<!-- Generated from plugin/commands/save.md. Do not edit by hand. Run `node scripts/sync-codex-support.mjs` instead. -->

# hypt-save — Commit, Push, Create PR

## Context

Before starting, gather context by running:

- Run `git status` to capture Current status.

- Changes: `git diff --stat`
- Branch: `git branch --show-current`

## Instructions

Do everything in a single pass. No questions, no confirmations.

### Step 1: Check for changes

If the working tree is clean (no modified, untracked, or staged files), say:
> Nothing to save — working tree is clean.

And stop.

### Step 1b: Pull latest main and rebase

Fetch the latest `main` and rebase the current branch on top of it:

```bash
git fetch origin main
git rebase origin/main
```

If the rebase hits conflicts:
1. Check which files are conflicted: `git diff --name-only --diff-filter=U`
2. For each conflicted file, read the conflict markers
3. **Trivial conflicts** (non-overlapping changes, whitespace, import ordering, additive changes to different sections of the same file): resolve them by editing the file to keep both sides, then `git add <file>`
4. **Non-trivial conflicts** (same lines changed differently, logic conflicts, architectural disagreements): abort the rebase and tell the user:
   > Merge conflict in `<file>` — this needs manual resolution. Rebase aborted.
   
   ```bash
   git rebase --abort
   ```
   And stop.
5. After resolving all trivial conflicts: `git rebase --continue`

### Step 2: Commit

1. Stage everything: `git add -A`
2. Read the full diff: `git diff --cached`
3. Write a clear, concise commit message based on what actually changed. Use conventional commit format:
   - `feat:` for new features
   - `fix:` for bug fixes
   - `chore:` for maintenance
   - `docs:` for documentation
   - `style:` for formatting
4. Commit. Use a HEREDOC for the message to handle multi-line properly.

### Step 3: Push

```bash
git push -u origin HEAD
```

If push fails because the remote branch doesn't exist yet, this command handles it automatically with `-u`.

### Step 4: Create or find PR

Check if a PR already exists for this branch:
```bash
gh pr view --json number,url 2>/dev/null
```

- If no PR exists: create one:
  ```bash
  gh pr create --fill
  ```
  This auto-fills the title from the branch name and body from commit messages.

### Step 5: Update PR description

Whether the PR was just created or already existed, update the description to reflect all changes on the branch.

**Gather the full picture:**
```bash
# All commits on this branch vs main
git log origin/main..HEAD --oneline --no-merges
# Summary of all files changed
git diff origin/main..HEAD --stat
```

**Generate an updated PR body** from all commits on the branch (not just the latest). Use this format:

```
## Summary
<2-4 bullet points summarizing what this PR does overall, written from the user's perspective>

## Changes
<one bullet per commit, concise>

---
🤖 Generated with Codex
```

**Update the PR:**
```bash
gh pr edit --body "$(cat <<'EOF'
<generated body>
EOF
)"
```

Also update the PR title if the current title is just the branch name or doesn't reflect the changes well. Use:
```bash
gh pr edit --title "<better title>"
```

### Step 6: Summary

Print a short summary:
```
Saved! 
- Commit: <short hash> — <message>
- Branch: <branch name>
- PR: <url>
```

That's it. Done.
