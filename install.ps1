# hypt plugin installer — auto-detects Claude Code and Codex CLI (Windows)
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File install.ps1
#   powershell -ExecutionPolicy Bypass -File install.ps1 -Doctor
#   irm https://raw.githubusercontent.com/brianevanmiller/hypt-builder/main/install.ps1 | iex
#
# Doctor mode prints structured output (one line per tool: "ok: <tool>" or
# "missing: <tool> — <why>" followed by per-platform install hints). It exits
# with code 0 if all prerequisites are present, or 2 if any are missing.
# Designed to be parsed by AI agents installing hypt on a non-coder's machine.
#
# When piping via `irm | iex`, set $env:HYPT_DOCTOR=1 to enable doctor mode.

param(
    [switch]$Doctor,
    [switch]$Check,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

if ($Help) {
    Write-Host "hypt installer (Windows)"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  install.ps1                install hypt"
    Write-Host "  install.ps1 -Doctor        check prerequisites only (exit 2 if any missing)"
    exit 0
}

$DoctorMode = $Doctor.IsPresent -or $Check.IsPresent -or ($env:HYPT_DOCTOR -eq "1")

$PluginName = "hypt"
$MarketplaceName = "hypt-builder"
$Repo = "brianevanmiller/hypt-builder"
$PluginKey = "$PluginName@$MarketplaceName"
$ClaudeDir = Join-Path $env:USERPROFILE ".claude"
$PluginsDir = Join-Path $ClaudeDir "plugins"
$MarketplaceDir = Join-Path $PluginsDir "marketplaces\$MarketplaceName"
$HyptDir = Join-Path $env:USERPROFILE ".hypt"
$CodexDir = Join-Path $env:USERPROFILE ".codex"

# --- Prereq check helper ---
function Test-Prereq {
    param(
        [string]$Tool,
        [string]$Why,
        [string]$HintMac,
        [string]$HintWin,
        [string]$HintLinux
    )

    $cmd = Get-Command $Tool -ErrorAction SilentlyContinue
    if ($cmd) {
        if ($script:DoctorMode) {
            Write-Host "ok: $Tool ($($cmd.Source))"
        }
        return $true
    } else {
        if ($script:DoctorMode) {
            Write-Host "missing: $Tool — $Why"
            Write-Host "  macOS:   $HintMac"
            Write-Host "  Windows: $HintWin"
            Write-Host "  Linux:   $HintLinux"
        }
        return $false
    }
}

# --- Doctor mode: check all prereqs and exit ---
if ($DoctorMode) {
    Write-Host "hypt prerequisite check"
    Write-Host ""

    $missing = 0
    if (-not (Test-Prereq -Tool "git" `
        -Why "version control (required by install and your project)" `
        -HintMac "brew install git" `
        -HintWin "winget install --id Git.Git -e" `
        -HintLinux "apt install -y git    # or your distro's equivalent")) { $missing++ }

    if (-not (Test-Prereq -Tool "node" `
        -Why "required by Claude Code and the installer" `
        -HintMac "brew install node" `
        -HintWin "winget install --id OpenJS.NodeJS.LTS -e" `
        -HintLinux "curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt install -y nodejs")) { $missing++ }

    if (-not (Test-Prereq -Tool "bun" `
        -Why "fast package manager / runtime, used by /start and /prototype" `
        -HintMac "curl -fsSL https://bun.sh/install | bash" `
        -HintWin "powershell -c `"irm bun.sh/install.ps1 | iex`"" `
        -HintLinux "curl -fsSL https://bun.sh/install | bash")) { $missing++ }

    if (-not (Test-Prereq -Tool "gh" `
        -Why "GitHub CLI, used by /start to authenticate with GitHub" `
        -HintMac "brew install gh" `
        -HintWin "winget install --id GitHub.cli -e" `
        -HintLinux "(see https://cli.github.com/manual/installation)")) { $missing++ }

    Write-Host ""
    if ($missing -eq 0) {
        Write-Host "All prerequisites installed. Ready to run: install.ps1"
        exit 0
    } else {
        Write-Host "$missing prerequisite(s) missing."
        Write-Host "If an AI agent is running this for you, it can install the missing"
        Write-Host "tools above with your permission. Otherwise, install them manually,"
        Write-Host "then re-run this installer."
        exit 2
    }
}

# --- Detect which agents are installed ---
$HasClaude = $false
$HasCodex = $false

if ((Test-Path $ClaudeDir) -or (Get-Command claude -ErrorAction SilentlyContinue)) {
    $HasClaude = $true
}

if ((Test-Path $CodexDir) -or (Get-Command codex -ErrorAction SilentlyContinue)) {
    $HasCodex = $true
}

# If neither detected, default to Claude (the primary target)
if (-not $HasClaude -and -not $HasCodex) {
    $HasClaude = $true
}

# --- Preflight: hard prereqs (installer cannot run without these) ---
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "Error: git is required. Install it from https://git-scm.com/ and try again. Hint: run install.ps1 -Doctor to see install commands."
    exit 1
}

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Error "Error: node is required (Claude Code depends on Node.js). Install it from https://nodejs.org/ and try again. Hint: run install.ps1 -Doctor to see install commands."
    exit 1
}

