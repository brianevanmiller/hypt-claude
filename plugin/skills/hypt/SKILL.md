---
name: hypt
description: >
  Hyptrain shipping workflow orchestrator. Routes user requests to the appropriate
  hypt skill. Use when the user says "start", "new project", "get started",
  "I have an idea", "save", "commit", "push", "review", "check my diff",
  "touchup", "polish", "tests", "unit tests", "close", "merge", "ship it",
  "done", "deploy", "is it live", "prototype", "build this feature",
  "implement this plan", "review plan", "critique plan", "check my plan", "set up CI", or "add CI".
allowed-tools: "Skill"
version: "1.0.0"
author: "Brian Miller"
license: "MIT"
compatible-with: claude-code
tags: [shipping, workflow, deploy, review, testing, prototype]
---

# HYPT — Hyptrain Shipping Workflow

Complete shipping workflow for Claude Code. Routes user intent to the right skill automatically.

## Routing Rules

When the user's request matches a shipping workflow action, invoke the appropriate hypt skill using the Skill tool as your FIRST action. Do NOT answer directly, do NOT use other tools first.

| User says | Invoke |
|-----------|--------|
| "Start", new project, get started, set up, onboarding, "I have an idea" | `hypt:start` |
| "Save", commit, push, create PR | `hypt:save` |
| Thorough code review, check my diff | `hypt:review` |
| Quick polish, touchup, pre-merge check, fix PR comments | `hypt:touchup` |
| Unit tests, add tests, test coverage, write tests | `hypt:unit-tests` |
| Close, merge, ship it, "done", "we're good" | `hypt:close` |
| Deploy, check deployment, is it live | `hypt:deploy` |
| Review plan, critique plan, check my plan, plan review, plan critic | `hypt:plan-critic` |
| Prototype, build this feature, implement this plan | `hypt:prototype` |
| Set up CI, add CI, automatic testing, ci setup | `hypt:ci-setup` |

## Workflow

The typical flow is:

0. `hypt:start` — onboarding: describe your idea, set up accounts, create a plan
0.5. `hypt:ci-setup` — set up automatic lint + test CI (optional, runs at end of start)
1. `hypt:prototype` — review plan, implement, review, test, and deliver
2. `hypt:save` — commit, push, create PR
3. `hypt:review` — thorough code review with parallel subagents
4. `hypt:touchup` — quick polish pass
5. `hypt:unit-tests` — add tests for PR changes
6. `hypt:deploy` — verify deployment is healthy
7. `hypt:close` — merge PR and wrap up

Skills can be used individually or as part of the full prototype workflow.
