<!-- hypt-engineer-start -->
## Workflow Discipline

### 1. Plan Before Building
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately — don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Use Subagents Effectively
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One task per subagent for focused execution

### 3. Learn From Mistakes
- After ANY correction from the user: update `$HOME/.claude/thoughts/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake twice
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at the start of each session for the relevant project

### 4. Verify Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 5. Demand Elegance (But Don't Over-Engineer)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes — don't over-engineer
- Challenge your own work before presenting it

### 6. Fix Problems Autonomously
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests — then resolve them
- Zero context switching required from the user

---

## Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.

---

## Planning & Approach

- Do NOT exit plan mode until the user explicitly approves the plan. Present the plan summary and wait for confirmation before proceeding to implementation.

---

## Git & GitHub Workflow

- When working with GitHub branch-protected `main` branches, NEVER push directly to main. Always create a separate PR branch for version bumps and other changes, even if they seem trivial.

---

## Pre-PR Checklist

- After completing implementation, always run typecheck (`tsc --noEmit` or equivalent), lint, and tests before creating a PR. Fix any failures including pre-existing ones that would block CI.

---

## PR & Commit Etiquette

- If git workflow docs exist (PR templates, commit conventions, etc.), read those before making the first commit or PR
- Otherwise, look at past PRs and commits to get a sense of the style, and follow that formatting
<!-- hypt-engineer-end -->
