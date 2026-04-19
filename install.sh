#!/usr/bin/env bash
set -euo pipefail

# hypt plugin installer — auto-detects Claude Code and Codex CLI
# Usage: bash install.sh
#   or:  bash <(curl -fsSL https://raw.githubusercontent.com/brianevanmiller/hypt-builder/main/install.sh)

PLUGIN_NAME="hypt"
MARKETPLACE_NAME="hypt-builder"
REPO="brianevanmiller/hypt-builder"
PLUGIN_KEY="${PLUGIN_NAME}@${MARKETPLACE_NAME}"
CLAUDE_DIR="$HOME/.claude"
PLUGINS_DIR="$CLAUDE_DIR/plugins"
MARKETPLACE_DIR="$PLUGINS_DIR/marketplaces/$MARKETPLACE_NAME"
HYPT_DIR="$HOME/.hypt"
CODEX_DIR="$HOME/.codex"

# --- Detect which agents are installed ---
HAS_CLAUDE=false
HAS_CODEX=false

if [ -d "$CLAUDE_DIR" ] || command -v claude &>/dev/null; then
  HAS_CLAUDE=true
fi

if [ -d "$CODEX_DIR" ] || command -v codex &>/dev/null; then
  HAS_CODEX=true
fi

# If neither detected, default to Claude (the primary target)
if [ "$HAS_CLAUDE" = false ] && [ "$HAS_CODEX" = false ]; then
  HAS_CLAUDE=true
fi

# --- Preflight checks ---
if ! command -v git &>/dev/null; then
  echo "Error: git is required. Install it and try again."
  exit 1
fi

if ! command -v node &>/dev/null; then
  echo "Error: node is required (Claude Code depends on Node.js)."
  echo "  Install it from https://nodejs.org/ and try again."
  exit 1
fi

# ============================================================
# CLAUDE CODE INSTALL
# ============================================================
if [ "$HAS_CLAUDE" = true ]; then
  echo "Detected Claude Code."

  # --- Create directory structure ---
  mkdir -p "$PLUGINS_DIR/cache"
  mkdir -p "$PLUGINS_DIR/marketplaces"

  # --- Clone or update the marketplace repo ---
  if [ -d "$MARKETPLACE_DIR/.git" ]; then
    echo "Updating hypt-builder..."
    git -C "$MARKETPLACE_DIR" pull --ff-only --quiet || {
      echo "Update failed. Re-downloading..."
      rm -rf "$MARKETPLACE_DIR"
      git clone --quiet "https://github.com/$REPO.git" "$MARKETPLACE_DIR"
    }
  else
    echo "Downloading hypt-builder..."
    rm -rf "$MARKETPLACE_DIR"
    git clone --quiet "https://github.com/$REPO.git" "$MARKETPLACE_DIR"
  fi

  # --- Read version from plugin.json ---
  VERSION=$(node -e "console.log(JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')).version)" "$MARKETPLACE_DIR/plugin/.claude-plugin/plugin.json") || {
    echo "Error: could not read plugin version from plugin.json"
    exit 1
  }
  GIT_SHA=$(git -C "$MARKETPLACE_DIR" rev-parse HEAD)

  # --- Copy plugin to cache ---
  CACHE_DIR="$PLUGINS_DIR/cache/$MARKETPLACE_NAME/$PLUGIN_NAME/$VERSION"
  rm -rf "$CACHE_DIR"
  mkdir -p "$CACHE_DIR"
  cp -R "$MARKETPLACE_DIR/plugin/." "$CACHE_DIR/"

  # --- Update JSON config files ---
  export PLUGIN_KEY MARKETPLACE_NAME REPO VERSION GIT_SHA PLUGIN_NAME
  node << 'JSEOF' || { echo "Error: failed to update config files."; exit 1; }
const fs = require('fs');
const path = require('path');
const os = require('os');

const claudeDir = path.join(os.homedir(), '.claude');
const pluginsDir = path.join(claudeDir, 'plugins');
const now = new Date().toISOString().replace(/\d{3}Z$/, '000Z');

const pluginKey = process.env.PLUGIN_KEY;
const marketplace = process.env.MARKETPLACE_NAME;
const repo = process.env.REPO;
const version = process.env.VERSION;
const gitSha = process.env.GIT_SHA;
const pluginName = process.env.PLUGIN_NAME;
const cachePath = path.join(pluginsDir, 'cache', marketplace, pluginName, version);
const marketplacePath = path.join(pluginsDir, 'marketplaces', marketplace);

function safeLoad(filePath, defaultVal) {
  if (!fs.existsSync(filePath)) return JSON.parse(JSON.stringify(defaultVal));
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch (e) {
    const backup = filePath + '.bak';
    fs.renameSync(filePath, backup);
    console.log('  Warning: ' + path.basename(filePath) + ' was malformed, backed up to ' + path.basename(backup));
    return JSON.parse(JSON.stringify(defaultVal));
  }
}

