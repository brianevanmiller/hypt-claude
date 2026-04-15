---
name: "hypt-ci-setup"
description: "Set up lightweight CI — runs unit tests automatically on every commit via GitHub Actions. Use when the user wants lightweight CI added for linting and unit tests, including `/ci-setup`, `hypt:ci-setup`."
metadata:
  short-description: "Lightweight CI for Your Project"
---
<!-- Generated from plugin/skills/ci-setup/SKILL.md. Do not edit by hand. Run `node scripts/sync-codex-support.mjs` instead. -->

# hypt-ci-setup — Lightweight CI for Your Project

## Context

Before starting, gather context by running:

- Run `pwd` to capture Working directory.

- Package manager: `ls bun.lockb bun.lock package-lock.json yarn.lock pnpm-lock.yaml 2>/dev/null || echo "No lockfile found"`
- Existing CI: `ls .github/workflows/*.yml 2>/dev/null || echo "No CI workflows"`
- Test script: `cat package.json 2>/dev/null | grep -E '"test"' || echo "No test script"`
- Existing tests: `find . -not -path "*/node_modules/*" \( -name "*.test.ts" -o -name "*.test.tsx" -o -name "*.spec.ts" \) 2>/dev/null | head -5 || echo "No test files found"`

## Instructions

This skill sets up the simplest possible CI pipeline — lint and unit tests on every push. It's designed for early-stage projects that need a safety net without slowing down iteration.

**Tone: same as $hypt-start — friendly, clear, explain what CI does in plain terms.**

### Step 1: Explain what this does

> One last thing before you start building: I'd like to set up automatic testing for your project.
>
> Here's what that means: every time code is pushed to GitHub, it automatically checks two things:
> 1. **Lint** — catches common mistakes and code style issues
> 2. **Tests** — runs your unit tests to make sure nothing is broken
>
> This takes about 15 seconds and runs in the background — you won't even notice it. But it catches bugs before they reach your live site.
>
> Want me to set this up? (It's free and takes me about 30 seconds)

Wait for confirmation. If they say no, skip to the end and say:

> No problem! You can always run `/ci-setup` later when you're ready.

If they say yes, continue.

### Step 2: Detect what's already in place

Check silently:
1. Is there already a `.github/workflows/` directory with CI?
2. Is there a `test` script in `package.json`?
3. What package manager is being used? (bun, npm, yarn, pnpm)

If CI already exists, say:

> Looks like CI is already set up! You're good to go.

And stop.

### Step 3: Set up the test runner

**If no `test` script exists in `package.json`:**

Detect the package manager from lockfiles:
- `bun.lockb` or `bun.lock` → bun
- `package-lock.json` → npm
- `yarn.lock` → yarn
- `pnpm-lock.yaml` → pnpm

**For bun projects** (preferred — no extra deps needed):

Add a test script to `package.json`:
```json
"test": "bun test"
```

Detect the project's existing test directory convention:
- If `tests/` exists, use `tests/`
- If `__tests__/` exists, use `__tests__/`
- If `test/` exists, use `test/`
- Otherwise, default to `__tests__/`

Create a minimal smoke test at `<test-dir>/smoke.test.ts`:
```ts
import { describe, expect, test } from "bun:test";

describe("smoke", () => {
  test("project loads", () => {
    expect(true).toBe(true);
  });
});
```

**For npm/yarn/pnpm projects:**

Install vitest:
```bash
npm install -D vitest   # or yarn/pnpm equivalent
```

Add test scripts to `package.json`:
```json
"test": "vitest run"
```

Create a minimal smoke test at `<test-dir>/smoke.test.ts` (using the same directory detected above):
```ts
import { describe, expect, test } from "vitest";

describe("smoke", () => {
  test("project loads", () => {
    expect(true).toBe(true);
  });
});
```

### Step 4: Create the GitHub Actions workflow

**Before creating the workflow**, check if a `lint` script exists in `package.json`. Only include the "Lint" step in the workflow if a lint script is present. If there is no lint script, omit the Lint step entirely to avoid CI failures.

Create `.github/workflows/ci.yml`:

**For bun projects:**
```yaml
name: CI

on:
  push:
    branches: ["**"]
  pull_request:
    branches: [main]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      - uses: oven-sh/setup-bun@v2

      - run: bun install --frozen-lockfile

      - name: Lint
        run: bun run lint

      - name: Test
        run: bun test
```

**For npm projects:**
```yaml
name: CI

on:
  push:
    branches: ["**"]
  pull_request:
    branches: [main]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      - uses: actions/setup-node@v4
        with:
          node-version: lts/*
          cache: npm

      - run: npm ci

      - name: Lint
        run: npm run lint

      - name: Test
        run: npm test
```

Adapt similarly for yarn/pnpm if detected.

### Step 5: Verify locally

Run the lint and test commands locally to make sure they pass:

```bash
bun run lint   # or npm run lint
bun test       # or npm test
```

If lint fails, fix the issues before continuing. If tests fail, check the smoke test.

### Step 6: Commit and push

```bash
git add .github/workflows/ci.yml __tests__/smoke.test.ts package.json package-lock.json yarn.lock pnpm-lock.yaml bun.lockb bun.lock 2>/dev/null
git commit -m "ci: add GitHub Actions CI — lint and unit tests on every push"
git push
```

### Step 7: Verify CI runs

```bash
gh run list --limit 1
```

If a run is in progress, watch it:
```bash
gh run watch --exit-status
```

Report the result to the user:

> CI is set up and running! Here's what happened:
> - **Status:** [passed / failed]
> - **Time:** [Xs]
>
> From now on, every time code is pushed, it'll automatically check for lint errors and run your tests. If something breaks, you'll see it on the PR before it goes live.

If CI failed, debug and fix the issue before moving on.

### Step 8: Summary

> CI is live! Here's what's in place:
> - **Lint check** — catches code style issues automatically
> - **Unit tests** — runs on every push (just a smoke test for now — real tests get added as you build features)
> - **Workflow file:** `.github/workflows/ci.yml`
>
> As you build features, the `/unit-tests` command will add real tests. CI will run them automatically — you don't need to think about it.
