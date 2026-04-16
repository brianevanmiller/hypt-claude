# Plan: Document hypt Router Design + Enhance Docs Skill

## Goal

1. Create `docs/hypt-router-design.md` with ASCII art diagrams showing how the `/hypt:hypt` skill router works — routing logic, skill composition, and the full pipeline flow. Written for non-coders.
2. Enhance `plugin/skills/docs/SKILL.md` to add a new step for **process workflow documentation** — creating/updating diagrams, ASCII art flowcharts, and other visual assets in `docs/` when process changes are shipped.

## Design Decisions

1. **ASCII art over Mermaid** — ASCII art renders everywhere (terminal, GitHub, any editor) without tooling. Mermaid needs a renderer.
2. **Non-coder audience** — the router doc should be understandable by a PM or founder, not just engineers.
3. **Docs skill enhancement is additive** — add a new Step 4b (between feature docs and dates/status), don't restructure existing steps.
4. **Keep it lightweight** — the docs skill step should only trigger when process/workflow files in `docs/` exist and are affected by the PR.

## Tasks

- [x] 1. Create `docs/hypt-router-design.md` with:
  - Overview of what the router is and why it exists
  - ASCII art: user input → router → skill dispatch
  - ASCII art: skill composition (pipeline, go, yolo)
  - ASCII art: full typical workflow (start → ... → close)
  - Table: all skills with one-line descriptions
- [x] 2. Enhance `plugin/skills/docs/SKILL.md`:
  - Update frontmatter `description` to mention process workflow documentation
  - Add Step 4b: "Update process workflow documentation"
  - Triggers: PR changed skill files, routing logic, or workflow composition
  - Actions: update ASCII diagrams, flowcharts, and process docs in `docs/`
  - Convention: process docs should use ASCII art for portability
  - Update Step 7 summary format to include a "Process docs" line
- [x] 3. Update `docs/todos/backlog.md` — no matching items in backlog (verified)