function atomicWrite(filePath, data) {
  const tmp = filePath + '.tmp';
  fs.writeFileSync(tmp, JSON.stringify(data, null, 2) + '\n');
  fs.renameSync(tmp, filePath);
}

// --- installed_plugins.json ---
const ipPath = path.join(pluginsDir, 'installed_plugins.json');
const ip = safeLoad(ipPath, { version: 2, plugins: {} });
if (!ip.plugins) ip.plugins = {};

const existing = ip.plugins[pluginKey];
const installedAt = (Array.isArray(existing) && existing[0] && existing[0].installedAt)
  ? existing[0].installedAt : now;

ip.plugins[pluginKey] = [{
  scope: 'user',
  installPath: cachePath,
  version: version,
  installedAt: installedAt,
  lastUpdated: now,
  gitCommitSha: gitSha
}];
atomicWrite(ipPath, ip);

// --- known_marketplaces.json ---
const kmPath = path.join(pluginsDir, 'known_marketplaces.json');
const km = safeLoad(kmPath, {});
km[marketplace] = {
  source: { source: 'github', repo: repo },
  installLocation: marketplacePath,
  lastUpdated: now,
  autoUpdate: true
};
atomicWrite(kmPath, km);

// --- settings.json ---
const settingsPath = path.join(claudeDir, 'settings.json');
const settings = safeLoad(settingsPath, {});
if (!settings.enabledPlugins) settings.enabledPlugins = {};
settings.enabledPlugins[pluginKey] = true;
atomicWrite(settingsPath, settings);

