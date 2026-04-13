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

if ! command -v python3 &>/dev/null; then
  echo "Error: python3 is required. On macOS, run: xcode-select --install"
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
VERSION=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['version'])" "$MARKETPLACE_DIR/plugin/.claude-plugin/plugin.json") || {
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
python3 << 'PYEOF' || { echo "Error: failed to update config files."; exit 1; }
import json, os, sys
from pathlib import Path
from datetime import datetime, timezone

claude_dir = Path.home() / ".claude"
plugins_dir = claude_dir / "plugins"
now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000Z")

plugin_key = os.environ["PLUGIN_KEY"]
marketplace = os.environ["MARKETPLACE_NAME"]
repo = os.environ["REPO"]
version = os.environ["VERSION"]
git_sha = os.environ["GIT_SHA"]
plugin_name = os.environ["PLUGIN_NAME"]
cache_path = str(plugins_dir / "cache" / marketplace / plugin_name / version)
marketplace_path = str(plugins_dir / "marketplaces" / marketplace)

def safe_load(path, default):
    """Load JSON, backing up and recreating if malformed."""
    if not path.exists():
        return default.copy()
    try:
        return json.loads(path.read_text())
    except (json.JSONDecodeError, ValueError):
        backup = path.with_suffix(".json.bak")
        path.rename(backup)
        print(f"  Warning: {path.name} was malformed, backed up to {backup.name}")
        return default.copy()

def atomic_write(path, data):
    """Write JSON atomically via temp file to prevent corruption on crash."""
    tmp = path.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(data, indent=2) + "\n")
    tmp.replace(path)

# --- installed_plugins.json ---
ip_path = plugins_dir / "installed_plugins.json"
ip = safe_load(ip_path, {"version": 2, "plugins": {}})
if "plugins" not in ip:
    ip["plugins"] = {}

existing = ip["plugins"].get(plugin_key, [])
installed_at = existing[0].get("installedAt", now) if isinstance(existing, list) and existing else now

ip["plugins"][plugin_key] = [{
    "scope": "user",
    "installPath": cache_path,
    "version": version,
    "installedAt": installed_at,
    "lastUpdated": now,
    "gitCommitSha": git_sha
}]
atomic_write(ip_path, ip)

# --- known_marketplaces.json ---
km_path = plugins_dir / "known_marketplaces.json"
km = safe_load(km_path, {})
km[marketplace] = {
    "source": {"source": "github", "repo": repo},
    "installLocation": marketplace_path,
    "lastUpdated": now,
    "autoUpdate": True
}
atomic_write(km_path, km)

# --- settings.json ---
settings_path = claude_dir / "settings.json"
settings = safe_load(settings_path, {})
if "enabledPlugins" not in settings:
    settings["enabledPlugins"] = {}
settings["enabledPlugins"][plugin_key] = True
atomic_write(settings_path, settings)

print("  Config files updated.")
PYEOF

echo ""
echo "hypt plugin installed successfully! (v$VERSION)"
echo ""
echo "Restart Claude Code to activate: type /exit then relaunch."
echo "After restart, try: /prototype, /save, /review, or /hypt"
