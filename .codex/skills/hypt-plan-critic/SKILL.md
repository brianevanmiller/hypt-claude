---
name: "hypt-plan-critic"
description: "Critical plan review — find gaps, ask questions, and refine before building. Use when the user wants a plan critiqued before implementation, including `/plan-critic`, `hypt:plan-critic`."
metadata:
  short-description: "Review a Plan Before Building"
---
<!-- Generated from plugin/skills/plan-critic/SKILL.md. Do not edit by hand. Run `node scripts/sync-codex-support.mjs` instead. -->

# hypt-plan-critic — Review a Plan Before Building

## Context

Before starting, gather context by running:

- Run `git branch --show-current` to capture Branch.

- Docs directory: `ls docs/*.md 2>/dev/null || echo "No docs yet"`

## Instructions

This skill critically reviews any plan document to ensure it's complete and robust enough to produce a working prototype. It catches gaps, ambiguities, and issues **before** code is written — when they're cheap to fix.

**Priority order:** Completeness for working MVP > Security > Bugs/Logic gaps > Code quality

This skill can be invoked two ways:
- **Standalone:** User says `/plan-critic` — full interactive flow
- **From `/prototype`:** Called automatically as Step 0a — streamlined flow (still asks blocker questions, but proposes defaults for lesser issues)

---

### Step 0: Get the plan

If a plan file path was provided (from `/prototype` or the user), use it directly.

Otherwise, ask:

> Which plan should I review? Options:
> - A `.md` file path (e.g., `docs/2026-04-13-my-app-plan.md`)
> - Paste the plan text here

Wait for the user's response.

---

### Step 1: Read the plan and app description

Read the plan file fully.

Then check if a companion app description exists alongside it. The app description has the same date prefix and idea slug but without `-plan` in the filename:
- Plan: `docs/YYYY-MM-DD-<idea>-plan.md`
- Description: `docs/YYYY-MM-DD-<idea>.md`

```bash
# If plan is docs/2026-04-13-dog-walker-plan.md, look for docs/2026-04-13-dog-walker.md
```

If found, read it too — it provides business context that helps evaluate whether the plan covers everything.

---

### Step 2: Evaluate against priority checklist

Review the plan critically, in this exact priority order. Take notes on every issue found.

#### Priority 1: Completeness for working MVP (highest priority)

- Does every feature have enough detail to implement end-to-end?
- Are all pages/routes defined? Can you list every URL the app needs?
- Is the data model complete — does every feature have the tables and fields it needs?
- Are relationships between tables clear? (e.g., "a user has many orders" — is that reflected?)
- Is the auth flow fully specified? (sign up, sign in, sign out, which pages require auth, what happens when an unauthenticated user visits a protected page)
- If payments: is the Stripe flow clear? (what triggers checkout, success/failure handling, webhooks)
- If emails: what triggers each email, and what should each email contain?
- Are there features the app description mentions that the plan is missing? (e.g., description says "users can rate each other" but plan has no ratings feature or ratings table)
- Are there obvious features that ANY app like this would need that aren't listed? (e.g., a marketplace with no way to contact the other party)

#### Priority 2: Security

- Does the data model imply Row Level Security (RLS) policies? (e.g., "users can only see their own orders" — is that enforced?)
- Is auth using Supabase Auth (good) or rolling a custom solution (risky)?
- Are API routes and server actions properly protected? (no unauthenticated access to sensitive operations)
- Is sensitive data (service role key, Stripe secret key) only used in server-side code?
- Is there user input that needs validation or sanitization? (form fields, URL parameters, file uploads)

#### Priority 3: Bugs / Logic gaps

- Are there contradictions between features? (e.g., "free tier" feature but pricing table shows no free option)
- Are there race conditions in the flows? (e.g., double-submit on payment, two users booking the same slot)
- Are error states considered? (payment fails, email can't be sent, auth session expires mid-action)
- Are there edge cases in the data model? (user deletes account but has active orders, item goes out of stock after being added to cart)

#### Priority 4: Code quality / Best practices

- Is the data model appropriately normalized for a prototype? (not over-engineered, not missing obvious tables)
- Are page/route names following Next.js App Router conventions?
- Is the tech stack consistent? (no conflicting libraries or redundant tools)
- Are there opportunities to simplify? (fewer tables, fewer pages, simpler flows that still deliver the MVP)

---

### Step 3: Ask questions for gaps and ambiguities

Categorize every issue found:

- **Blocker** — can't build a working prototype without resolving this
- **Important** — prototype will work but will have a significant gap or risk
- **Nice to clarify** — would improve the prototype, but a sensible default exists

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
> **Nice to clarify** (minor, I'll assume a default unless you say otherwise):
> 1. [Issue description + what I'd assume]
>
> Let's start with the blockers — [first blocker question]?

Wait for answers to ALL blockers before continuing. For important and nice-to-clarify items, propose defaults and ask if they're acceptable.

**When invoked from `/prototype`:**

Same review, but streamlined to avoid friction:
- Still present and wait for answers to **blockers** — these must be resolved
- For **important** items: propose defaults, list them, and say "I'll go with these unless you object"
- For **nice to clarify** items: silently use sensible defaults (don't even mention them unless they're surprising)

---

### Step 4: Propose fixes

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
git add docs/ && git commit -m "docs: refine plan after critical review" && git push
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

---

### Step 5: Confirm readiness

If improvements were made or skipped:

> Plan review complete. Your plan is solid and ready for `/prototype`.

If called from `/prototype`, return control so the prototype workflow continues to Step 1 (implementation).

If called standalone, tell the user:

> When you're ready to build, say `/prototype` and point it to your plan file.