# --- Soft prereqs: warn but continue (needed by /start, not the installer itself) ---
$SoftMissing = @()
if (-not (Get-Command bun -ErrorAction SilentlyContinue)) { $SoftMissing += "bun (used by /start and /prototype)" }
if (-not (Get-Command gh  -ErrorAction SilentlyContinue)) { $SoftMissing += "gh (used by /start for GitHub auth)" }

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

# ============================================================
# CLAUDE CODE INSTALL
# ============================================================
$Version = $null

if ($HasClaude) {
    Write-Host "Detected Claude Code."

    # --- Create directory structure ---
    New-Item -ItemType Directory -Force -Path (Join-Path $PluginsDir "cache") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $PluginsDir "marketplaces") | Out-Null

    # --- Clone or update the marketplace repo ---
    if (Test-Path (Join-Path $MarketplaceDir ".git")) {
        Write-Host "Updating hypt-builder..."
        git -C "$MarketplaceDir" pull --ff-only --quiet 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Update failed. Re-downloading..."
            Remove-Item -Recurse -Force $MarketplaceDir -ErrorAction SilentlyContinue
            git clone --quiet "https://github.com/$Repo.git" "$MarketplaceDir"
            if ($LASTEXITCODE -ne 0) { Write-Error "Error: git clone failed."; exit 1 }
        }
    } else {
        Write-Host "Downloading hypt-builder..."
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

    # Register SessionStart hook (uses bash script — works if Git Bash is on PATH)
    $HookScript = Join-Path $MarketplaceDir "bin\hypt-session-update"
    $HookTool = Join-Path $MarketplaceDir "bin\hypt-settings-hook"
    if ((Get-Command bash -ErrorAction SilentlyContinue) -and (Test-Path $HookTool)) {
        try { bash "$HookTool" add "$HookScript" 2>$null } catch {}
    } else {
        Write-Host "  Note: auto-updates require Git Bash on PATH. To update manually, re-run this script."
    }

    # --- Offer starter CLAUDE.md ---
    $StarterFile = Join-Path $MarketplaceDir "docs\starter-claude-md.md"
    $TargetClaudeMd = Join-Path $ClaudeDir "CLAUDE.md"

    if (Test-Path $StarterFile) {
        $isInteractive = [Environment]::UserInteractive -and -not ([Console]::IsInputRedirected)
        if ($isInteractive) {
            if (-not (Test-Path $TargetClaudeMd)) {
                # No existing CLAUDE.md — offer fresh install
                Write-Host ""
                Write-Host "Optional: install the hypt starter CLAUDE.md?"
                Write-Host "This gives Claude senior engineering habits — planning, verification,"
                Write-Host "code quality, and smart git practices — out of the box."
                Write-Host ""
                $response = Read-Host "Install starter CLAUDE.md? [Y/n]"
                if ($response -match '^[nN]') {
                    Write-Host "  Skipped. You can find it later at: docs/starter-claude-md.md"
                } else {
                    Copy-Item $StarterFile $TargetClaudeMd
                    Write-Host "  Installed to ~/.claude/CLAUDE.md"
                    Write-Host "  You can customize it anytime — it's just a text file."
                }
            } elseif (-not (Select-String -Path $TargetClaudeMd -Pattern "<!-- hypt-engineer-start -->" -SimpleMatch -Quiet) -or
                     -not (Select-String -Path $TargetClaudeMd -Pattern "<!-- hypt-engineer-end -->" -SimpleMatch -Quiet)) {
                # Existing CLAUDE.md without complete hypt block — offer to enhance
                Write-Host ""
                Write-Host "Found existing ~/.claude/CLAUDE.md."
                Write-Host "Want to enhance it with hypt engineering discipline?"
                Write-Host "(planning, verification, code quality, smart git practices)"
                Write-Host "Your existing content will be preserved."
                Write-Host ""
                $response = Read-Host "Add engineering discipline to your CLAUDE.md? [Y/n]"
                if ($response -match '^[nN]') {
                    Write-Host "  Skipped. The starter is at: docs/starter-claude-md.md"
                } else {
                    # Extract content between markers and append
                    $StarterContent = Get-Content $StarterFile -Raw -Encoding UTF8
                    $Block = [regex]::Match($StarterContent, '(?s)(<!-- hypt-engineer-start -->.*?<!-- hypt-engineer-end -->)')
                    if ($Block.Success) {
                        Add-Content -Path $TargetClaudeMd -Value "`n$($Block.Value)" -Encoding UTF8
                    }
                    Write-Host "  Engineering discipline added to ~/.claude/CLAUDE.md"
                }
            } else {
                # Already has hypt block — update idempotently
                $Content = Get-Content $TargetClaudeMd -Raw -Encoding UTF8
                $Content = $Content -replace '(?s)<!-- hypt-engineer-start -->.*?<!-- hypt-engineer-end -->', ''
                $Content = $Content.TrimEnd()
                $StarterContent = Get-Content $StarterFile -Raw -Encoding UTF8
                $Block = [regex]::Match($StarterContent, '(?s)(<!-- hypt-engineer-start -->.*?<!-- hypt-engineer-end -->)')
                if ($Block.Success) {
                    "$Content`n`n$($Block.Value)`n" | Set-Content -Path $TargetClaudeMd -Encoding UTF8
                }
            }
        } else {
            Write-Host "  Starter CLAUDE.md available at: $MarketplaceDir\docs\starter-claude-md.md"
        }
    }
}

