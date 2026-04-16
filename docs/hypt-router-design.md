# Hypt Router Design

## Overview

The hypt router is a single entry point that listens to what you say and
sends you to the right skill automatically. Instead of memorizing 22
different commands, you just describe what you want in plain English and
the router figures out which skill to run. Think of it as a receptionist
who directs you to the right department. There are 20 skills in total.

## How Routing Works

When you type a message, the router scans it for keywords and phrases,
then dispatches the matching skill:

```
                        ┌──────────────────────┐
                        │  You type something  │
                        │   "fix this bug"     │
                        └──────────┬───────────┘
                                   │
                                   v
                  ┌────────────────────────────────┐
                  │       hypt:hypt (router)       │
                  │                                │
                  │  Scans your message for phrases│
                  │  like "fix", "bug", "broken"   │
                  └────────────────┬───────────────┘
                                   │
                          match found?
                         /            \
                       yes             no
                       /                \
                      v                  v
        ┌──────────────────┐   ┌──────────────────┐
        │  Invoke matched  │   │  Ask you to      │
        │  skill: hypt:fix │   │  clarify         │
        └──────────────────┘   └──────────────────┘
```

**Phrase matching examples:**

```
  Your words                          Matched skill
  ─────────────────────────────────── ─────────────────
  "I have an idea"              ───►  hypt:start
  "commit and push"             ───►  hypt:save
  "something's wrong"           ───►  hypt:fix
  "ship it"                     ───►  hypt:close
  "yolo"                        ───►  hypt:yolo
  "what should I work on next"  ───►  hypt:suggestions
```

## Skill Categories

The 20 skills fall into three groups:

### Atomic Skills (16)

These do one job. They are the building blocks.

```
 ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
 │    start     │ │    save      │ │   review     │
 │  Onboarding  │ │ Commit & PR  │ │ Code review  │
 └──────────────┘ └──────────────┘ └──────────────┘
 ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
 │   touchup    │ │  unit-tests  │ │    close     │
 │ Quick polish │ │ Write tests  │ │ Merge & wrap │
 └──────────────┘ └──────────────┘ └──────────────┘
 ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
 │ suggestions  │ │   deploy     │ │   status     │
 │  Next tasks  │ │ Ship to prod │ │  Site check  │
 └──────────────┘ └──────────────┘ └──────────────┘
 ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
 │   restore    │ │ post-mortem  │ │ plan-critic  │
 │  Rollback    │ │ What broke?  │ │ Review plan  │
 └──────────────┘ └──────────────┘ └──────────────┘
 ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
 │  prototype   │ │     fix      │ │    docs      │
 │ Build it     │ │ Fix bugs     │ │ Update docs  │
 └──────────────┘ └──────────────┘ └──────────────┘
 ┌──────────────┐
 │   ci-setup   │
 │ Set up CI    │
 └──────────────┘
```

### Composition Skills (2)

These chain multiple atomic skills together in sequence.

```
 ┌──────────────┐   ┌──────────────┐
 │   pipeline   │   │  autoclose   │
 │ Full dev flow│   │ Auto-merge   │
 └──────────────┘   └──────────────┘
```

### Shortcut Skills (2)

These combine composition skills for maximum speed.

```
 ┌──────────────┐   ┌──────────────┐
 │      go      │   │     yolo     │
 │Ship + confirm│   │ Ship, no ask │
 └──────────────┘   └──────────────┘
```

## Composition Diagrams

### pipeline

The full development pipeline. Takes code from research all the way
through to a saved PR.

```
 ┌──────────┐   ┌──────────┐   ┌───────────┐   ┌───────────┐
 │ research │──►│   plan   │──►│plan-critic│──►│ prototype │
 └──────────┘   └──────────┘   └───────────┘   │  (build)  │
                                                └─────┬─────┘
                                                      │
                                                      v
 ┌──────────┐   ┌──────────┐   ┌───────────┐   ┌───────────┐
 │   save   │◄──│   docs   │◄──│unit-tests │◄──│  review   │
 └──────────┘   └──────────┘   └───────────┘   │   loop    │
                                                └───────────┘
```

### autoclose

Handles everything after the code is ready: polish, merge, deploy,
and version bump.

```
 ┌───────────┐  ┌──────────┐   ┌───────────┐   ┌───────────┐
 │  touchup  │─►│   docs   │──►│suggestions│──►│   merge   │
 │(if needed)│  └──────────┘   └───────────┘   └─────┬─────┘
 └───────────┘                                       │
                                                     v
                ┌──────────┐   ┌───────────┐   ┌───────────┐
                │ release  │◄──│  version  │◄──│  deploy   │
                └──────────┘   │   bump    │   │   check   │
                               └───────────┘   └───────────┘
```

### go

Runs the full pipeline, pauses for your OK, then autocloses.

