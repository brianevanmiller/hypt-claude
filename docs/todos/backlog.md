# Backlog

What to work on next — updated automatically by `/close`. Feel free to edit, reorder, or check things off.

## Security
<!-- Auth, permissions, data protection, input validation -->

- [ ] Plumb `is_allowlisted` through remaining scanner checks (hook registrations, MCP tool refs, allowed-tools) — the settings.json check was bypassing the allowlist until v0.26.x; the same gap likely exists elsewhere and forces code changes for future false positives
- [ ] Add multi-line prompt injection detection using perl — the scanner currently only matches within single lines
- [ ] Add scanner coverage for fenced shell snippets in prompt files — catch dangerous commands inside markdown code blocks for Claude and Codex skill surfaces
- [ ] Add OAuth `state` parameter scaffold to /start integrations — provide a concrete CSRF-safe state token pattern (sign + verify) so the OAuth callback stub isn't left as a TODO comment

## Bugs
<!-- Known issues and things that need fixing -->

- [ ] Add pipeline continuation resilience — reinforce "keep moving" after every sub-skill return, not just after plan-critic

## Features
<!-- New capabilities and enhancements -->

- [ ] Implement the Linear integration sketched in `docs/linear-integration-plan.md` — land `hypt:breakdown` and the TRACKER abstraction so the design doc becomes shipping functionality
- [ ] Add Codex CLI support for starter CLAUDE.md — append engineering discipline block to `~/.codex/instructions.md` during Codex install path (mirrors the Claude Code CLAUDE.md feature)

- [ ] Add a `/dry-run` mode for pipeline — run the full pipeline without committing or pushing, useful for previewing what would happen
- [ ] Add /save progress indicator to pipeline output — when /save runs during pipeline, briefly log which checkpoint triggered it so users can follow along
- [ ] Add a `--dry-run` flag to `hypt-vercel-bypass` for safer debugging
- [ ] Add package manager auto-detection to all skills — detect from lockfiles (like /ci-setup does) so /fix, /touchup, /prototype etc. work correctly for npm/yarn/pnpm projects too
- [ ] Add a /logs command for deployment error investigation — pull recent Vercel/Netlify build logs when /status or /restore shows something is down
- [ ] Add /restore database auto-detection — detect Supabase, PlanetScale, or Neon from project config and provide platform-specific recovery steps automatically
- [ ] Add post-mortem history viewer — a /post-mortems command to list all past incidents from docs/post-mortem/ with status
- [ ] Add post-mortem → fix linking — when /fix resolves a post-mortem issue, auto-check off the action items in the post-mortem doc
- [ ] Add a `--watch` mode to the security scanner for real-time feedback during local development
- [x] Add a global Codex install/sync workflow — publish generated hypt skills to `~/.codex/skills` for use outside this repo
- [ ] Add support for additional AI coding agents — the multi-agent installer framework supports detection; Cursor, Windsurf, or Aider could be added next
- [x] Regenerate Codex adapted skills to include hypt-docs and hypt-post-mortem — run `node scripts/sync-codex-support.mjs` after merging
- [ ] Add provider OAuth signup walkthroughs to /start Phase 3b — walk users through Google Cloud Console, Notion integration, Slack app setup etc. (mirror the existing Stripe/Resend signup pattern) for each provider chosen in Q7b
- [ ] Add a `/harden` skill (or fold into /prototype) that implements the Production Hardening checklist — wire up Sentry, structured logging, rate limiting, RLS audit, uptime monitoring rather than just listing them as todos
- [ ] Add an admin route scaffold for the allowlist — when ALLOWLIST_MODE=team, scaffold a tiny owner-only page to add/remove emails so users don't have to edit Supabase SQL by hand

## Performance
<!-- Speed, loading, optimization -->

## Testing
<!-- Test coverage gaps and missing tests -->

- [ ] Add scanner self-test fixture for settings.json (CONFIG_MANIPULATION) allowlist suppression — mirror the existing curl allowlist positive test so the v0.26.x allowlist plumbing can't silently regress
- [ ] Automate `install.sh --doctor` / `install.ps1 -Doctor` assertions — run both with reduced PATH, assert exit 2 + structured `missing:` output; manual run on a fresh macOS Claude Desktop session and a real Windows box still need real-machine QA
- [ ] Add starter CLAUDE.md install test — verify all three paths (fresh install, enhance existing, idempotent update) and non-interactive skip

- [ ] Add /restore integration test — verify merge vs squash commit detection and correct revert strategy selection
- [ ] Add plan-critic complexity classification test — verify small/large detection with sample plans of varying sizes and scopes
- [ ] Add /save idempotency test — verify /save handles all edge cases cleanly: clean tree, no PR, existing PR, rebase conflicts
- [ ] Add automated tests for the bypass detection heuristic
- [ ] Add scanner integration test that verifies `--markdown-report` flag and CI workflow exit codes end-to-end
- [ ] Add sync generator regression tests — verify alias rewriting skips code blocks, stale generated files are removed, and subdirectory `--check` works
- [ ] Add end-to-end test for Codex install path — verify install.sh detects Codex, generates adapted skills, and writes idempotent instructions.md
- [ ] Add `--check` flag to hypt-codex-adapt for CI validation — verify adapted skills stay in sync with source SKILL.md files
- [ ] Add docs skill integration test — verify semantic checkbox matching works with varied PR titles and backlog item phrasing
- [ ] Add post-mortem skill integration test — verify correct identification of reverted commits and post-mortem doc generation
- [ ] Add /start integration test for new branches — verify Q5b allowlist scaffolding, Q7b integrations scaffolding, and Step 4c.5 production-hardening produce the expected files (migrations, lib/integrations stubs, vercel.json cron entry, plan section)

## Documentation
<!-- Docs, guides, and READMEs that need updating -->

- [x] Update README to document the full command set — cover /status, /fix, /ci-setup, /suggestions and other newer skills

## Cleanup
<!-- Tech debt, refactoring, code quality improvements -->

- [ ] Log which detection path triggered the bypass (exact SHA vs heuristic fallback)
