# HYPT — Hyptrain Shipping Workflow

A shipping workflow plugin for AI coding agents (Claude Code, Codex CLI): implement, review, test, deploy, and close.

## Skills

| Command | Description |
|---------|-------------|
| `hypt:start` | Onboarding — describe your idea, set up accounts, create a build plan |
| `hypt:save` | Commit, push, and create/update PR automatically |
| `hypt:review` | Thorough PR review with 4 parallel subagents — auto-fixes urgent issues |
| `hypt:touchup` | Quick pre-merge polish — fix PR comments, build issues, update docs |
| `hypt:unit-tests` | Smart unit test generation prioritized by business criticality |
| `hypt:fix` | Diagnose and fix bugs — triage, research, plan, and deliver a tested fix |
| `hypt:deploy` | Verify deployment health — detects platform automatically |
| `hypt:status` | Quick deployment status check — is my site up? |
| `hypt:restore` | Restore to a previous working version — rollback, revert, database recovery, auto-investigates |
| `hypt:post-mortem` | Analyze what went wrong after a restore — creates incident doc, updates backlog |
| `hypt:docs` | Scan and update project documentation — checklists, READMEs, feature docs, dates |
| `hypt:close` | Suggest next tasks, update backlog, confirm before merge, verify deployment, and release |
| `hypt:autoclose` | Autonomous close — merge, deploy check, version bump, release (no confirmation) |
| `hypt:pipeline` | Full development pipeline — research, plan, build, review, test, save PR (no merge) |
| `hypt:go` | Autonomous pipeline + confirm before merge |
| `hypt:yolo` | Fully autonomous — pipeline + merge, no stopping |
| `hypt:todo` | Add or update items in your project's backlog, roadmap, or todo list |
| `hypt:suggestions` | Suggest next tasks, group related items, and offer /yolo or /go activation |
| `hypt:plan-critic` | Critical plan review — find gaps, ask questions, refine before building |
| `hypt:prototype` | End-to-end: review plan, implement, review x2, test, and deliver |
| `hypt:ci-setup` | Set up lightweight CI — runs unit tests on every commit |

## Installation

Tell your AI agent:

> Install this plugin: https://github.com/brianevanmiller/hypt-claude

Works with **Claude Code** and **Codex CLI** — the installer auto-detects which agents you have.

Or install manually:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/brianevanmiller/hypt-claude/main/install.sh)
```

After installation, restart your agent.

## Supported Deployment Platforms

The deploy, restore, and close skills automatically detect your deployment platform:

- **Vercel** (`vercel.json` or `.vercel/`)
- **Netlify** (`netlify.toml` or `_redirects`)
- **Fly.io** (`fly.toml`)
- **Render** (`render.yaml`)
- **Railway** (`railway.json` or `railway.toml`)
- **Generic** — falls back to GitHub Deployments API

## Security

Includes a supply chain security scanner (`bin/hypt-security-scan`) that detects prompt injection, invisible Unicode, shell injection, tool poisoning, and structural anomalies. Runs in CI on PRs to `main`. See [docs/security-scan.md](../docs/security-scan.md) for details.

## Requirements

- [GitHub CLI](https://cli.github.com/) (`gh`) — used for PR management, deployment checks
- Git
- [Bun](https://bun.sh/) — runtime, package manager, and task runner

## Workflow

The typical development flow:

```
start -> prototype -> save -> review -> touchup -> unit-tests -> docs -> deploy -> close
```

Shortcuts compose the pipeline and close skills:

```
/go   = pipeline -> confirm -> autoclose   (autonomous with safety net)
/yolo = pipeline -> autoclose              (fully autonomous)
```

Each skill can also be used independently. For example, use `hypt:save` anytime you want to commit and push, or `hypt:review` for a standalone code review.

## License

MIT
