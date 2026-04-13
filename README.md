# hypt — Shipping Workflow Plugin for Claude Code

A complete shipping workflow: implement, review, test, deploy, and close — all from Claude Code.

<!--
CLAUDE CODE INSTALLATION INSTRUCTIONS (for AI assistants):
If a user asks you to install this plugin, run this single command:
bash <(curl -fsSL https://raw.githubusercontent.com/brianevanmiller/hypt-claude/main/install.sh)
This handles everything: cloning, caching, config updates. After it completes, tell the user to restart Claude Code (/exit then relaunch).
-->

## Install

Tell Claude Code:

> Install this plugin: https://github.com/brianevanmiller/hypt-claude

Or install manually:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/brianevanmiller/hypt-claude/main/install.sh)
```

After installation, restart Claude Code (`/exit` then relaunch).

## Commands

All commands use the `hypt:` prefix (e.g., type `/start` or `/hypt` and Claude will route to the right one):

| Command | Description |
|---------|-------------|
| `/start` | Onboarding — describe your idea, set up accounts, create a build plan |
| `/prototype` | End-to-end: review plan, implement, review x2, test, and deliver |
| `/save` | Commit, push, and create/update PR automatically |
| `/review` | Thorough PR review with 4 parallel subagents — auto-fixes urgent issues |
| `/touchup` | Quick pre-merge polish — fix PR comments, build issues, update docs |
| `/unit-tests` | Smart unit test generation prioritized by business criticality |
| `/deploy` | Verify deployment health — detects platform automatically |
| `/close` | Merge PR, verify deployment, suggest next tasks |
| `/plan-critic` | Critical plan review — find gaps, ask questions, refine before building |

## Workflow

```
start → prototype → save → review → touchup → unit-tests → deploy → close
```

Each command can also be used independently.

## Supported Deployment Platforms

Vercel, Netlify, Fly.io, Render, Railway, and GitHub Deployments API (fallback).

## Requirements

- [GitHub CLI](https://cli.github.com/) (`gh`)
- Git
- [Bun](https://bun.sh/) — runtime, package manager, and task runner (needed for `/start` and `/prototype`, not for install)

## License

MIT