console.log('  Config files updated.');
JSEOF

  # Make bin scripts executable
  if [ -d "$MARKETPLACE_DIR/bin" ]; then
    chmod +x "$MARKETPLACE_DIR"/bin/* || true
  fi

  # Register SessionStart hook for auto-updates
  HOOK_SCRIPT="$MARKETPLACE_DIR/bin/hypt-session-update"
  HOOK_TOOL="$MARKETPLACE_DIR/bin/hypt-settings-hook"
  if [ -x "$HOOK_TOOL" ]; then
    "$HOOK_TOOL" add "$HOOK_SCRIPT" 2>/dev/null || true
  fi

  # Read version for final output (may already be set)
  INSTALLED_VERSION="$VERSION"

  # --- Offer starter CLAUDE.md ---
  STARTER_FILE="$MARKETPLACE_DIR/docs/starter-claude-md.md"
  TARGET_CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"

  if [ -f "$STARTER_FILE" ]; then
    if [ -t 0 ]; then
      if [ ! -f "$TARGET_CLAUDE_MD" ]; then
        # No existing CLAUDE.md — offer fresh install
        echo ""
        echo "Optional: install the hypt starter CLAUDE.md?"
        echo "This gives Claude senior engineering habits — planning, verification,"
        echo "code quality, and smart git practices — out of the box."
        echo ""
        read -r -p "Install starter CLAUDE.md? [Y/n] " response
        case "$response" in
          [nN]*) echo "  Skipped. You can find it later at: docs/starter-claude-md.md" ;;
          *)
            cp "$STARTER_FILE" "$TARGET_CLAUDE_MD"
            echo "  Installed to ~/.claude/CLAUDE.md"
            echo "  You can customize it anytime — it's just a text file."
            ;;
        esac
      elif ! grep -q '<!-- hypt-engineer-start -->' "$TARGET_CLAUDE_MD" || ! grep -q '<!-- hypt-engineer-end -->' "$TARGET_CLAUDE_MD"; then
        # Existing CLAUDE.md without complete hypt block — offer to enhance
        echo ""
        echo "Found existing ~/.claude/CLAUDE.md."
        echo "Want to enhance it with hypt engineering discipline?"
        echo "(planning, verification, code quality, smart git practices)"
        echo "Your existing content will be preserved."
        echo ""
        read -r -p "Add engineering discipline to your CLAUDE.md? [Y/n] " response
        case "$response" in
          [nN]*) echo "  Skipped. The starter is at: docs/starter-claude-md.md" ;;
          *)
            # Extract the content between markers from the starter file and append
            [ -s "$TARGET_CLAUDE_MD" ] && [ "$(tail -c 1 "$TARGET_CLAUDE_MD" | wc -l)" -eq 0 ] && printf '\n' >> "$TARGET_CLAUDE_MD"
            printf '\n' >> "$TARGET_CLAUDE_MD"
            sed -n '/<!-- hypt-engineer-start -->/,/<!-- hypt-engineer-end -->/p' "$STARTER_FILE" >> "$TARGET_CLAUDE_MD"
            echo "  Engineering discipline added to ~/.claude/CLAUDE.md"
            ;;
        esac
      else
        # Already has hypt block — update it idempotently
        sed -i.bak '/<!-- hypt-engineer-start -->/,/<!-- hypt-engineer-end -->/d' "$TARGET_CLAUDE_MD"
        rm -f "$TARGET_CLAUDE_MD.bak"
        [ -s "$TARGET_CLAUDE_MD" ] && [ "$(tail -c 1 "$TARGET_CLAUDE_MD" | wc -l)" -eq 0 ] && printf '\n' >> "$TARGET_CLAUDE_MD"
        printf '\n' >> "$TARGET_CLAUDE_MD"
        sed -n '/<!-- hypt-engineer-start -->/,/<!-- hypt-engineer-end -->/p' "$STARTER_FILE" >> "$TARGET_CLAUDE_MD"
      fi
    else
      # Non-interactive (piped install) — skip prompt, don't install without consent
      echo "  Starter CLAUDE.md available at: $MARKETPLACE_DIR/docs/starter-claude-md.md"
    fi
  fi
fi

# ============================================================
# SHARED: repo location & auto-update config
# ============================================================

# Determine where the repo lives
if [ -d "$MARKETPLACE_DIR/.git" ]; then
  REPO_DIR="$MARKETPLACE_DIR"
elif [ -d "$HYPT_DIR/repo/.git" ]; then
  REPO_DIR="$HYPT_DIR/repo"
else
  # Codex-only install: clone to ~/.hypt/repo/
  if [ "$HAS_CODEX" = true ] && [ "$HAS_CLAUDE" = false ]; then
    echo "Downloading hypt..."
    mkdir -p "$HYPT_DIR/repo"
    git clone --quiet "https://github.com/$REPO.git" "$HYPT_DIR/repo"
    REPO_DIR="$HYPT_DIR/repo"
  else
    REPO_DIR="$MARKETPLACE_DIR"
  fi
fi

# Read version from repo if not already set
if [ -z "${VERSION:-}" ]; then
  VERSION=$(cat "$REPO_DIR/VERSION" 2>/dev/null || echo "unknown")
fi

mkdir -p "$HYPT_DIR"

# Create default config if missing (auto_upgrade ON by default)
if [ ! -f "$HYPT_DIR/config.json" ]; then
  cat > "$HYPT_DIR/config.json" << 'CONFIGEOF'
{
  "auto_upgrade": true,
  "update_check": true
}
CONFIGEOF
fi

# Symlink bin/ to ~/.hypt/bin/ for generic access
if [ -d "$REPO_DIR/bin" ]; then
  ln -sfn "$REPO_DIR/bin" "$HYPT_DIR/bin"
fi

# Make bin scripts executable
if [ -d "$REPO_DIR/bin" ]; then
  chmod +x "$REPO_DIR"/bin/* || true
fi

# ============================================================
# CODEX CLI INSTALL
# ============================================================
if [ "$HAS_CODEX" = true ]; then
  echo "Detected Codex CLI."

  ADAPT_SCRIPT="$REPO_DIR/bin/hypt-codex-adapt"
  SKILLS_DIR="$HYPT_DIR/skills"
  mkdir -p "$SKILLS_DIR"

  if [ -x "$ADAPT_SCRIPT" ]; then
    # Generate adapted skills from skill directories
    for skill_dir in "$REPO_DIR/plugin/skills"/*/; do
      name=$(basename "$skill_dir")
      # Skip the meta-router (hypt:hypt) — replaced by the global instruction
      [ "$name" = "hypt" ] && continue
      if [ -f "$skill_dir/SKILL.md" ]; then
        "$ADAPT_SCRIPT" "$skill_dir/SKILL.md" > "$SKILLS_DIR/$name.md"
      fi
    done

    # Generate adapted skills from command files
    for cmd in "$REPO_DIR/plugin/commands"/*.md; do
      name=$(basename "$cmd" .md)
      "$ADAPT_SCRIPT" "$cmd" > "$SKILLS_DIR/$name.md"
    done

    echo "  Generated $(ls -1 "$SKILLS_DIR" | wc -l | tr -d ' ') skill files."
  else
    echo "  Warning: hypt-codex-adapt not found, skipping skill generation."
  fi

  # Install/update global instruction in ~/.codex/instructions.md
  mkdir -p "$CODEX_DIR"
  INSTRUCTIONS_FILE="$CODEX_DIR/instructions.md"

  # Write the hypt instruction block to a temp file
  HYPT_BLOCK_FILE=$(mktemp)
  trap 'rm -f "$HYPT_BLOCK_FILE"' EXIT
  cat > "$HYPT_BLOCK_FILE" << 'INSTREOF'
<!-- hypt-start -->
## hypt — Shipping Workflow

You have the hypt shipping workflow installed. When the user requests any of these
actions, read the detailed instructions from the skill file before executing.

| Action | Trigger phrases | Skill file |
|--------|----------------|------------|
| Save | save, commit, push, create PR | ~/.hypt/skills/save.md |
| Review | review, check my diff, look this over | ~/.hypt/skills/review.md |
| Deploy | deploy, check deployment | ~/.hypt/skills/deploy.md |
| Status | status, is my site up, quick check | ~/.hypt/skills/status.md |
| Fix | fix, debug, diagnose, investigate bug | ~/.hypt/skills/fix.md |
| Start | start, onboard, set up, initialize | ~/.hypt/skills/start.md |
| Prototype | prototype, build, implement | ~/.hypt/skills/prototype.md |
| Close | close, merge, ship, wrap up | ~/.hypt/skills/close.md |
| Touchup | touchup, polish, cleanup | ~/.hypt/skills/touchup.md |
| Unit Tests | add tests, write tests, unit tests | ~/.hypt/skills/unit-tests.md |
| Suggestions | suggest, what's next, backlog | ~/.hypt/skills/suggestions.md |
| Plan Critic | critique plan, review plan | ~/.hypt/skills/plan-critic.md |
| CI Setup | set up CI, add CI, GitHub Actions | ~/.hypt/skills/ci-setup.md |
| Pipeline | full pipeline, research and build | ~/.hypt/skills/pipeline.md |
| Go | go, ship with confirmation | ~/.hypt/skills/go.md |
| Yolo | yolo, ship it, full auto | ~/.hypt/skills/yolo.md |
| Autoclose | autoclose, auto merge | ~/.hypt/skills/autoclose.md |

Before executing any hypt skill, run this check silently:
```bash
~/.hypt/bin/hypt-update-check 2>/dev/null || true
```
If output contains `UPGRADE_AVAILABLE`: run `bash ~/.hypt/repo/install.sh` then continue.
If output contains `JUST_UPGRADED <old> <new>`: briefly mention "Running hypt v{new}." then continue.
<!-- hypt-end -->
INSTREOF

  if [ -f "$INSTRUCTIONS_FILE" ]; then
    # Remove existing hypt block if present (idempotent)
    if grep -q '<!-- hypt-start -->' "$INSTRUCTIONS_FILE"; then
      sed -i.bak '/<!-- hypt-start -->/,/<!-- hypt-end -->/d' "$INSTRUCTIONS_FILE"
      rm -f "$INSTRUCTIONS_FILE.bak"
    fi
    # Append the new block (only add newline if file doesn't end with one)
    [ -s "$INSTRUCTIONS_FILE" ] && [ "$(tail -c 1 "$INSTRUCTIONS_FILE" | wc -l)" -eq 0 ] && printf '\n' >> "$INSTRUCTIONS_FILE"
    cat "$HYPT_BLOCK_FILE" >> "$INSTRUCTIONS_FILE"
  else
    # Create the file with the hypt block
    cp "$HYPT_BLOCK_FILE" "$INSTRUCTIONS_FILE"
  fi
  rm -f "$HYPT_BLOCK_FILE"

  echo "  Codex CLI instructions updated."
fi

# ============================================================
# DONE
# ============================================================
echo ""
echo "hypt installed successfully! (v$VERSION)"
echo "Auto-updates enabled — hypt will keep itself up to date."

if [ "$HAS_CLAUDE" = true ] && [ "$HAS_CODEX" = true ]; then
  echo ""
  echo "Installed for: Claude Code + Codex CLI"
  echo "Restart both agents to activate."
elif [ "$HAS_CLAUDE" = true ]; then
  echo ""
  echo "Restart Claude Code to activate: type /exit then relaunch."
  echo "After restart, run /start to set up your project (accounts, tooling, and build plan)."
  echo "Already set up? Try: /prototype, /save, /review, or /hypt"
else
  echo ""
  echo "Installed for: Codex CLI"
  echo "Restart your Codex session to activate."
  echo "Then try: \"save my changes\", \"review my code\", or \"deploy\""
fi

# ============================================================
# RECOMMEND GSTACK (optional companion tool)
# ============================================================
if [ ! -d "$HOME/.claude/skills/gstack" ]; then
  echo ""
  echo "---"
  echo ""
  echo "Recommended: install gstack for visual QA testing, design review, and security audits."
  echo "gstack is a free companion tool (MIT license) that adds 35+ specialist skills to your workflow."
  echo ""
  echo "  Tell your AI agent: 'Install gstack' or run:"
  echo "  git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup"
  echo ""
  echo "Learn more: https://github.com/garrytan/gstack"
fi
