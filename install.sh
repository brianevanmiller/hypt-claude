#!/usr/bin/env bash
set -euo pipefail

# hypt-claude plugin installer for Claude Code
# Usage: bash install.sh
#   or:  bash <(curl -fsSL https://raw.githubusercontent.com/brianevanmiller/hypt-claude/main/install.sh)

PLUGIN_NAME="hypt"
MARKETPLACE_NAME="hypt-claude"
REPO="brianevanmiller/hypt-claude"
PLUGIN_KEY="${PLUGIN_NAME}@${MARKETPLACE_NAME}"
CLAUDE_DIR="$HOME/.claude"
PLUGINS_DIR="$CLAUDE_DIR/plugins"
MARKETPLACE_DIR="$PLUGINS_DIR/marketplaces/$MARKETPLACE_NAME"

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

# --- Create directory structure ---
mkdir -p "$PLUGINS_DIR/cache"
mkdir -p "$PLUGINS_DIR/marketplaces"

# --- Clone or update the marketplace repo ---
if [ -d "$MARKETPLACE_DIR/.git" ]; then
  echo "Updating hypt-claude..."
  git -C "$MARKETPLACE_DIR" pull --ff-only --quiet || {
    echo "Update failed. Re-downloading..."
    rm -rf "$MARKETPLACE_DIR"
    git clone --quiet "https://github.com/$REPO.git" "$MARKETPLACE_DIR"
  }
else
  echo "Downloading hypt-claude..."
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

# --- Set up auto-update ---
mkdir -p "$HOME/.hypt"

# Create default config if missing (auto_upgrade ON by default)
if [ ! -f "$HOME/.hypt/config.json" ]; then
  cat > "$HOME/.hypt/config.json" << 'CONFIGEOF'
{
  "auto_upgrade": true,
  "update_check": true
}
CONFIGEOF
fi

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

echo ""
echo "hypt plugin installed successfully! (v$VERSION)"
echo "Auto-updates enabled — hypt will keep itself up to date."
echo ""
echo "Restart Claude Code to activate: type /exit then relaunch."
echo "After restart, run /start to set up your project (accounts, tooling, and build plan)."
echo "Already set up? Try: /prototype, /save, /review, or /hypt"