# ============================================================
# SHARED: repo location & auto-update config
# ============================================================

# Determine where the repo lives
$RepoDir = $null
if (Test-Path (Join-Path $MarketplaceDir ".git")) {
    $RepoDir = $MarketplaceDir
} elseif (Test-Path (Join-Path $HyptDir "repo\.git")) {
    $RepoDir = Join-Path $HyptDir "repo"
} else {
    # Codex-only install: clone to ~/.hypt/repo/
    if ($HasCodex -and -not $HasClaude) {
        Write-Host "Downloading hypt..."
        $RepoDir = Join-Path $HyptDir "repo"
        New-Item -ItemType Directory -Force -Path $RepoDir | Out-Null
        git clone --quiet "https://github.com/$Repo.git" "$RepoDir"
        if ($LASTEXITCODE -ne 0) { Write-Error "Error: git clone failed."; exit 1 }
    } else {
        $RepoDir = $MarketplaceDir
    }
}

# Read version from repo if not already set
if (-not $Version) {
    $VersionFile = Join-Path $RepoDir "VERSION"
    if (Test-Path $VersionFile) {
        $Version = (Get-Content $VersionFile -Raw).Trim()
    } else {
        $Version = "unknown"
    }
}

New-Item -ItemType Directory -Force -Path $HyptDir | Out-Null

$ConfigPath = Join-Path $HyptDir "config.json"
if (-not (Test-Path $ConfigPath)) {
    AtomicWriteJson $ConfigPath @{ auto_upgrade = $true; update_check = $true }
}

