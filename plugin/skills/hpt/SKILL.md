---
name: hpt
description: >
  Hyptrain shipping workflow orchestrator. Routes user requests to the appropriate
  hpt skill. Use when the user says "save", "commit", "push", "review",
  "check my diff", "touchup", "polish", "tests", "unit tests", "close",
  "merge", "ship it", "done", "deploy", "is it live", "prototype",
  "build this feature", or "implement this plan".
allowed-tools: "Skill"
version: "1.0.0"
author: "Brian Miller"
license: "MIT"
compatible-with: claude-code
tags: [shipping, workflow, deploy, review, testing, prototype]
---

# HPT — Hyptrain Shipping Workflow

Complete shipping workflow for Claude Code. Routes user intent to the right skill automatically.

## Routing Rules

When the user's request matches a shipping workflow action, invoke the appropriate hpt skill using the Skill tool as your FIRST action. Do NOT answer directly, do NOT use other tools first.

| User says | Invoke |
|-----------|--------|
| "Save", commit, push, create PR | `hpt:save` |
| Thorough code review, check my diff | `hpt:review` |
| Quick polish, touchup, pre-merge check, fix PR comments | `hpt:touchup` |
| Unit tests, add tests, test coverage, write tests | `hpt:unit-tests` |
| Close, merge, ship it, "done", "we're good" | `hpt:close` |
| Deploy, check deployment, is it live | `hpt:deploy` |
| Prototype, build this feature, implement this plan | `hpt:prototype` |

## Workflow

The typical flow is:

1. `hpt:prototype` — implement a feature from a plan
2. `hpt:save` — commit, push, create PR
3. `hpt:review` — thorough code review with parallel subagents
4. `hpt:touchup` — quick polish pass
5. `hpt:unit-tests` — add tests for PR changes
6. `hpt:deploy` — verify deployment is healthy
7. `hpt:close` — merge PR and wrap up

Skills can be used individually or as part of the full prototype workflow.
