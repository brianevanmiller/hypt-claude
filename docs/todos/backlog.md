# Backlog

What to work on next — updated automatically by `/close`. Feel free to edit, reorder, or check things off.

## Security
<!-- Auth, permissions, data protection, input validation -->

- [ ] Add multi-line prompt injection detection using perl — the scanner currently only matches within single lines
- [ ] Add scanner coverage for fenced shell snippets in prompt files — catch dangerous commands inside markdown code blocks for Claude and Codex skill surfaces

## Bugs
<!-- Known issues and things that need fixing -->

## Features
<!-- New capabilities and enhancements -->

- [ ] Add a `/dry-run` mode for pipeline — run the full pipeline without committing or pushing, useful for previewing what would happen
- [ ] Add /save progress indicator to pipeline output — when /save runs during pipeline, briefly log which checkpoint triggered it so users can follow along
- [ ] Add a `--dry-run` flag to `hypt-vercel-bypass` for safer debugging
- [ ] Add package manager auto-detection to all skills — detect from lockfiles (like /ci-setup does) so /fix, /touchup, /prototype etc. work correctly for npm/yarn/pnpm projects too
- [ ] Add a /logs command for deployment error investigation — pull recent Vercel/Netlify build logs when /status shows something is down
- [ ] Add a `--watch` mode to the security scanner for real-time feedback during local development
- [ ] Add a global Codex install/sync workflow — publish generated hypt skills to `~/.codex/skills` for use outside this repo

## Performance
<!-- Speed, loading, optimization -->

## Testing
<!-- Test coverage gaps and missing tests -->

- [ ] Add /save idempotency test — verify /save handles all edge cases cleanly: clean tree, no PR, existing PR, rebase conflicts
- [ ] Add automated tests for the bypass detection heuristic
- [ ] Add scanner integration test that verifies `--markdown-report` flag and CI workflow exit codes end-to-end
- [ ] Add sync generator regression tests — verify alias rewriting skips code blocks, stale generated files are removed, and subdirectory `--check` works

## Documentation
<!-- Docs, guides, and READMEs that need updating -->

- [x] Update README to document the full command set — cover /status, /fix, /ci-setup, /suggestions and other newer skills

## Cleanup
<!-- Tech debt, refactoring, code quality improvements -->

- [ ] Log which detection path triggered the bypass (exact SHA vs heuristic fallback)
