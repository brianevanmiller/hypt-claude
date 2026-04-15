---
name: "hypt-touchup"
description: "Quick pre-merge polish — fix PR comments, build issues, and update docs. Use when the user wants quick polish before merge, including PR feedback, docs, and build fixes, including `/touchup`, `hypt:touchup`."
metadata:
  short-description: "Quick Pre-Merge Polish"
---
<!-- Generated from plugin/skills/touchup/SKILL.md. Do not edit by hand. Run `node scripts/sync-codex-support.mjs` instead. -->

# hypt-touchup — Quick Pre-Merge Polish

## Context

Before starting, gather context by running:

- Run `git branch --show-current` to capture Branch.

- Changes in this PR: `git diff main...HEAD --stat 2>/dev/null || git diff origin/main...HEAD --stat 2>/dev/null || echo "No diff against main"`
- PR info: `gh pr view --json number,url,title 2>/dev/null || echo "No PR found"`

## Instructions

This is a quick polish pass. Address PR feedback first, then catch build-breakers, update docs, and do a light review.

### Step 1: Address PR comments

Pull all comments on the PR (human reviewers and bots):

```bash
gh pr view --json comments,reviews --jq '.comments[].body, .reviews[].body' 2>/dev/null
```

Also check for review comments on specific lines:

```bash
gh api repos/{owner}/{repo}/pulls/{number}/comments --jq '.[] | "[\(.path):\(.line // .original_line)] \(.body)"' 2>/dev/null
```

For each comment or review item:
1. **Critical / blocking items** (requested changes, failing checks, "must fix"): fix these immediately. These are holding up the merge.
2. **Trivial / low-risk items** (typos, naming suggestions, small style fixes, missing docs): fix these too — they're quick wins.
3. **Opinionated / debatable items** (architecture disagreements, "consider refactoring"): skip these — they need discussion, not a quick fix.

After addressing comments, commit:
```bash
git add -A && git commit -m "fix: address PR review comments" && git push
```

If no comments needed fixing, skip the commit.

### Step 2: Light PR review

Do a quick scan of the diff — NOT a deep review, just a fast pass for obvious problems:

```bash
git diff main...HEAD 2>/dev/null || git diff origin/main...HEAD 2>/dev/null
```

Look for:
- **Build breakers**: missing imports, syntax errors, unresolved merge conflicts
- **Obvious bugs**: typos in variable names, copy-paste errors, accidentally commented-out code
- **Security red flags**: hardcoded secrets, `dangerouslySetInnerHTML` with user input, exposed API keys
- **Broken functionality**: components referencing deleted files, broken route paths

Fix anything you find. Don't refactor, don't improve style, don't add features.

### Step 3: Type check and build

If the project uses TypeScript (check for `tsconfig.json`):
```bash
bunx tsc --noEmit 2>&1
```
If there are type errors, fix them minimally.

Run the project's build command:
```bash
bun run build 2>&1
```

If the build fails, fix the specific errors (not warnings).

### Step 4: Commit fixes

If any files were changed in steps 2-3:
```bash
git add -A && git commit -m "chore: touchup — fix build issues" && git push
```

If nothing needed fixing, skip this step.

### Step 5: Update documentation

1. Find all markdown docs:
   ```bash
   find docs/ -name "*.md" -type f 2>/dev/null
   ```

2. Get the full PR diff to understand what changed:
   ```bash
   git diff main...HEAD 2>/dev/null || git diff origin/main...HEAD 2>/dev/null
   ```

3. For each markdown doc in `docs/`:
   - Read the doc
   - Check if any changes in the PR affect what the doc describes (features, architecture, schemas, API routes, database tables, flows)
   - If yes: update the doc to reflect the current state
   - If no: skip it

4. If any docs were updated:
   ```bash
   git add docs/ && git commit -m "docs: update documentation for PR changes" && git push
   ```

### Step 6: Confirm ready

Print a summary:

```
Touchup complete!
- PR comments addressed: X items fixed, Y skipped (need discussion)
- Build issues fixed: X
- Docs updated: [list of files, or "none needed"]
- PR is ready for merge.
```
