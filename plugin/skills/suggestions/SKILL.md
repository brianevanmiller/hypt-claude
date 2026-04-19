---
description: "Suggest next tasks and track them in your project backlog"
allowed-tools: ["Bash", "Read", "Edit", "Write", "Grep", "Glob", "Skill"]
---

# /suggestions — Suggest Next Tasks and Update Backlog

## Preamble (run silently before the skill)

```bash
_UPD=$(~/.claude/plugins/marketplaces/hypt-builder/bin/hypt-update-check 2>/dev/null || true)
echo "${_UPD:-UP_TO_DATE}"
GSTACK_AVAILABLE=$(test -f ~/.claude/skills/gstack/SKILL.md && echo "true" || echo "false")
echo "GSTACK: $GSTACK_AVAILABLE"
```

- If output contains `UPGRADE_AVAILABLE <old> <new>`: Silently run `bash ~/.claude/plugins/marketplaces/hypt-builder/install.sh` then briefly tell the user: "hypt updated to v{new}. Restart Claude Code when convenient to use the latest version." Then continue with the skill normally.
- If output contains `JUST_UPGRADED <old> <new>`: Briefly say "Running hypt v{new} (updated from v{old})." then continue.
- Otherwise: continue silently — say nothing about updates.
- `GSTACK` line: note silently whether gstack is available. Do not mention this to the user.

## Context

- Branch: !`git branch --show-current`
- PR info: !`gh pr view --json title,body,number,url 2>/dev/null || echo "No PR found"`
- Changes in this PR: !`git diff main...HEAD --stat 2>/dev/null || git diff origin/main...HEAD --stat 2>/dev/null || echo "No diff against main"`
- Tracking files: !`find . -maxdepth 3 -iname "*.md" \( -iname "*todo*" -o -iname "*backlog*" -o -iname "*roadmap*" -o -iname "*tasks*" \) -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./.codex/*" 2>/dev/null | head -10 || echo "None found"`

## Instructions

This skill analyzes the current PR and project state, then suggests prioritized next tasks. Optionally tracks them in `docs/todos/backlog.md` so nothing falls through the cracks.

### Step 1: Check user preference

```bash
~/.claude/plugins/marketplaces/hypt-builder/bin/hypt-config get suggestions_auto_backlog
```

- If the value is `skip`: **stop here** — return immediately with no output. The user has opted out of suggestions during `/close`.
- If the value is `auto`: continue to Step 2, but skip the interactive picker in Step 4 — auto-add all suggestions.
- If the value is `ask`, empty, or missing: this is a first-time user or one who chose "always ask." Continue interactively.

### Step 2: Gather context

Analyze these sources to understand what was built and what might come next:

1. **Current PR** — use the title, body, and files changed from the Context section above. If no PR exists, use the branch name and recent commit messages (`git log --oneline -10`) to understand what was built.
2. **All tracking files** — read every file listed in "Tracking files" from the Context section. This includes `docs/todos/backlog.md`, `TODOS.md`, `TODO.md`, `roadmap.md`, `tasks.md`, or any other markdown tracking file the user has. Collect all unchecked items (`- [ ]`) from every file. Note what's already tracked so you don't suggest duplicates.
3. **Open GitHub issues:**
   ```bash
   gh issue list --limit 10 --json number,title,labels 2>/dev/null
   ```
4. **Code-level signals** — look for TODOs, FIXMEs, and hacks added in this PR:
   ```bash
   (git diff main...HEAD 2>/dev/null || git diff origin/main...HEAD 2>/dev/null) | grep -E '^\+.*\b(TODO|FIXME|HACK|XXX)\b' || true
   ```
5. **Missing test coverage** — check if files changed in the PR have corresponding test files:
   ```bash
   (git diff main...HEAD --name-only 2>/dev/null || git diff origin/main...HEAD --name-only 2>/dev/null) | grep -E '\.(ts|tsx|js|jsx)$' | grep -v '\.test\.' | grep -v '\.spec\.' || true
   ```

### Step 3: Generate suggestions

Based on everything gathered, build a combined list of suggestions. Include:

- **Existing unchecked items** from all tracking files (these are user-specified priorities — always include them)
- **New suggestions** based on PR analysis, code signals, and missing coverage (3-5 additional items)

Each suggestion needs:

- **A one-sentence description** in plain language (no jargon)
- **A category** — one of: `Security`, `Bugs`, `Features`, `Performance`, `Testing`, `Documentation`, `Cleanup`
- **A brief "why now"** — connect it to what was just built so the user understands the reasoning
- **Source** — mark items from tracking files as `(from backlog)`, `(from TODOS.md)`, etc. so the user knows which are their own items vs new suggestions

**Priority order when choosing what to suggest:**
1. Security gaps (auth, permissions, input validation, data protection)
2. Bugs or issues found during analysis
3. Natural follow-on features from what was just built
4. Performance improvements
5. Missing test coverage
6. Documentation gaps
7. Code cleanup and tech debt

**Grouping:** Before presenting, group related items together — especially smaller items in the same domain of work. For example:

- Multiple search-related items → group as "Search improvements"
- Multiple test items for the same area → group as "Test coverage for [area]"
- Multiple doc updates → group as "Documentation updates"

Grouped items should be presented as a single numbered entry with sub-items, and can be tackled together in one session. Only group items that genuinely belong together — don't force unrelated items into groups.

Only suggest things that are genuinely useful. Don't pad the list with generic advice.

### Step 4: Present suggestions

Show the suggestions in a friendly, approachable format. Group related items together visually:

```
Nice work! Here are some things to tackle next:

1. [Plain-language description] (category)
   [One sentence explaining why this makes sense now]

2. [Group name] (category) — tackle together
   a. [Sub-item 1]
   b. [Sub-item 2]
   c. [Sub-item 3]
   [One sentence explaining why these go together]

3. [Plain-language description] (category) (from backlog)
   [One sentence explaining why this makes sense now]

---

**Want to start on any of these?**
- Pick a number to add to your backlog
- Say "go 1" or "yolo 2" to start working on it right now
- "all" to add everything to the backlog, or "none" to skip
```

**If the user picks a number with "go" or "yolo":** Invoke the corresponding skill immediately.

- `"go 1"` or `"go mode on 1"` → Invoke the Skill tool with skill: "hypt:go" and pass the selected item description as the argument
- `"yolo 2"` or `"yolo it"` → Invoke the Skill tool with skill: "hypt:yolo" and pass the selected item description as the argument
- `"pipeline 3"` → Invoke the Skill tool with skill: "hypt:pipeline" and pass the selected item description as the argument

After invoking the skill, stop — the invoked skill handles everything from there.

**If the user just picks numbers (like "1, 3"):** Add those items to the backlog (proceed to Step 5).

**If the user's preference is `auto`:** skip the question entirely. Print the suggestions briefly and proceed to add all of them to the backlog:

```
Here's what I'm adding to your backlog:

1. [Description] (category)
2. [Description] (category)
3. [Description] (category)
```

Wait for the user's response before continuing (unless auto mode).

### Step 5: Update backlog

If the user said "none", skip this step entirely and jump to Step 6.

**If `docs/todos/backlog.md` does not exist:**

Create it from this template:

```bash
mkdir -p docs/todos
```

Write the file with this content:

```markdown
# Backlog

What to work on next — updated automatically by `/todo` and `/close`. Feel free to edit, reorder, or check things off.

## Security
<!-- Auth, permissions, data protection, input validation -->

## Bugs
<!-- Known issues and things that need fixing -->

## Features
<!-- New capabilities and enhancements -->

## Performance
<!-- Speed, loading, optimization -->

## Testing
<!-- Test coverage gaps and missing tests -->

## Documentation
<!-- Docs, guides, and READMEs that need updating -->

## Cleanup
<!-- Tech debt, refactoring, code quality improvements -->
```

Then explain to the user:

> I created a backlog at `docs/todos/backlog.md`. It's a simple checklist organized by category — you can view and check off items right on GitHub. It gets updated each time you run `/close`.

**Add selected items to the backlog:**

For each selected suggestion, find the matching section header in `docs/todos/backlog.md` (e.g., a "Security" suggestion goes under `## Security`) and append:

```markdown
- [ ] [Description of the suggestion]
```

Add items directly below the section header (after the HTML comment if present). If a section doesn't exist for a category, add a new section at the bottom.

**Commit and push:**

```bash
git add docs/todos/backlog.md
git commit -m "docs: update backlog with next tasks"
git push -u origin HEAD
```

### Step 6: Save preference (first-time only)

**Only ask this if the preference was empty/missing in Step 1.** If the user already has a preference set, skip this step entirely.

```
One more thing — would you like me to update the backlog automatically during /close, or ask you each time?

1. Always update — add suggestions to the backlog automatically
2. Always ask — show me the suggestions and let me pick (what just happened)
3. Skip — don't show suggestions during /close

You can change this anytime by saying "change my backlog preference".
```

Wait for the user's response, then save:

- **"1" (always update):**
  ```bash
  ~/.claude/plugins/marketplaces/hypt-builder/bin/hypt-config set suggestions_auto_backlog auto
  ```

- **"2" (always ask):**
  ```bash
  ~/.claude/plugins/marketplaces/hypt-builder/bin/hypt-config set suggestions_auto_backlog ask
  ```

- **"3" (skip):**
  ```bash
  ~/.claude/plugins/marketplaces/hypt-builder/bin/hypt-config set suggestions_auto_backlog skip
  ```

### Step 7: Summary

If items were added:
```
Backlog updated — added [N] items to docs/todos/backlog.md.
```

If the user said "none" or preference was "skip":
```
No backlog changes. Moving on!
```

### Standalone usage: Change preference

If the user invokes this skill and says something like "change my backlog preference", "update suggestions settings", or "stop updating my backlog":

1. Show the current preference:
   ```bash
   ~/.claude/plugins/marketplaces/hypt-builder/bin/hypt-config get suggestions_auto_backlog
   ```

2. Present the same three options from Step 6.

3. Save their choice and confirm:
   ```
   Got it — updated your preference. This will take effect next time you run /close.
   ```
