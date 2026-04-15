# Security Scan

hypt-claude includes a supply chain security scanner that detects prompt injection, invisible Unicode attacks, shell injection, tool poisoning, and structural anomalies in contributions.

## Why this matters

hypt-claude is a Claude Code plugin with an auto-update mechanism. Code merged to `main` is automatically pulled and executed on user machines. A single malicious PR could compromise thousands of users silently.

## What it checks

### Pass 1: Unicode / Encoding Attacks (HIGH)
- Zero-width characters (U+200B, U+200C, U+200D, U+FEFF, U+00AD)
- Bidirectional text overrides (Trojan Source attack)
- Unicode tag characters (Glassworm-style invisible payloads)
- Variation selectors (invisible text modifiers)

### Pass 2: Prompt Injection (CRITICAL) — scoped to `plugin/**/*.md`
- Instruction override attempts ("ignore previous instructions", "you are now", etc.)
- Fake role/system delimiters (`<system>`, `[SYSTEM]`, `### Human:`)
- Data exfiltration via markdown images with variable interpolation
- Encoded instruction hiding (base64 decode, eval() in prompt files)

### Pass 3: Shell Injection / RCE (CRITICAL)
- Pipe to shell (`curl | bash`, `wget | sh`)
- Process substitution (`bash <(...)`)
- `eval` with variable expansion
- Writes to sensitive system paths (`~/.ssh/`, `/etc/`)
- Dangerous commands (netcat listeners, chmod 777, setuid)
- Network calls to unrecognized domains

### Pass 4: Tool Poisoning / Config Manipulation (MEDIUM)
- Non-standard tools in `allowed-tools` YAML frontmatter
- MCP tool references in skill files
- `settings.json` manipulation outside established config managers
- Hook registrations outside `hypt-settings-hook`

### Pass 5: Structural Anomalies (MEDIUM/LOW)
- Executable files outside `bin/`
- Unexpected file types in `plugin/` (Python, Ruby, binaries)
- Hidden files in `plugin/`
- Symlinks, large files (>50KB)

## Risk levels

| Level | Blocks merge? | Examples |
|-------|:---:|---------|
| CRITICAL | Yes | Prompt injection keywords, curl-pipe-bash, eval |
| HIGH | Yes | Invisible Unicode, encoding obfuscation, data exfiltration |
| MEDIUM | Yes | Non-standard tools, config manipulation, unknown network calls |
| LOW | No | Large files, symlinks (informational only) |

## Running locally

```bash
# Full scan (same as CI)
bin/hypt-security-scan --mode blocking --all

# Advisory mode (always exits 0)
bin/hypt-security-scan --mode advisory --all

# Only scan changed files (PR mode)
bin/hypt-security-scan --mode blocking --diff-only

# Verify the scanner itself works
bin/hypt-security-scan --self-test

# GitHub Actions annotations format
bin/hypt-security-scan --mode blocking --diff-only --format github

# Markdown output (like the PR comment)
bin/hypt-security-scan --mode advisory --all --format markdown
```

## Resolving findings

### False positives

If the scanner flags legitimate code, add an allowlist entry to `bin/hypt-security-scan`:

```bash
ALLOWLIST=(
  # Explanation of why this pattern is safe
  "file/path:pattern_substring"
)
```

Rules:
1. Every entry **must** have a comment explaining why it's safe
2. The entry is `file_substring:line_substring` — both must match to suppress
3. Keep entries as narrow as possible (match the specific flag/pattern, not just the filename)

### True positives

If the scanner finds a real issue, fix the code:
- **Prompt injection**: Remove or rephrase the instruction override language
- **Unicode**: Remove invisible characters (use `cat -A` to see them)
- **Shell injection**: Use safer patterns (quote variables, avoid eval, don't pipe to shell)
- **Tool poisoning**: Only use approved tools: `Bash, Read, Write, Edit, Grep, Glob, Agent, Skill`

## Known limitations

- **Line-oriented matching**: Prompt injection patterns match within single lines only. A multi-line injection that splits keywords across lines (e.g., `ignore previous\ninstructions`) will evade detection. This is a deliberate trade-off for speed and simplicity — multi-line regex in bash/grep is brittle. If you suspect a multi-line attack, review the diff manually.

## CI behavior

The scanner runs as a GitHub Actions workflow on:
- **Pull requests to `main`**: Scans changed files, posts results as a PR comment, blocks merge if CRITICAL/HIGH/MEDIUM findings exist
- **Pushes to `main`**: Scans all files as a safety net

### Branch protection setup (one-time)

To make the scanner a required check:
1. Go to Settings > Branches > Branch protection rules
2. Add rule for `main`
3. Enable "Require status checks to pass before merging"
4. Search for and add "Security Scan"
