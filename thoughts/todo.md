# Plan: Add /hypt:todo skill

## Summary
Create a non-coder friendly `/hypt:todo` skill that lets users add items to their project's tracking file (TODOS.md, backlog.md, roadmap.md, etc.) with natural language. Enhance `/hypt:suggestions` to read from all tracking files, group related items, and offer /yolo or /go activation on chosen items.

## Tasks

- [x] 1. Create `plugin/skills/todo/SKILL.md` — the main skill
  - Detect existing tracking files (TODOS.md, backlog.md, roadmap.md, TODO.md, etc.)
  - Parse user's natural language request into actionable todo items
  - Categorize items into appropriate sections
  - Group related small items together
  - Update the file in place (create backlog.md if none exists)
  - Commit and push
- [x] 2. Update `plugin/skills/suggestions/SKILL.md`
  - Read from ALL tracking files, not just `docs/todos/backlog.md`
  - Group related items by domain/similarity
  - After presenting suggestions, offer "/yolo or /go on any of these?"
  - Route to chosen skill when user picks an item
- [x] 3. Update `plugin/skills/hypt/SKILL.md` — add routing
  - Add trigger phrases for todo skill
- [x] 4. Update `plugin/.claude-plugin/plugin.json`
  - Add "todo" to description and keywords
- [x] 5. Update `scripts/sync-codex-support.mjs`
  - Add todo skill entry to SKILLS array
- [x] 6. Run `node scripts/sync-codex-support.mjs` to generate Codex adapted skill
- [x] 7. Update READMEs with new skill documentation
