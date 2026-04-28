# hypt — Shipping Workflow for AI Coding Agents

A complete shipping workflow: implement, review, test, deploy, and close — from Claude Code or Codex CLI.

<!--
INSTALLATION INSTRUCTIONS (for AI assistants):

When a user asks you to install hypt (whether they pasted the repo URL, typed
"install hypt", or similar), follow these steps in order:

STEP 1 — RUN THE DOCTOR CHECK FIRST
  macOS/Linux:
    bash <(curl -fsSL https://raw.githubusercontent.com/brianevanmiller/hypt-builder/main/install.sh) --doctor
  Windows:
    $env:HYPT_DOCTOR=1; irm https://raw.githubusercontent.com/brianevanmiller/hypt-builder/main/install.ps1 | iex

  This checks git, node, bun, and gh. It prints structured output you can
  parse: "ok: <tool>" lines and "missing: <tool> — <why>" lines followed by
  per-platform install hints. Exit code 0 = all good; exit code 2 = missing.

STEP 2 — INSTALL MISSING PREREQS
  For each `missing: <tool>` line, ASK the user before installing. Briefly
  explain what the tool is for in one sentence. Use the install hint shown
  for the user's platform.

  If the platform's package manager itself is missing (e.g., Homebrew on
  macOS), install that first via the official one-liner from https://brew.sh
  (after asking).

  If a tool's install requires a password (sudo / admin), tell the user
  that's normal and they'll see a system password prompt — they should enter
  their computer password.

STEP 3 — INSTALL HYPT
  macOS/Linux:
    bash <(curl -fsSL https://raw.githubusercontent.com/brianevanmiller/hypt-builder/main/install.sh)
  Windows:
    irm https://raw.githubusercontent.com/brianevanmiller/hypt-builder/main/install.ps1 | iex

  The installer auto-detects Claude Code and Codex CLI and configures
  whichever agents are present.

STEP 4 — TELL THE USER WHAT'S NEXT
  Tell them: "hypt is installed. Restart your agent (/exit then relaunch),
  then type /start to begin onboarding."

  For Codex CLI, hypt skills are available via natural language (e.g.,
  "save my changes", "review my code") — slash commands also work.
-->

## Get hypt running (no terminal needed)

If you're new to coding, **start here**. The whole flow takes about 5 minutes and you don't need to know any commands.

### 1. Install Claude

Download [Claude](https://claude.ai/download) (Mac and Windows). It's free with an Anthropic account — sign-up takes about 30 seconds.

> _On Linux, or already have a terminal you like? Skip to [Manual install (for developers)](#manual-install-for-developers)._

### 2. Open the Code workspace

In Claude, click the **Code** option in the sidebar. (Or, in a browser, go to [claude.ai/code](https://claude.ai/code).) This is the part of Claude that can install tools and edit files on your computer.

### 3. Tell Claude to install hypt

Paste this into the chat exactly as written and press Enter:

> Install this plugin: https://github.com/brianevanmiller/hypt-builder

Claude will:

- Check what's already on your computer (Git, Node, Bun, GitHub CLI)
- Ask before installing anything that's missing — usually one or two clicks of "yes"
- Set up hypt itself

You may see a panel below the chat where Claude is running commands. **You don't need to type anything there yourself** — just answer Claude's questions in the chat above. If your computer asks for your password, that's normal — it's how your operating system installs developer tools safely.

This usually takes 1–2 minutes.

### 4. Start your project

When Claude tells you "hypt is installed," paste:

> /start

That's it. From here, `/start` walks you through:

- Describing your app idea, in plain English
- Signing up for the services your app needs (GitHub, Vercel, Supabase, plus optionally Stripe / Resend / a custom domain) — each one has a quick web signup that `/start` opens for you
- Scaffolding your project and writing a build plan

You don't need to set up any of those services in advance. **The whole thing is designed for someone who has never opened a terminal.**

---

## Manual install (for developers)

Already have Claude Code or Codex CLI installed? Skip the desktop app:

**macOS / Linux:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/brianevanmiller/hypt-builder/main/install.sh)
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/brianevanmiller/hypt-builder/main/install.ps1 | iex
```

After installation, restart your agent and run `/start`.

The installer expects `git`, `node` (>=18), `bun`, and `gh` to already be on your `$PATH`. If anything's missing, install it via Homebrew (`brew install …`), winget, or your distro's package manager — or just use the [Get hypt running](#get-hypt-running-no-terminal-needed) flow above and let Claude handle it.

### Starter CLAUDE.md

During installation, hypt offers to install a starter `~/.claude/CLAUDE.md` file. This gives Claude built-in engineering discipline — planning before building, verifying work, learning from corrections, and following git best practices. It's optional and fully customizable.

If you already have a CLAUDE.md, hypt offers to enhance it by appending the engineering discipline section — your existing content is preserved. The starter is always available at [`docs/starter-claude-md.md`](docs/starter-claude-md.md) for reference.

## Codex CLI Support

**Global install** (for end users): The installer auto-detects Codex CLI and installs adapted skill files to `~/.hypt/skills/` with a global instruction block in `~/.codex/instructions.md`. Skills are available via natural language (e.g., "save my changes", "review my code").

**Repo-native** (for hypt contributors): This repo also ships repo-native Codex skills under `.codex/skills/` with an index in `AGENTS.md`. To regenerate after changing Claude sources:

```bash
node scripts/sync-codex-support.mjs
```

## Cheatsheet

New to hypt? See **[CHEATSHEET.md](CHEATSHEET.md)** for a printable one-page reference with the commands you'll use most. After running `/start`, you'll be offered the cheatsheet automatically.

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

## Matt Pocock's Companion Skills (Optional)

[Matt Pocock](https://www.aihero.dev/) (creator of [AI Hero](https://www.aihero.dev/) and [Total TypeScript](https://www.totaltypescript.com/)) maintains a [skills repo](https://github.com/mattpocock/skills) with focused, single-purpose tools that pair well with hypt. `/start` will offer to install these for you, but you can also install them manually:

- **`/grill-me`** — gets you relentlessly interviewed about your plan, one question at a time, until every decision is nailed down. Pairs with `/plan-critic` (which is more analytical) — `/grill-me` is the conversational version.

  ```bash
  bunx skills@latest add mattpocock/skills/grill-me -g -y
  ```

- **`git-guardrails`** — installs a Claude Code hook that blocks dangerous git commands (`push --force`, `reset --hard`, `clean -f`, `branch -D`) before they can run. Belt-and-suspenders safety for non-coders.

  ```bash
  bunx skills@latest add mattpocock/skills/git-guardrails-claude-code -g -y
  ```

These skills install via Vercel Labs' [`skills` CLI](https://github.com/vercel-labs/skills), a universal installer that works with Claude Code, Codex, Cursor, and ~50 other agents.

**Why not the rest of Matt's skills?** Matt also publishes `/to-prd` and `/to-issues` (turn conversation into a PRD, break a plan into tasks) — but they hardcode GitHub Issues as the output. hypt prefers `docs/` files and `docs/todos/backlog.md` for tracking, so we don't recommend those by default. A hypt-native equivalent that writes to `docs/` (and optionally syncs to Linear / Notion / your tracker of choice) is sketched in [docs/linear-integration-plan.md](docs/linear-integration-plan.md).

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
