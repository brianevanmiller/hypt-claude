# HYPT — Hyptrain Shipping Workflow Plugin

A Claude Code plugin that provides a complete shipping workflow: implement, review, test, deploy, and close.

## Skills

| Command | Description |
|---------|-------------|
| `hypt:start` | Onboarding — describe your idea, set up accounts, create a build plan |
| `hypt:save` | Commit, push, and create/update PR automatically |
| `hypt:review` | Thorough PR review with 4 parallel subagents — auto-fixes urgent issues |
| `hypt:touchup` | Quick pre-merge polish — fix PR comments, build issues, update docs |
| `hypt:unit-tests` | Smart unit test generation prioritized by business criticality |
| `hypt:deploy` | Verify deployment health — detects platform automatically |
| `hypt:close` | Suggest next tasks, update backlog, confirm before merge, verify deployment, and release |
| `hypt:autoclose` | Autonomous close — merge, deploy check, version bump, release (no confirmation) |
| `hypt:pipeline` | Full development pipeline — research, plan, build, review, test, save PR (no merge) |
| `hypt:go` | Autonomous pipeline + confirm before merge |
| `hypt:yolo` | Fully autonomous — pipeline + merge, no stopping |
| `hypt:suggestions` | Suggest next tasks and track them in your project backlog |
| `hypt:plan-critic` | Critical plan review — find gaps, ask questions, refine before building |
| `hypt:prototype` | End-to-end: review plan, implement, review x2, test, and deliver |

## Installation

Tell Claude Code:

> Install this plugin: https://github.com/brianevanmiller/hypt-claude

Or install manually:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/brianevanmiller/hypt-claude/main/install.sh)
```

After installation, restart Claude Code (`/exit` then relaunch).

## Supported Deployment Platforms

The deploy and close skills automatically detect your deployment platform:

- **Vercel** (`vercel.json` or `.vercel/`)
- **Netlify** (`netlify.toml` or `_redirects`)
- **Fly.io** (`fly.toml`)
- **Render** (`render.yaml`)
- **Railway** (`railway.json` or `railway.toml`)
- **Generic** — falls back to GitHub Deployments API

## Requirements

- [GitHub CLI](https://cli.github.com/) (`gh`) — used for PR management, deployment checks
- Git
- [Bun](https://bun.sh/) — runtime, package manager, and task runner

## Workflow

The typical development flow:

```
start -> prototype -> save -> review -> touchup -> unit-tests -> deploy -> close
```

Shortcuts compose the pipeline and close skills:

```
/go   = pipeline -> confirm -> autoclose   (autonomous with safety net)
/yolo = pipeline -> autoclose              (fully autonomous)
```

Each skill can also be used independently. For example, use `hypt:save` anytime you want to commit and push, or `hypt:review` for a standalone code review.

## License

MIT
