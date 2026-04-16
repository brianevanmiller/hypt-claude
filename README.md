# hypt — Shipping Workflow for AI Coding Agents

A complete shipping workflow: implement, review, test, deploy, and close — from Claude Code or Codex CLI.

<!--
INSTALLATION INSTRUCTIONS (for AI assistants):

CLAUDE CODE:
  bash <(curl -fsSL https://raw.githubusercontent.com/brianevanmiller/hypt-claude/main/install.sh)
  After: tell user to restart Claude Code (/exit then relaunch), then run /start

CODEX CLI:
  bash <(curl -fsSL https://raw.githubusercontent.com/brianevanmiller/hypt-claude/main/install.sh)
  The installer auto-detects Codex CLI and installs global instructions.
  After: tell user to restart their Codex session. Hypt skills are available
  via natural language (e.g., "save my changes", "review my code").

The installer auto-detects which agents are installed and configures all of them.
-->

## Install

Tell your AI agent:

> Install this plugin: https://github.com/brianevanmiller/hypt-claude

This works with **Claude Code** and **Codex CLI**. The installer auto-detects
which agents you have and configures both.

Or install manually:

**macOS / Linux:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/brianevanmiller/hypt-claude/main/install.sh)
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/brianevanmiller/hypt-claude/main/install.ps1 | iex
```

After installation, restart your agent.

## Codex CLI Support

**Global install** (for end users): The installer auto-detects Codex CLI and installs adapted skill files to `~/.hypt/skills/` with a global instruction block in `~/.codex/instructions.md`. Skills are available via natural language (e.g., "save my changes", "review my code").

**Repo-native** (for hypt contributors): This repo also ships repo-native Codex skills under `.codex/skills/` with an index in `AGENTS.md`. To regenerate after changing Claude sources:

```bash
node scripts/sync-codex-support.mjs
```

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
| `/fix` | Diagnose and fix bugs — triage, research, plan, and deliver a tested fix |
| `/deploy` | Verify deployment health — detects platform, auto-bypasses Vercel free-plan blocks |
| `/status` | Quick deployment status check — is my site up? |
| `/restore` | Restore to a previous working version — rollback, revert, database recovery, auto-investigates |
| `/post-mortem` | Analyze what went wrong after a restore — creates incident doc, updates backlog |
| `/docs` | Scan and update project documentation — checklists, READMEs, feature docs |
| `/close` | Suggest next tasks, update backlog, confirm before merge, verify deployment |
| `/todo` | Add or update items in your project's backlog, roadmap, or todo list |
| `/suggestions` | Suggest next tasks, group related items, and offer /yolo or /go activation |
| `/plan-critic` | Critical plan review — find gaps, ask questions, refine before building |
| `/go` | Autonomous pipeline + confirm before merge |
| `/yolo` | Fully autonomous pipeline + merge, no stopping |
| `/pipeline` | Full development pipeline — research, plan, build, review, test, save PR (no merge) |
| `/autoclose` | Autonomous merge — deploy check, version bump, release (no confirmation) |
| `/ci-setup` | Set up lightweight CI — runs unit tests on every commit |

## Workflow

Just type what you want — the router picks the right skill:

```
 ┌──────────────────┐     ┌────────────────┐     ┌──────────────┐
 │  "fix this bug"  │────►│  hypt router   │────►│   hypt:fix   │
 │  "ship it"       │     │ (phrase match)  │     │   hypt:close │
 │  "save"          │     └────────────────┘     │   hypt:save  │
 └──────────────────┘                            └──────────────┘
```

The typical development flow:

```
 start ─► prototype ─► save ─► review ─► touchup ─► tests ─► docs ─► deploy ─► close
```

Shortcuts compose skills into full pipelines:

```
 /go   = pipeline ─► confirm ─► autoclose    (autonomous with safety net)
 /yolo = pipeline ─► autoclose               (fully autonomous)
```

Each command can also be used independently. See [docs/hypt-router-design.md](docs/hypt-router-design.md) for detailed routing diagrams and skill composition.

## gstack Integration (Optional)

hypt works great on its own, but for the full experience, install [gstack](https://github.com/garrytan/gstack) — a free companion tool that adds 35+ specialist skills:

- **Visual QA testing** (`/qa`) — test your app in a real browser
- **Design review** (`/design-review`) — spot visual issues and AI design slop
- **Security audit** (`/cso`) — OWASP Top 10 + STRIDE threat model
- **Product thinking** (`/office-hours`) — YC-style forcing questions to sharpen your idea
- **Systematic debugging** (`/investigate`) — root-cause analysis for complex bugs
- **Design exploration** (`/design-shotgun`) — generate AI mockup variants
- **Performance testing** (`/benchmark`) — Core Web Vitals and page load times

When gstack is installed, hypt automatically detects it and:
- Routes QA, design, and security requests to gstack's specialist skills
- Escalates complex code reviews and bug investigations to gstack's deeper tools
- Offers product thinking via `/office-hours` during `/start` onboarding

Install gstack:
```bash
git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup
```

Or just tell your AI agent: "Install gstack"

**Without gstack**, hypt handles everything itself — code review, testing, deployment, and bug fixes. gstack adds depth for visual testing, design, and security that hypt doesn't cover natively.

## Supported Deployment Platforms

Vercel, Netlify, Fly.io, Render, Railway, and GitHub Deployments API (fallback).

## Security

Includes a supply chain security scanner that runs in CI on every PR to `main`. Detects prompt injection, invisible Unicode attacks, shell injection, tool poisoning, and structural anomalies. See [docs/security-scan.md](docs/security-scan.md) for details.

## Requirements

- [Node.js](https://nodejs.org/) — required by Claude Code and used by the installer
- [GitHub CLI](https://cli.github.com/) (`gh`)
- Git
- [Bun](https://bun.sh/) — runtime, package manager, and task runner (needed for `/start` and `/prototype`, not for install)

## License

MIT
