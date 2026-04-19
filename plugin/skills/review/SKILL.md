---
description: "Thorough PR review with parallel subagents — auto-fixes urgent issues"
allowed-tools: ["Bash", "Read", "Grep", "Glob", "Edit", "Write", "Agent"]
---

# /review — Thorough PR Review

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

- PR diff summary: !`git diff main...HEAD --stat 2>/dev/null || git diff origin/main...HEAD --stat 2>/dev/null || echo "No diff against main"`
- PR info: !`gh pr view --json title,body,number,url 2>/dev/null || echo "No PR found — run /save first"`
- Branch: !`git branch --show-current`

## Instructions

### Step 1: Gather the full diff

Run `git diff main...HEAD` to get the complete diff. This is what the subagents will review.

Also read the PR title/body and branch name to understand the intent of the changes.

### Step 2: Launch 4 review agents in parallel

Use the Agent tool to launch ALL FOUR agents in a SINGLE message (parallel execution). Each agent gets the full diff and PR context.

**Agent 1 — Feature Completeness**
> You are reviewing a PR for feature completeness.
> PR title: {title}, PR body: {body}, Branch: {branch}
> Diff: {diff}
>
> Check: Does the code deliver what the PR/branch promises? Look for:
> - Incomplete implementations or TODO comments left behind
> - Missing routes, pages, or API endpoints that the feature needs
> - UI components referenced but not created
> - Database migrations or schema changes that are missing
>
> Report each finding as: `severity | file:line | description | suggested fix`
> Severities: urgent (feature fundamentally broken), high (significant gap), medium (minor gap), low (nice-to-have)

**Agent 2 — Security & Performance**
> You are reviewing a PR for security and performance issues.
> Diff: {diff}
>
> Check for:
> - XSS: dangerouslySetInnerHTML, unsanitized user input in JSX
> - SQL injection: raw queries with string interpolation
> - Auth: missing auth checks in server actions, API routes, or middleware
> - Exposed secrets: hardcoded API keys, tokens, or credentials
> - Performance: N+1 queries, missing loading/error states, large client bundles, unnecessary client-side rendering
> - Missing rate limiting on public endpoints
>
> Report each finding as: `severity | file:line | description | suggested fix`

**Agent 3 — Bug Finder**
> You are hunting for bugs in a PR.
> Diff: {diff}
>
> Look for:
> - Logic errors, off-by-one, wrong comparisons
> - Null/undefined access without optional chaining
> - Race conditions in async code
> - Unhandled promise rejections
> - Missing error boundaries
> - TypeScript `any` abuse hiding real type errors
> - State mutations that should be immutable
> - Hook dependency array issues (useEffect, useMemo, useCallback)
>
> Report each finding as: `severity | file:line | description | suggested fix`

**Agent 4 — Tech Stack Best Practices**
> You are reviewing a PR for tech stack best practices.
> Diff: {diff}
>
> First, detect the project's stack by reading package.json, config files, and the diff itself.
> Then check for:
> - Framework-specific anti-patterns (misuse of server/client boundaries, wrong data fetching patterns, incorrect routing conventions)
> - ORM/database client misuse (wrong client for the context, missing connection handling)
> - TypeScript: proper typing, no unnecessary `as` casts, no `any` abuse
> - CSS framework: proper utility usage, avoiding inline styles when utilities exist
> - File/folder conventions for the project's framework
> - Dependency concerns: unused imports, overly heavy dependencies for simple tasks
>
> Report each finding as: `severity | file:line | description | suggested fix`

### Step 3: Collect and organize findings

After all 4 agents complete, merge their findings into a single list sorted by severity:

1. **Urgent** — must fix, something is broken
2. **High** — should fix, significant issue
3. **Medium** — worth fixing, minor issue
4. **Low** — nice to have, suggestion

### Step 4: Auto-fix urgent and high issues

For every urgent and high severity finding:
1. Read the file
2. Apply the fix using the Edit tool
3. Verify the fix makes sense

After all fixes are applied:
```bash
git add -A && git commit -m "fix: address PR review — urgent and high priority items" && git push
```

### Step 5: Present remaining items

Show the user a table of medium and low findings:

| # | Severity | File | Issue | Fix |
|---|----------|------|-------|-----|
| 1 | medium   | ... | ... | ... |

Ask: "Want me to fix any of these? Reply with the numbers, 'all', or 'skip'."

### Step 6: Summary

```
Review complete!
- Findings: X urgent, Y high, Z medium, W low
- Auto-fixed: X + Y items (committed and pushed)
- Remaining: Z + W items for your review
```
