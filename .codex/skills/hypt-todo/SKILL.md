---
name: "hypt-todo"
description: "Add or update todos, backlog items, or roadmap entries in your project's tracking file. Use when the user wants to add, update, or manage items in their project's tracking file (backlog, roadmap, todos), including `/todo`, `hypt:todo`."
metadata:
  short-description: "Update Your Project Backlog"
---
<!-- Generated from plugin/skills/todo/SKILL.md. Do not edit by hand. Run `node scripts/sync-codex-support.mjs` instead. -->

# hypt-todo — Update Your Project Backlog

## Context

Before starting, gather context by running:

- Run `git branch --show-current` to capture Branch.

- Tracking files: `find . -maxdepth 3 -iname "*.md" \( -iname "*todo*" -o -iname "*backlog*" -o -iname "*roadmap*" -o -iname "*tasks*" \) -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./.codex/*" 2>/dev/null | head -10 || echo "None found"`

## Instructions

This skill makes it easy to add items to your project's tracking file — no technical knowledge needed. Just tell it what you want to work on, and it handles the rest.

### Step 1: Find the tracking file

Look at the "Tracking files" from the Context section above. Determine which file to use:

**Priority order** (use the first one that exists):
1. `docs/todos/backlog.md` — the standard hypt backlog format
2. `TODOS.md` or `TODO.md` at the project root
3. `docs/roadmap.md` or `ROADMAP.md`
4. `docs/tasks.md` or `TASKS.md`
5. Any other markdown file from the tracking files list

**If no tracking file exists:** Create `docs/todos/backlog.md` using the standard template:

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

Tell the user:

> I created a backlog at `docs/todos/backlog.md`. It's a simple checklist — you can view and edit it right on GitHub.

**If a tracking file exists:** Read it to understand its structure (sections, format, existing items).

### Step 2: Parse the user's request

The user may provide items in many forms:

- A single item: "add deploy monitoring to the backlog"
- A list: "track these: dark mode, export to PDF, and user onboarding"
- Vague intent: "we need better error handling and some tests"
- Natural conversation: "I think we should add a search feature and also fix that login bug"

Extract each distinct item from their request. For each item, write a clear, actionable one-liner. Keep the user's language — don't over-formalize it.

**Examples of good item phrasing:**
- "Add dark mode toggle to settings page" (not "Implement theme switching infrastructure")
- "Fix login bug where password reset link expires too fast" (not "Resolve authentication token TTL misconfiguration")
- "Write tests for the checkout flow" (not "Establish comprehensive e2e test coverage for payment processing pipeline")

### Step 3: Categorize items

For files that use the standard backlog format (with `## Security`, `## Bugs`, `## Features`, etc.), assign each item to the right section:

| Category | Put it here when... |
|----------|-------------------|
| Security | Auth, permissions, data protection, secrets, input validation |
| Bugs | Something is broken or not working right |
| Features | New capability, enhancement, or user-facing change |
| Performance | Speed, optimization, caching, loading times |
| Testing | Tests, coverage, QA |
| Documentation | Docs, guides, READMEs, comments |
| Cleanup | Tech debt, refactoring, removing old code |

If the file uses a **different structure** (numbered lists, flat checkboxes, custom sections), match its existing format. Don't restructure someone's file — add items where they fit naturally.

### Step 4: Group related items

Before adding items, check if any can be logically grouped:

- **Same domain:** "add search" + "add search filters" + "add search history" → group under a single parent item or note they're related
- **Same effort:** multiple small items in the same area → suggest tackling together
- **Dependencies:** if one item clearly depends on another, note it

When grouping, use indented sub-items:

```markdown
- [ ] Add search functionality
  - [ ] Basic keyword search
  - [ ] Search filters (date, type, status)
  - [ ] Search history / recent searches
```

Only group items that genuinely belong together. Don't force unrelated items into groups.

### Step 5: Check for duplicates

Before adding each item, scan the existing file for similar entries. If an item is already tracked (even with different wording), skip it and tell the user:

> "Add dark mode" is already on your list — skipping.

If an existing item is close but not quite the same, mention it:

> You already have "Add theme support" on the list. Want me to add "Add dark mode toggle" separately, or update the existing item?

Wait for the user's answer before proceeding if there's ambiguity.

### Step 6: Add items to the file

Add each new item to the appropriate section as an unchecked checkbox:

```markdown
- [ ] [Description of the item]
```

Add items after the section header's HTML comment (if present) and after any existing items in that section. Keep the file's existing style consistent.

**For non-standard file formats:** Match whatever format the file already uses (numbered lists, plain text, etc.). If the file has no clear format, default to checkbox style.

### Step 7: Confirm and save

Show the user what was added in a friendly summary:

```
Added to your backlog:

## Features
- [ ] Add dark mode toggle to settings page
- [ ] Export conversations to PDF

## Bugs
- [ ] Fix password reset link expiring too fast

(3 items added to docs/todos/backlog.md)
```

Then commit and push:

```bash
git add <tracking-file-path>
git commit -m "docs: update backlog with new items"
git push -u origin HEAD
```

If the push fails (no remote, no branch set up, etc.), that's fine — just commit locally and let the user know:

> Saved locally. Run `/save` when you're ready to push.

### Handling edge cases

**User invokes `/todo` with no items or empty input:**
Ask what they'd like to add:

> What would you like to add? Just tell me in plain language — like "add dark mode" or "fix the login bug."

**User says "update" or "change" an existing item:**
Find the matching item and edit it in place. Show the before/after.

**User says "remove" or "check off" an item:**
Change `- [ ]` to `- [x]` for the matching item. Or remove it if they say "delete" or "remove."

**User says "show me my backlog" or "what's on my list":**
Just read and display the tracking file contents. Don't modify anything.

**User says something vague like "update the roadmap":**
Ask what they'd like to add:

> What would you like to add to your roadmap? Just tell me in plain language — like "add user profiles" or "fix the slow loading on the dashboard."
