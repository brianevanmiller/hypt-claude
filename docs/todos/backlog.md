# Backlog

What to work on next — updated automatically by `/close`. Feel free to edit, reorder, or check things off.

## Security
<!-- Auth, permissions, data protection, input validation -->

## Bugs
<!-- Known issues and things that need fixing -->

## Features
<!-- New capabilities and enhancements -->

- [ ] Add a `--dry-run` flag to `hypt-vercel-bypass` for safer debugging
- [ ] Add package manager auto-detection to all skills — detect from lockfiles (like /ci-setup does) so /fix, /touchup, /prototype etc. work correctly for npm/yarn/pnpm projects too
- [ ] Add a /logs command for deployment error investigation — pull recent Vercel/Netlify build logs when /status shows something is down

## Performance
<!-- Speed, loading, optimization -->

## Testing
<!-- Test coverage gaps and missing tests -->

- [ ] Add automated tests for the bypass detection heuristic

## Documentation
<!-- Docs, guides, and READMEs that need updating -->

- [ ] Update README to document the full command set — cover /status, /fix, /ci-setup, /suggestions and other newer skills

## Cleanup
<!-- Tech debt, refactoring, code quality improvements -->

- [ ] Log which detection path triggered the bypass (exact SHA vs heuristic fallback)