# ============================================================
# CODEX CLI INSTALL
# ============================================================
if ($HasCodex) {
    Write-Host "Detected Codex CLI."

    $SkillsDir = Join-Path $HyptDir "skills"
    New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null

    # Generate adapted skills (requires Git Bash for the adapt script)
    $AdaptScript = Join-Path $RepoDir "bin\hypt-codex-adapt"
    if ((Get-Command bash -ErrorAction SilentlyContinue) -and (Test-Path $AdaptScript)) {
        # Adapt skill directories
        $SkillDirs = Get-ChildItem -Directory (Join-Path $RepoDir "plugin\skills") -ErrorAction SilentlyContinue
        foreach ($Dir in $SkillDirs) {
            if ($Dir.Name -eq "hypt") { continue }  # Skip meta-router
            $SkillFile = Join-Path $Dir.FullName "SKILL.md"
            if (Test-Path $SkillFile) {
                $Output = bash "$AdaptScript" "$SkillFile"
                $Output | Set-Content -Path (Join-Path $SkillsDir "$($Dir.Name).md") -Encoding UTF8
            }
        }

        # Adapt command files
        $CmdFiles = Get-ChildItem (Join-Path $RepoDir "plugin\commands\*.md") -ErrorAction SilentlyContinue
        foreach ($Cmd in $CmdFiles) {
            $Output = bash "$AdaptScript" $Cmd.FullName
            $Output | Set-Content -Path (Join-Path $SkillsDir "$($Cmd.BaseName).md") -Encoding UTF8
        }

        $SkillCount = @(Get-ChildItem $SkillsDir -Filter "*.md").Count
        Write-Host "  Generated $SkillCount skill files."
    } else {
        Write-Host "  Warning: Git Bash required for skill generation. Install Git Bash and re-run."
    }

    # Install/update global instruction in ~/.codex/instructions.md
    New-Item -ItemType Directory -Force -Path $CodexDir | Out-Null
    $InstructionsFile = Join-Path $CodexDir "instructions.md"

    $HyptBlock = @'
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
'@

    if (Test-Path $InstructionsFile) {
        $Content = Get-Content $InstructionsFile -Raw
        # Remove existing hypt block if present (idempotent)
        if ($Content -match '<!-- hypt-start -->') {
            $Content = $Content -replace '(?s)<!-- hypt-start -->.*?<!-- hypt-end -->', ''
            $Content = $Content.TrimEnd()
        }
        # Append the new block
        "$Content`n`n$HyptBlock" | Set-Content -Path $InstructionsFile -Encoding UTF8
    } else {
        $HyptBlock | Set-Content -Path $InstructionsFile -Encoding UTF8
    }

    Write-Host "  Codex CLI instructions updated."
}

# ============================================================
# DONE
# ============================================================
Write-Host ""
Write-Host "hypt installed successfully! (v$Version)"
Write-Host "Auto-updates enabled — hypt will keep itself up to date."

# Soft prereq warnings — print after success so users know what /start will need
if ($SoftMissing.Count -gt 0) {
    Write-Host ""
    Write-Host "Note: the following are not yet installed but are needed by /start:"
    foreach ($item in $SoftMissing) {
        Write-Host "  - $item"
    }
    Write-Host "Run install.ps1 -Doctor for install commands, or your AI agent can"
    Write-Host "install them for you when you run /start."
}

if ($HasClaude -and $HasCodex) {
    Write-Host ""
    Write-Host "Installed for: Claude Code + Codex CLI"
    Write-Host "Restart both agents to activate."
} elseif ($HasClaude) {
    Write-Host ""
    Write-Host "Restart Claude Code to activate: type /exit then relaunch."
    Write-Host "After restart, run /start to set up your project (accounts, tooling, and build plan)."
    Write-Host "Already set up? Try: /prototype, /save, /review, or /hypt"
} else {
    Write-Host ""
    Write-Host "Installed for: Codex CLI"
    Write-Host "Restart your Codex session to activate."
    Write-Host 'Then try: "save my changes", "review my code", or "deploy"'
}

# ============================================================
# RECOMMEND GSTACK (optional companion tool)
# ============================================================
$GstackDir = Join-Path $env:USERPROFILE ".claude\skills\gstack"
if (-not (Test-Path $GstackDir)) {
    Write-Host ""
    Write-Host "---"
    Write-Host ""
    Write-Host "Recommended: install gstack for visual QA testing, design review, and security audits."
    Write-Host "gstack is a free companion tool (MIT license) that adds 35+ specialist skills to your workflow."
    Write-Host ""
    Write-Host "  Tell your AI agent: 'Install gstack' or run:"
    Write-Host "  git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup"
    Write-Host ""
    Write-Host "Learn more: https://github.com/garrytan/gstack"
}