```
 ┌──────────────────────────┐     ┌─────────────┐
 │        pipeline          │────►│ CONFIRMATION│
 │ research ► plan ► build  │     │    GATE     │
 │ review ► test ► save     │     │             │
 └──────────────────────────┘     │  You say OK │
                                  └──────┬──────┘
                                         │
                                         v
                              ┌──────────────────┐
                              │    autoclose     │
                              │ merge ► deploy   │
                              │ version ► release│
                              └──────────────────┘
```

### yolo

Same as go, but skips the confirmation gate entirely.

```
 ┌──────────────────────────┐     ┌──────────────────┐
 │        pipeline          │────►│    autoclose     │
 │ research ► plan ► build  │     │ merge ► deploy   │
 │ review ► test ► save     │     │ version ► release│
 └──────────────────────────┘     └──────────────────┘

           No stopping. No asking. Just ships.
```

## Typical Development Workflow

A full project lifecycle from start to finish:

```
 0           1            2             3           4
 ┌───────┐  ┌──────────┐  ┌───────────┐  ┌───────┐  ┌──────┐
 │ start │─►│ ci-setup │─►│ prototype │─►│  fix  │─►│ save │
 └───────┘  └──────────┘  └───────────┘  └───────┘  └──┬───┘
                                                        │
     ┌──────────────────────────────────────────────────┘
     │
     v
 5           6            7             8           9
 ┌────────┐  ┌──────────┐  ┌───────────┐  ┌───────┐  ┌──────┐
 │ review │─►│ touchup  │─►│unit-tests │─►│status │─►│deploy│
 └────────┘  └──────────┘  └───────────┘  └───────┘  └──┬───┘
                                                        │
     ┌──────────────────────────────────────────────────┘
     │
     v
 10             10a           11            12           13
 ┌────────────┐ ┌───────────┐ ┌───────────┐ ┌──────────┐ ┌───────┐
 │  restore   │►│   post-   │►│   docs    │►│suggest-  │►│ close │
 │ (if needed)│ │  mortem   │ └───────────┘ │  ions    │ └───────┘
 └────────────┘ └───────────┘               └──────────┘
```

Most projects won't need every step. The router lets you jump to
whichever skill you need at any point.

## Quick Reference

| #  | Skill           | Category    | What it does                                           | Trigger phrases                                         |
|----|-----------------|-------------|--------------------------------------------------------|---------------------------------------------------------|
| 1  | start           | Atomic      | Onboard a new project, understand your idea            | "start", "get started", "I have an idea"                |
| 2  | save            | Atomic      | Commit, push, and create or update a PR                | "save", "commit", "push", "create PR"                   |
| 3  | review          | Atomic      | Thorough code review of your diff                      | "code review", "check my diff", "review my work"        |
| 4  | touchup         | Atomic      | Quick polish before merging                            | "touchup", "quick polish", "fix PR comments"            |
| 5  | unit-tests      | Atomic      | Write or extend unit tests                             | "unit tests", "add tests", "test coverage"              |
| 6  | close           | Atomic      | Merge, check off tasks, wrap up                        | "close", "merge", "ship it", "done"                     |
| 7  | suggestions     | Atomic      | Suggest what to work on next                           | "suggestions", "what should I work on next", "backlog"  |
| 8  | deploy          | Atomic      | Check or fix deployment health                         | "deploy", "check deployment", "fix deployment"          |
| 9  | status          | Atomic      | Quick check: is my site up?                            | "status", "is it live", "is my site up"                 |
| 10 | restore         | Atomic      | Rollback to a previous working version                 | "restore", "rollback", "revert", "undo deploy"          |
| 11 | post-mortem     | Atomic      | Analyze what went wrong after an incident              | "post-mortem", "incident report", "what went wrong"     |
| 12 | plan-critic     | Atomic      | Review and critique a plan before building             | "review plan", "critique plan", "check my plan"         |
| 13 | prototype       | Atomic      | Build a feature end-to-end                             | "prototype", "build this feature", "implement this"     |
| 14 | fix             | Atomic      | Diagnose and fix bugs                                  | "fix", "bug", "broken", "not working", "error"          |
| 15 | docs            | Atomic      | Update project documentation                           | "update docs", "refresh docs", "documentation"          |
| 16 | ci-setup        | Atomic      | Set up continuous integration                          | "set up CI", "add CI", "automatic testing"              |
| 17 | pipeline        | Composition | Full dev flow: research through saved PR               | "run pipeline", "review and test", "get this PR-ready"  |
| 18 | autoclose       | Composition | Auto-merge, deploy, version bump, release              | "autoclose", "auto merge", "merge without asking"       |
| 19 | go              | Shortcut    | Pipeline + confirmation + autoclose                    | "go", "go mode", "ship with confirmation"               |
| 20 | yolo            | Shortcut    | Pipeline + autoclose, no confirmation                  | "yolo", "yolo it", "just ship it"                       |
