# HPT — Hyptrain Shipping Workflow Plugin

A Claude Code plugin that provides a complete shipping workflow: implement, review, test, deploy, and close.

## Skills

| Command | Description |
|---------|-------------|
| `hpt:save` | Commit, push, and create/update PR automatically |
| `hpt:review` | Thorough PR review with 4 parallel subagents — auto-fixes urgent issues |
| `hpt:touchup` | Quick pre-merge polish — fix PR comments, build issues, update docs |
| `hpt:unit-tests` | Smart unit test generation prioritized by business criticality |
| `hpt:deploy` | Verify deployment health — detects platform automatically |
| `hpt:close` | Merge PR, verify deployment, suggest next tasks |
| `hpt:prototype` | End-to-end: implement plan, review x2, test, and deliver |

## Installation

```
/plugin install hpt@hpt-claude
```

Or install from the GitHub URL directly:

```
/plugin install hpt from github:brianevanmiller/hpt-claude
```

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
- npm (for build/test commands)

## Workflow

The typical development flow:

```
prototype -> save -> review -> touchup -> unit-tests -> deploy -> close
```

Each skill can also be used independently. For example, use `hpt:save` anytime you want to commit and push, or `hpt:review` for a standalone code review.

## License

MIT
