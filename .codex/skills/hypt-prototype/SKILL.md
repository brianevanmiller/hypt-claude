---
name: "hypt-prototype"
description: "End-to-end prototype: implement plan, review, test, and deliver a working build. Use when the user wants a plan implemented into a working prototype end to end, including `/prototype`, `hypt:prototype`."
metadata:
  short-description: "Build a Working Prototype from a Plan"
---
<!-- Generated from plugin/commands/prototype.md. Do not edit by hand. Run `node scripts/sync-codex-support.mjs` instead. -->

# hypt-prototype — Build a Working Prototype from a Plan

## Context

Before starting, gather context by running:

- Run `git branch --show-current` to capture Branch.

- Existing docs: `ls docs/ 2>/dev/null || echo "No docs/ folder"`
- PR status: `gh pr view --json number,url 2>/dev/null || echo "No PR yet"`

## Instructions

This skill takes a plan document and delivers a working, reviewed, tested prototype. Designed to be run by anyone — no technical knowledge required.

---

### Step 0: Detect mode — fresh build or iterate on existing PR

Check the Context section above. If a PR already exists for this branch:

> **Resuming existing prototype.** PR #<number> found — skipping to review and iteration.
> I'll critically review the current implementation, fix issues, add tests, and get it ready.

**Skip directly to Step 3** (first review). The implementation already happened — now we refine it.

If NO PR exists, continue with Step 0b below.

---

### Step 0b: Get the plan

**Always ask the user for the plan.** Say:

> Which plan should I implement? Options:
> - A `.md` file path (e.g., `docs/my-feature-plan.md`)
> - A plan from this session (I'll look for it in the conversation)
> - Paste the plan here

Wait for the user's response. Once you have the plan:
1. Read the plan document fully
2. Summarize what you're about to build in 2-3 sentences
3. Proceed to Step 0c.

---

### Step 0c: Review the plan

Use `$hypt-plan-critic`

Pass the plan file path (or the plan text from the conversation). The plan critic will review for completeness, security, logic gaps, and best practices.

If the critic identifies blockers, they must be resolved before continuing. Once the critic confirms the plan is ready, say:

> "Starting the prototype build now. I'll handle everything — sit back and I'll check in when it's ready for you to look at."

---

### Step 1: Implement the MVP

Build the feature described in the plan. Focus on:
- **Working code** — the feature must function end-to-end
- **Security** — no exposed secrets, proper auth checks, input validation
- **Bug-free** — handle error states, null checks, edge cases
- **Minimal scope** — implement what the plan says, nothing extra

Do NOT write unit tests in this step. Tests come later.

After implementation, verify the build compiles. If the project uses TypeScript (`tsconfig.json` exists):
```bash
bunx tsc --noEmit 2>&1
```

Run the project's build command:
```bash
bun run build 2>&1
```

Fix any build errors before proceeding.

---

### Step 2: Save — initial PR

Use `$hypt-save`

This commits everything, pushes, and creates a PR.

---

### Step 3: First review — fix everything

Use `$hypt-review`

When the review completes and asks about medium/low findings, reply "all" — fix everything. Be maximalist here. The goal is clean, solid code.

**Important:** If the review suggests adding unit tests, skip those suggestions. Tests come in Step 6.

After all fixes are applied, save the changes:

Use `$hypt-save`

---

### Step 4: First touchup — catch stragglers

Use `$hypt-touchup`

This addresses any PR bot comments, fixes build issues, and updates docs.

---

### Step 5: Second review — final quality pass

Use `$hypt-review`

Again, fix ALL findings (reply "all"). Still skip any unit test suggestions.

After all fixes, save the changes:

Use `$hypt-save`

---

### Step 6: Unit tests

Use `$hypt-unit-tests`

This creates appropriate tests and confirms they pass.

---

### Step 7: Final touchup

Use `$hypt-touchup`

Confirm the PR is in a mergeable state — build passes, no blocking comments.

---

### Step 8: Get deployment links

Detect the deployment platform:
```bash
ls vercel.json .vercel/ netlify.toml fly.toml render.yaml railway.json railway.toml 2>/dev/null
```

Find the preview deployment URL using the detected platform or the GitHub Deployments API:

**Platform-specific check runs:**
```bash
gh pr checks --json name,link --jq '.[] | select(.name | test("vercel|netlify|deploy|Vercel|Netlify"; "i")) | .link' 2>/dev/null
```

**GitHub Deployments API (generic):**
```bash
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
SHA=$(git rev-parse HEAD)
gh api "repos/$REPO/deployments?sha=$SHA" --jq '.[0].id' 2>/dev/null
```
Then get the URL:
```bash
gh api "repos/$REPO/deployments/<ID>/statuses" --jq '.[0].target_url' 2>/dev/null
```

If the deployment is still in progress, wait for it (poll every 15s, up to 3 minutes).

Health-check the preview URL:
```bash
curl -sL -o /dev/null -w "%{http_code}" "<PREVIEW_URL>"
```

---

### Step 9: Write feature synopsis

Create a feature doc at `docs/features/<date>-<feature-name>.md` where:
- `<date>` is today's date in `YYYY-MM-DD` format
- `<feature-name>` is a short kebab-case name for the feature

The doc should follow this structure:

```markdown
# <Feature Name>

## Business Value

<What this feature does for users / the business. Written for a non-technical audience.
Why it matters, what problem it solves, who benefits.>

## What It Does

<Plain-English description of the feature behavior. What can users do now that they couldn't before?>

## How It Works

<Implementation details for developers. Key files, architecture decisions, data flow.
Keep it concise — reference the code, don't duplicate it.>

## Files Changed

<List of key files added or modified>

## Status

- PR: #<number> — <url>
- Preview: <preview_url>
- Tests: passing
- Date: <today's date>
```

Create the `docs/features/` directory if it doesn't exist:
```bash
mkdir -p docs/features
```

Commit the feature doc:
```bash
git add docs/features/ && git commit -m "docs: add feature synopsis for <feature-name>" && git push
```

---

### Step 10: Present to the user

Show a clear summary:

```
Prototype complete! Here's what was built:

## <Feature Name>

<2-3 sentence business value summary>

### Links
- Preview build: <preview_url>  <- click to see it live
- Pull request: <pr_url>

### What happened
- Implementation: done
- Code reviews: 2 rounds, all findings fixed
- Unit tests: done (<N> test cases passing)
- Build: passing
- Docs: saved to docs/features/<filename>.md

### Try it out
<1-2 specific things the user can do in the preview to see the feature working>
```

Then ask:

> Take a look at the preview and let me know what you think!
> When you're happy with it, say `/close` and I'll merge it to production.
