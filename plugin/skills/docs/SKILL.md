---
name: docs
description: >
  Scan and update project documentation — check off completed items, update
  README tables, feature docs, dates, and references. Used by /pipeline and /close,
  or standalone via "update docs".
allowed-tools: ["Bash", "Read", "Edit", "Write", "Grep", "Glob"]
version: "1.0.0"
author: "Brian Miller"
license: "MIT"
---

# hypt:docs — Documentation Updater

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
- PR status: !`gh pr view --json number,title,body,files --jq '{number, title, body, files: [.files[].path]}' 2>/dev/null || echo "NO_PR"`
- Recent commits on branch: !`git log main..HEAD --oneline --no-merges 2>/dev/null || git log --oneline -10 2>/dev/null`
- Files changed vs main: !`git diff main..HEAD --name-only 2>/dev/null || echo "No diff"`
- Documentation files: !`find . -maxdepth 4 -name "*.md" -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./.context/*" -not -path "./thoughts/*" 2>/dev/null | head -20`
- Files with unchecked items: !`find . -maxdepth 4 -name "*.md" -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./.context/*" -print0 2>/dev/null | xargs -0 grep -l -- "\- \[ \]" 2>/dev/null | head -10`

## Instructions

This skill scans project documentation and updates it to reflect the current branch/PR changes. It handles checklist completion, README/feature doc updates, and date/status refreshes.

This skill complements `/touchup` Step 5 (which does a lightweight reactive doc pass on `docs/` files). The docs skill is a structured, proactive pass across all known doc types.

**Important:** This skill does NOT update CHANGELOG.md with version entries — that is autoclose's responsibility during version bump. It does NOT generate new documentation for undocumented features. It does NOT touch auto-generated files (like AGENTS.md).

**Date-prefixed document convention:** Some document types use `YYYY-MM-DD-<topic>.md` naming (e.g., `docs/post-mortem/2026-04-16-broken-auth-post-mortem.md`). When scanning for docs to update, recognize this pattern and treat the date prefix as metadata — match against the topic portion for semantic relevance.

---

### Step 1: Gather context — what was shipped

Build a picture of what this branch/PR changed. Adapt based on what's available:

**If a PR exists** (Context shows PR number/title/body):
- Use the PR title, body, and file list as the primary source
- Supplement with commit messages

**If no PR exists** (Context shows NO_PR):
- Use the git diff and commit messages as the primary source:
```bash
git diff main..HEAD --stat 2>/dev/null
git log main..HEAD --oneline --no-merges 2>/dev/null
```

Summarize in one sentence what was shipped — this guides all subsequent doc updates.

---

### Step 2: Check off completed checklist items

Scan all documentation files that contain unchecked items (`- [ ]`). The Context section lists them above.

**For each file with unchecked items**, read it and compare each `- [ ]` item against:
- The PR title and body (if available)
- The commit messages on this branch
- The list of files changed

An item is considered **completed** if:
- The PR title or body explicitly references it (e.g., PR "add dark mode" matches `- [ ] Add dark mode support`)
- The commits clearly implement what the item describes
- The files changed correspond directly to the item's scope

**Use semantic matching** — don't require exact string matches. For example:
- PR "feat: add user authentication" matches `- [ ] User auth / login flow`
- PR "fix: resolve email validation bug" matches `- [ ] Fix email validation edge cases`
- Commit "add /docs command" matches `- [ ] Add a /docs or documentation update skill`

**Check off matched items** by changing `- [ ]` to `- [x]` using the Edit tool.

Common files to check:
- `docs/todos/backlog.md` — project backlog
- `TODOS.md` or `TODO.md` — root-level to-dos
- `docs/roadmap.md` — project roadmap
- `thoughts/todo.md` — working plans
- Any other `.md` file with `- [ ]` items

If no items match, move on silently.

---

### Step 3: Update README and skill/command tables

Check if the PR added or modified any user-facing features that should be reflected in the README.

**Triggers for README update:**
- A new skill file was created in `plugin/skills/*/SKILL.md`
- A new command file was created in `plugin/commands/*.md`
- An existing skill's description was significantly changed
- New CLI tools, API endpoints, or configuration options were added
- Supported platforms, requirements, or installation steps changed

**If a trigger is detected:**

1. Read the relevant README(s):
   - Root `README.md` — user-facing, has command table and workflow diagram
   - `plugin/README.md` — contributor-facing, has skills table

2. Update the command/skill tables to include new entries or reflect changed descriptions.

3. If the workflow diagram needs updating (new skill changes the typical flow), update it.

**If no triggers apply**, skip this step silently.

---

### Step 4: Update feature documentation

Check if any documentation in `docs/` describes features or systems that were modified by this PR.

**For each `.md` file in `docs/` (excluding `docs/todos/`):**
1. Read the file
2. Check if the PR changed code, schemas, APIs, or behavior that this doc describes
3. If yes: update the doc to reflect the current state — fix outdated descriptions, add new sections for added functionality, remove references to deleted features

**For skill and command files** (`plugin/skills/*/SKILL.md`, `plugin/commands/*.md`):
- If the PR modified a skill's behavior, check that its SKILL.md description still matches
- If frontmatter `description` is outdated, update it

**If no feature docs need updating**, skip this step silently.

---

### Step 5: Update dates and status indicators

Scan documentation for date references and status indicators that should be refreshed:

**Dates:**
- If a checklist item was just checked off and has an associated date (e.g., "Target: Q2 2026"), leave it as-is (it's a target, not a last-updated)
- If a doc has a "Last updated: YYYY-MM-DD" header or footer and was modified in this run, update it to today's date
- Do NOT update version dates in CHANGELOG.md (autoclose's job)

**Status indicators:**
- If a doc or section says "Status: in progress" or "Status: planned" and the PR completed that work, update to "Status: complete" or "Status: shipped"
- If a README badge or status line references a feature that was just added, ensure it's accurate

**Reference links:**
- If the PR renamed or moved files that are linked from other docs, update the links
- Quick check: find markdown links `[text](path)` where `path` points to a repo file that was renamed/moved in this PR

**If nothing needs updating**, skip this step silently.

---

### Step 6: Commit documentation changes

Check if any files were modified in Steps 2-5:

```bash
git status --short -- docs/ plugin/ README.md TODOS.md TODO.md thoughts/todo.md
```

**If changes exist**, commit them:
```bash
git add -- docs/ plugin/ README.md TODOS.md TODO.md thoughts/todo.md 2>/dev/null
git diff --cached --quiet || git commit -m "docs: update documentation for PR changes"
git push -u origin HEAD 2>/dev/null || true
```

**If no changes were made**, skip the commit silently.

---

### Step 7: Summary

Print a brief summary:

```
Docs updated:
- Completed items: <N items checked off across M files, or "none">
- README: <updated / no changes needed>
- Feature docs: <list of updated files, or "no changes needed">
- Dates/status: <updated / no changes needed>
```

If nothing was changed at all:

```
Docs: no updates needed — documentation is current.
```
