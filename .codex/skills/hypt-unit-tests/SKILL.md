---
name: "hypt-unit-tests"
description: "Create or extend unit tests for PR changes — lean by default, thorough for critical paths. Use when the user wants tests added or extended for the current PR, including `/unit-tests`, `hypt:unit-tests`."
metadata:
  short-description: "Smart Unit Tests for PR Changes"
---
<!-- Generated from plugin/skills/unit-tests/SKILL.md. Do not edit by hand. Run `node scripts/sync-codex-support.mjs` instead. -->

# hypt-unit-tests — Smart Unit Tests for PR Changes

## Context

Before starting, gather context by running:

- Run `git branch --show-current` to capture Branch.

- PR changes: `git diff main...HEAD --stat 2>/dev/null || git diff origin/main...HEAD --stat 2>/dev/null || echo "No diff against main"`
- PR info: `gh pr view --json title,body,number 2>/dev/null || echo "No PR found"`
- Existing tests: `find . -name "*.test.ts" -o -name "*.test.tsx" -o -name "*.spec.ts" -o -name "*.spec.tsx" -o -name "*.test.js" -o -name "*.test.jsx" -o -name "*.spec.js" -o -name "*.spec.jsx" 2>/dev/null | head -20 || echo "No test files found"`
- Test config: `ls vitest.config.* jest.config.* 2>/dev/null || echo "No test config found"`

## Instructions

### Step 0: Bootstrap test infrastructure (if needed)

Check if a test runner is configured:
1. Look for `vitest.config.*`, `jest.config.*`, or a `test` script in `package.json`
2. If a test runner already exists, skip this step entirely and use the existing setup

If no test runner exists, bootstrap based on the project:

**Detect project type:**
```bash
cat package.json | grep -E '"(react|next|vue|angular|svelte)"' 2>/dev/null
```

**React/Next.js projects** (has `react` in deps):
```bash
bun add -D vitest @testing-library/react @testing-library/jest-dom @vitejs/plugin-react jsdom
```

Create `vitest.config.ts`:
```ts
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./vitest.setup.ts'],
    include: ['**/*.test.{ts,tsx}'],
  },
})
```

Create `vitest.setup.ts`:
```ts
import '@testing-library/jest-dom/vitest'
```

**Node/TypeScript projects** (no React):
```bash
bun add -D vitest
```

Create `vitest.config.ts`:
```ts
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    globals: true,
    include: ['**/*.test.{ts,js}'],
  },
})
```

**Projects with Jest partially configured**: Complete the Jest setup instead of adding Vitest.

Add test scripts to `package.json` if missing:
```json
"test": "vitest run",
"test:watch": "vitest"
```

Add `vitest/globals` to `tsconfig.json` types if using TypeScript.

### Step 1: Deep research into what to test

This is the most important step. Understand WHAT to test before writing anything.

**1a. Understand the PR changes:**
- Read the full diff: `git diff main...HEAD`
- Identify every changed/added file
- Categorize: utility functions, components, server actions, API routes, hooks, database queries, middleware

**1b. Research the feature context:**
- Read relevant docs in `docs/` — look for design docs, business plans, schema docs that explain WHY these changes exist
- Read the PR title/body and branch name for intent
- Read the code itself — understand the happy path and edge cases

**1c. Decide what deserves tests:**

Apply this priority framework:

| Priority | What | Test depth | Examples |
|----------|------|------------|---------|
| **Must test** | Money, trades, transactions, auth | Thorough — multiple edge cases | Payment flows, auth guards, data mutations |
| **Should test** | Core business logic, data transformations | Moderate — happy path + 1-2 edge cases | Validation, search/filter, data processing |
| **Maybe test** | UI components with logic | Lean — just key behavior | Forms with validation, conditional rendering |
| **Skip** | Pure presentation, config, types, layouts | None | Static pages, type definitions, CSS changes |

**When in doubt, write fewer tests.** One well-targeted test beats five shallow ones.

### Step 2: Check for existing tests

If test files already exist:
- Read the existing tests to understand patterns, conventions, and helper utilities
- Don't duplicate coverage — check what's already tested
- Follow the existing style (naming, file location, assertion patterns)
- Add new test cases to existing test files when they cover the same module
- Only create new test files for modules that have no test file yet

If no tests exist yet:
- Place test files next to the source files: `foo.ts` -> `foo.test.ts`
- Use descriptive test names that explain the behavior, not the implementation

### Step 3: Write the tests

**General principles:**
- Test behavior, not implementation
- Use real types, avoid `as any`
- Mock external dependencies (database clients, APIs) but not internal logic
- Keep each test focused on one thing
- Use `describe` blocks to group related tests
- Write the test name as a sentence: `it('rejects trades when seller has insufficient items')`

**For utility functions / business logic:**
```ts
describe('calculateTradeValue', () => {
  it('sums item values for a simple trade', () => { ... })
  it('throws when trade has no items', () => { ... })
})
```

**For React components:**
```ts
import { render, screen } from '@testing-library/react'

describe('TradeCard', () => {
  it('shows item names and trade status', () => { ... })
  it('disables accept button when trade is expired', () => { ... })
})
```

**For server actions / API logic:**
```ts
describe('createTrade', () => {
  it('creates a trade record with correct fields', () => { ... })
  it('rejects if user is not authenticated', () => { ... })
})
```

**Lean by default.** For non-critical code, 1-3 tests per module is enough. For critical paths (auth, transactions, data mutations), be more thorough — cover edge cases, error paths, boundary conditions.

### Step 4: Run the tests

```bash
bun test 2>&1
```

If tests fail:
1. Read the error output
2. Fix the test OR the source code (if the test uncovered a real bug)
3. Re-run until all tests pass

If a test is flaky or hard to get working, delete it rather than leaving a skipped test. No `.skip()` allowed.

### Step 5: Commit and push

```bash
git add -A && git commit -m "test: add unit tests for PR changes" && git push
```

### Step 6: Check CI

```bash
gh pr checks --watch 2>/dev/null || gh pr view --json statusCheckRollup --jq '.statusCheckRollup[] | "\(.name): \(.status) \(.conclusion // "")"' 2>/dev/null
```

If CI fails:
1. Read the failure output
2. Fix the issue
3. Commit and push again: `git add -A && git commit -m "fix: resolve CI test failures" && git push`
4. Re-check CI

### Step 7: Summary

```
Unit tests complete!
- Test infra: [already existed / bootstrapped Vitest]
- Tests created: X new test files, Y test cases
- Coverage: [list of modules tested]
- Critical paths tested: [list any auth/transaction/mutation tests]
- All tests passing locally and in CI
```
