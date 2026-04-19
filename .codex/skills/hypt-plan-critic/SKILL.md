---
name: "hypt-plan-critic"
description: "Dynamic plan review — adapts to task complexity, uses parallel subagents for larger plans. Use when the user wants a plan critiqued before implementation, including `/plan-critic`, `hypt:plan-critic`."
metadata:
  short-description: "Review a Plan Before Building"
---
<!-- Generated from plugin/skills/plan-critic/SKILL.md. Do not edit by hand. Run `node scripts/sync-codex-support.mjs` instead. -->

# hypt-plan-critic — Review a Plan Before Building

## Context

Before starting, gather context by running:

- Run `git branch --show-current` to capture Branch.

- Docs directory: `ls docs/*.md 2>/dev/null || echo "No docs yet"`
- Plan files: `ls docs/*-plan*.md docs/roadmap.md TODO.md TODOS.md docs/todos/backlog.md 2>/dev/null || echo "No plans found"`

## Instructions

This skill critically reviews any implementation plan — features, bugfixes, refactors, or anything else — to catch gaps, ambiguities, and risks **before** code is written, when they're cheap to fix.

It dynamically adapts its review depth based on task complexity. Small tasks get a quick inline check; larger tasks get parallel subagent analysis.

**Priority order:** Plan correctness > Codebase understanding > Completeness > Security > Logic gaps

This skill can be invoked three ways:
- **Standalone:** User says `/plan-critic` — full interactive flow
- **From `/prototype`:** Called automatically as Step 0a — streamlined flow (still asks blocker questions, but proposes defaults for lesser issues)
- **From `/pipeline`:** Called autonomously as part of the pipeline — fully non-interactive. Makes its own calls on all non-blocker issues, updates the plan file directly, and returns control immediately.

---

### Step 0: Get the plan and original request

**Required inputs:** This skill needs TWO things for a thorough review:
1. The plan content (file path or text)
2. The original user request / task description (so it can evaluate whether the plan addresses the problem)

If a plan file path was provided (from `/prototype`, `/pipeline`, or the user), use it directly.

If called from `/prototype` or `/pipeline`, both should be provided by the caller.

If called standalone:
- If no plan was provided, ask:
  > Which plan should I review? Options:
  > - A `.md` file path (e.g., `docs/2026-04-13-my-app-plan.md` or `docs/roadmap.md`)
  > - Paste the plan text here

- If no original request was provided, ask:
  > What was the original request or goal this plan is meant to address?

Wait for the user's response before continuing.

---

### Step 1: Read the plan and gather context

Read the plan file fully.

Then gather additional context:
- If the plan references specific files, spot-check that they exist and contain what the plan assumes (use search/file discovery)
- If there's a companion description or issue linked, read it for additional context
- If the plan is at `docs/YYYY-MM-DD-<idea>-plan.md`, check for a companion `docs/YYYY-MM-DD-<idea>.md` and read it if found — it provides business context

---

### Step 2: Assess task complexity

Based on the plan content, classify the task as **small** or **large**.

**Small** — ALL of these are true:
- Plan modifies ≤3 files
- Task is a straightforward bugfix, config change, or small isolated feature
- Plan is under ~50 lines
- No architectural decisions or cross-cutting concerns
- No database schema changes
- No new public API surfaces

**Large** — ANY of these is true:
- Plan modifies 4+ files
- Task involves a new feature, refactor, or multi-component change
- Plan is 50+ lines or references multiple subsystems
- Architectural decisions are involved (new patterns, abstractions, service boundaries)
- Database schema changes or migrations
- Cross-cutting concerns (auth, logging, error handling changes)

**Err on the side of "small" for borderline cases.** The cost of over-analyzing a small change is higher than under-analyzing it.

If **small**, proceed to Step 3S (Quick Review).
If **large**, proceed to Step 3L (Deep Review).

---

### Step 3S: Quick Review (small tasks only)

Do a quick inline logic check — no subagents needed:

1. **Problem-solution match:** Does the plan actually address the stated problem/request?
2. **File verification:** Do the files and functions mentioned in the plan actually exist in the codebase? (Use search/file discovery to spot-check the key ones)
3. **Obvious gaps:** Any missing error handling, edge cases, or logical contradictions?
4. **Pattern conformance:** Does the approach follow existing codebase patterns? (Quick check — don't over-research)

If issues found, categorize them (blocker / important / nice-to-have) and proceed to Step 4.
If no issues found, proceed directly to Step 6 (confirm readiness).

---

### Step 3L: Deep Review (large tasks)

Spawn parallel sub-agents to launch BOTH agents in a SINGLE message (parallel execution). Provide each agent with: the full plan text, the original user request, and the current branch name.

**Agent 1 — Research Thoroughness**
> You are evaluating whether an implementation plan demonstrates sufficient understanding of the codebase it will modify.
>
> Original request: {original_request}
> Plan: {plan_text}
> Branch: {branch}
>
> Your job:
> - Read the files the plan proposes to modify. Does the plan accurately describe their current state?
> - Check for related documentation (README, docs/, inline comments) that the plan should reference
> - Look for existing coding patterns, conventions, or utilities the plan should leverage but doesn't mention
> - Identify any app behaviors, edge cases, or integrations the plan might not account for
> - Check if there are tests, types, or validation patterns that the plan should be aware of
>
> Report each finding as: `severity | description | what the plan should address`
> Severities: blocker (plan is based on wrong assumptions), important (significant gap in understanding), nice-to-have (would improve the plan)

**Agent 2 — Plan Completeness**
> You are evaluating whether an implementation plan fully addresses the original request.
>
> Original request: {original_request}
> Plan: {plan_text}
> Branch: {branch}
>
> Your job:
> - Does the plan cover every aspect of the original request? List any items from the request that aren't addressed
> - Are there obvious quality-of-life improvements or polish items that should be included?
> - Does the plan handle error cases, loading states, and edge cases?
> - Are there security implications the plan should mention? (auth checks, input validation, data access controls)
> - Is the plan's scope appropriate? (not too narrow, not bloated with unnecessary extras)
> - Would an engineer picking up this plan have enough detail to implement it without guessing?
>
> Report each finding as: `severity | description | suggested addition to plan`
> Severities: blocker (request fundamentally unmet), important (significant gap), nice-to-have (polish)

After both agents complete, merge their findings into a single list, deduplicate, and sort by severity. Proceed to Step 4.

Also evaluate the plan against this priority checklist for anything the agents may have missed:

#### Priority 1: Completeness (highest priority)

- Does the plan address every aspect of the original request?
- Does every item have enough detail to implement without guessing?
- Are all the files that need to change identified?
- Is the data model or schema change complete (if applicable)?
- Are there flows or paths that are mentioned but not fully specified?
- Are there obvious items that any implementation of this type would need that aren't listed?

#### Priority 2: Security

- Does the plan involve user input? Is validation/sanitization addressed?
- Are there authorization checks needed? (who can access what)
- Does the plan involve sensitive data? (credentials, PII, tokens — are they handled safely?)
- Are there API endpoints or server actions that need auth protection?
- Is there potential for injection (SQL, XSS, command injection) in the proposed approach?

#### Priority 3: Bugs / Logic gaps

- Are there contradictions between different parts of the plan?
- Are there race conditions or concurrency issues in the proposed flows?
- Are error states and failure modes considered?
- Are there edge cases in the data or control flow? (empty inputs, boundary values, concurrent modifications)
- Does the plan account for existing state? (migrations, backwards compatibility, existing data)

#### Priority 4: Code quality / Best practices

- Does the approach follow the project's existing patterns and conventions?
- Is the solution appropriately scoped? (not over-engineered, not under-engineered)
- Are there existing utilities, helpers, or abstractions the plan should reuse?
- Is the tech approach consistent with the project's stack?
- Are there opportunities to simplify the approach?

---

### Step 4: Present findings and resolve issues

Categorize every issue found:

- **Blocker** — plan is based on wrong assumptions or fundamentally misses the request
- **Important** — plan will work but has a significant gap or risk
- **Nice to have** — would improve the plan, but a sensible default exists

**When invoked standalone (`/plan-critic`):**

Present ALL issues, grouped by category, starting with blockers:

> I've reviewed your plan and found a few things to address before building:
>
> **Blockers** (need your input before we can build):
> 1. [Issue description + question]
> 2. [Issue description + question]
>
> **Important** (should fix, but I can suggest defaults):
> 1. [Issue description + suggested default]
>
> **Nice to have** (minor, I'll assume a default unless you say otherwise):
> 1. [Issue description + what I'd assume]
>
> Let's start with the blockers — [first blocker question]?

Wait for answers to ALL blockers before continuing. For important and nice-to-have items, propose defaults and ask if they're acceptable.

**When invoked from `/prototype`:**

Same review, but streamlined to avoid friction:
- Still present and wait for answers to **blockers** — these must be resolved
- For **important** items: propose defaults, list them, and say "I'll go with these unless you object"
- For **nice to have** items: silently use sensible defaults (don't even mention them unless they're surprising)

**When invoked from `/pipeline`:**

Fully autonomous — no user interaction at all:
- **Blockers:** If genuine blockers exist (plan is based on provably wrong assumptions about the codebase), note them in the plan file as a `## Review: Open Questions` section and proceed. Do NOT stop the pipeline.
- **Important:** Make the call yourself. Apply the most reasonable fix/addition to the plan.
- **Nice to have:** Silently incorporate sensible defaults.

---

### Step 5: Apply fixes to the plan

**When invoked standalone (`/plan-critic`):**

After all questions are resolved, present the improvements:

> I found **[N] things** to improve in your plan. Here's what I'd change:
>
> **Completeness:**
> - [change 1]
> - [change 2]
>
> **Security:**
> - [change 1]
>
> **Logic:**
> - [change 1]
>
> How would you like me to handle these?
>
> 1. **Update the plan directly** — I'll edit the plan file with all improvements
> 2. **Create an addendum** — I'll write a separate file to read alongside the plan
> 3. **Skip** — the plan is good enough as-is, let's build

**If option 1 (update directly):**

Edit the plan file in place by editing the file. Make targeted changes — don't rewrite the entire document. Then:

```bash
git add -A && git commit -m "docs: refine plan after critical review" && git push
```

**If option 2 (addendum):**

Write `docs/YYYY-MM-DD-<idea>-plan-addendum.md` with:

```markdown
# [App Name] — Plan Addendum

> This addendum should be read alongside the main plan: `./YYYY-MM-DD-<idea>-plan.md`
> Generated after critical review on [today's date].

## Additional Details

### [Section name]
[Additional details, clarifications, or corrections]

### [Section name]
[...]
```

Then:
```bash
git add docs/ && git commit -m "docs: add plan addendum after critical review" && git push
```

**If option 3 (skip):**

Continue without changes.

**When invoked from `/prototype`:**

Same options as standalone, but default to option 1 unless the user chooses otherwise.

**When invoked from `/pipeline`:**

Do NOT present options or wait for input.

If Step 4 found no issues (or only nice-to-have items that were silently incorporated with no plan edits needed), skip directly to Step 6 — do not create an empty commit.

If the plan was updated:
1. Edit the plan file in place by editing the file — add missing details, fix gaps, incorporate improvements
2. Commit and push the changes:
```bash
git add -A && git commit -m "docs: refine plan after automated review" && git push
```
3. Return control to the pipeline immediately.

---

### Step 6: Confirm readiness

If improvements were made or skipped:

> Plan review complete. Your plan is ready for implementation.

If called from `/prototype`, return control so the prototype workflow continues to Step 1 (implementation).

If called from `/pipeline`, return control so the pipeline continues to the build step.

If called standalone, tell the user:

> When you're ready to build, say `/prototype` and point it to your plan file.
