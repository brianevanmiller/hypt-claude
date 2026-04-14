# hypt-claude plugin installer for Claude Code (Windows)
# Usage: powershell -ExecutionPolicy Bypass -File install.ps1
#   or:  irm https://raw.githubusercontent.com/brianevanmiller/hypt-claude/main/install.ps1 | iex

$ErrorActionPreference = "Stop"

$PluginName = "hypt"
$MarketplaceName = "hypt-claude"
$Repo = "brianevanmiller/hypt-claude"
$PluginKey = "$PluginName@$MarketplaceName"
$ClaudeDir = Join-Path $env:USERPROFILE ".claude"
$PluginsDir = Join-Path $ClaudeDir "plugins"
$MarketplaceDir = Join-Path $PluginsDir "marketplaces\$MarketplaceName"

# --- Preflight checks ---
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "Error: git is required. Install it from https://git-scm.com/ and try again."
    exit 1
}

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Error "Error: node is required (Claude Code depends on Node.js). Install it from https://nodejs.org/ and try again."
    exit 1
}

# --- Create directory structure ---
New-Item -ItemType Directory -Force -Path (Join-Path $PluginsDir "cache") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $PluginsDir "marketplaces") | Out-Null

# --- Clone or update the marketplace repo ---
if (Test-Path (Join-Path $MarketplaceDir ".git")) {
    Write-Host "Updating hypt-claude..."
    git -C "$MarketplaceDir" pull --ff-only --quiet 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Update failed. Re-downloading..."
        Remove-Item -Recurse -Force $MarketplaceDir -ErrorAction SilentlyContinue
        git clone --quiet "https://github.com/$Repo.git" "$MarketplaceDir"
        if ($LASTEXITCODE -ne 0) { Write-Error "Error: git clone failed."; exit 1 }
    }
} else {
    Write-Host "Downloading hypt-claude..."
    Remove-Item -Recurse -Force $MarketplaceDir -ErrorAction SilentlyContinue
    git clone --quiet "https://github.com/$Repo.git" "$MarketplaceDir"
    if ($LASTEXITCODE -ne 0) { Write-Error "Error: git clone failed."; exit 1 }
}

# --- Read version from plugin.json ---
$PluginJsonPath = Join-Path $MarketplaceDir "plugin\.claude-plugin\plugin.json"
try {
    $PluginJson = Get-Content $PluginJsonPath -Raw | ConvertFrom-Json
    $Version = $PluginJson.version
} catch {
    Write-Error "Error: could not read plugin version from plugin.json"
    exit 1
}
$GitSha = git -C $MarketplaceDir rev-parse HEAD

# --- Copy plugin to cache ---
$CacheDir = Join-Path $PluginsDir "cache\$MarketplaceName\$PluginName\$Version"
Remove-Item -Recurse -Force $CacheDir -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $CacheDir | Out-Null
Copy-Item -Recurse -Force (Join-Path $MarketplaceDir "plugin\*") $CacheDir

# --- Helper: load JSON safely ---
function SafeLoadJson($FilePath, $Default) {
    if (-not (Test-Path $FilePath)) { return $Default | ConvertTo-Json -Depth 10 | ConvertFrom-Json }
    try {
        return (Get-Content $FilePath -Raw | ConvertFrom-Json)
    } catch {
        $Backup = "$FilePath.bak"
        Move-Item -Force $FilePath $Backup
        Write-Host "  Warning: $(Split-Path $FilePath -Leaf) was malformed, backed up to $(Split-Path $Backup -Leaf)"
        return $Default | ConvertTo-Json -Depth 10 | ConvertFrom-Json
    }
}

# --- Helper: write JSON atomically ---
function AtomicWriteJson($FilePath, $Data) {
    $Tmp = "$FilePath.tmp"
    $Data | ConvertTo-Json -Depth 10 | Set-Content -Path $Tmp -Encoding UTF8
    Move-Item -Force $Tmp $FilePath
}

# --- Update JSON config files ---
$Now = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.000Z")
$CachePath = $CacheDir
$MarketplacePath = $MarketplaceDir

# --- installed_plugins.json ---
$IpPath = Join-Path $PluginsDir "installed_plugins.json"
$Ip = SafeLoadJson $IpPath @{ version = 2; plugins = @{} }
if (-not $Ip.plugins) { $Ip | Add-Member -NotePropertyName plugins -NotePropertyValue @{} -Force }

$InstalledAt = $Now
if ($Ip.plugins.PSObject.Properties.Name -contains $PluginKey) {
    $Existing = $Ip.plugins.$PluginKey
    if ($Existing -is [array] -and $Existing.Count -gt 0 -and $Existing[0].installedAt) {
        $InstalledAt = $Existing[0].installedAt
    }
}

$Ip.plugins | Add-Member -NotePropertyName $PluginKey -NotePropertyValue @(
    @{
        scope = "user"
        installPath = $CachePath
        version = $Version
        installedAt = $InstalledAt
        lastUpdated = $Now
        gitCommitSha = $GitSha
    }
) -Force
AtomicWriteJson $IpPath $Ip

# --- known_marketplaces.json ---
$KmPath = Join-Path $PluginsDir "known_marketplaces.json"
$Km = SafeLoadJson $KmPath @{}
$Km | Add-Member -NotePropertyName $MarketplaceName -NotePropertyValue @{
    source = @{ source = "github"; repo = $Repo }
    installLocation = $MarketplacePath
    lastUpdated = $Now
    autoUpdate = $true
} -Force
AtomicWriteJson $KmPath $Km

# --- settings.json ---
$SettingsPath = Join-Path $ClaudeDir "settings.json"
$Settings = SafeLoadJson $SettingsPath @{}
if (-not $Settings.enabledPlugins) {
    $Settings | Add-Member -NotePropertyName enabledPlugins -NotePropertyValue @{} -Force
}
$Settings.enabledPlugins | Add-Member -NotePropertyName $PluginKey -NotePropertyValue $true -Force
AtomicWriteJson $SettingsPath $Settings

Write-Host "  Config files updated."

# --- Set up auto-update ---
$HyptDir = Join-Path $env:USERPROFILE ".hypt"
New-Item -ItemType Directory -Force -Path $HyptDir | Out-Null

$ConfigPath = Join-Path $HyptDir "config.json"
if (-not (Test-Path $ConfigPath)) {
    AtomicWriteJson $ConfigPath @{ auto_upgrade = $true; update_check = $true }
}

# Register SessionStart hook (uses bash script — works if Git Bash is on PATH)
$HookScript = Join-Path $MarketplaceDir "bin\hypt-session-update"
$HookTool = Join-Path $MarketplaceDir "bin\hypt-settings-hook"
if ((Get-Command bash -ErrorAction SilentlyContinue) -and (Test-Path $HookTool)) {
    try { bash "$HookTool" add "$HookScript" 2>$null } catch {}
} else {
    Write-Host "  Note: auto-updates require Git Bash on PATH. To update manually, re-run this script."
}

Write-Host ""
Write-Host "hypt plugin installed successfully! (v$Version)"
Write-Host "Auto-updates enabled — hypt will keep itself up to date."
Write-Host ""
Write-Host "Restart Claude Code to activate: type /exit then relaunch."
Write-Host "After restart, run /start to set up your project (accounts, tooling, and build plan)."
Write-Host "Already set up? Try: /prototype, /save, /review, or /hypt"
