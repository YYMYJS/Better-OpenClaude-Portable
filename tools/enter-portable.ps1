<#
.SYNOPSIS
  Switch to Portable OpenClaude environment on this USB drive.
  Run any command in the USB context without affecting the host install.

.DESCRIPTION
  Sets all environment variables to point OpenClaude at this USB drive's
  data directory, then either:
    - drops you into a PowerShell sub-shell (no Command)
    - runs the given Command in the portable context

.EXAMPLE
  .\enter-portable.ps1                        # Enter portable subshell
  .\enter-portable.ps1 openclaude /plugins    # Check plugins on USB
  .\enter-portable.ps1 npm install -g some-tool
#>

param(
  [Parameter(Position=0, ValueFromRemainingArguments)]
  [string[]]$Command
)

# ── Detect USB root ────────────────────────────────────────
$UsbRoot = Split-Path -Parent $PSScriptRoot
$DataDir  = Join-Path $UsbRoot "data"
$EngineDir = Join-Path $UsbRoot "engine"

Write-Host "=== Portable OpenClaude Environment ===" -ForegroundColor Cyan
Write-Host "  USB Root:  $UsbRoot" -ForegroundColor Cyan
Write-Host "  Config:    $DataDir\openclaude" -ForegroundColor Cyan
Write-Host "  Plugins:   $DataDir\openclaude\plugins" -ForegroundColor Cyan
Write-Host "  Skills:    $DataDir\openclaude\skills" -ForegroundColor Cyan
Write-Host "  Cache:     $DataDir\app_data\claude-cli\Cache" -ForegroundColor Cyan
Write-Host ""

# ── Verify it's really a portable USB ──────────────────────
if (!(Test-Path "$EngineDir\package.json") -or !(Test-Path "$DataDir\ai_settings.env")) {
  Write-Error "ERROR: This doesn't look like an OpenClaude Portable USB!"
  Write-Error "       Missing engine\package.json or data\ai_settings.env"
  exit 1
}

# ── Set all portable env vars ──────────────────────────────
$env:CLAUDE_CONFIG_DIR          = Join-Path $DataDir "openclaude"
$env:LOCALAPPDATA               = Join-Path $DataDir "app_data"
$env:XDG_CONFIG_HOME            = Join-Path $DataDir "config"
$env:XDG_DATA_HOME              = Join-Path $DataDir "app_data"
$env:XDG_CACHE_HOME             = Join-Path $DataDir "cache"
$env:npm_config_cache           = Join-Path $DataDir "npm-cache"
$env:CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"

# Add portable Node.js to PATH if it exists
$NodeDir = Join-Path $EngineDir "node-win-x64"
if (Test-Path "$NodeDir\node.exe") {
  $env:PATH = "$NodeDir;$env:PATH"
}

# Add portable Git to PATH if it exists
$GitDir = Join-Path $EngineDir "git-win-x64"
if (Test-Path "$GitDir\bin\git.exe") {
  $env:PATH = "$GitDir\bin;$env:PATH"
  $env:GIT_BASH = "$GitDir\bin\bash.exe"
  $env:CLAUDE_CODE_GIT_BASH_PATH = "$GitDir\bin\bash.exe"
}

# Add portable bin (uv, and other CLI tools) to PATH if it exists
$PortableBin = Join-Path $DataDir "bin"
if (Test-Path $PortableBin) {
  $env:PATH = "$PortableBin;$env:PATH"
}

# Path to portable openclaude CLI
# Use EngineDir if set, otherwise derive from script location
if ($EngineDir) {
  $NodeExe = Join-Path $EngineDir "node-win-x64\node.exe"
  $OpenClaundBin = Join-Path $EngineDir "node_modules\@gitlawb\openclaude\bin\openclaude"
} else {
  # Fallback: compute from script location (for interactive sessions)
  $ScriptRoot = Split-Path -Parent $PSCommandPath
  if (!$ScriptRoot) { $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
  $EngineDirFallback = Split-Path -Parent $ScriptRoot
  $NodeExe = Join-Path $EngineDirFallback "engine\node-win-x64\node.exe"
  $OpenClaundBin = Join-Path $EngineDirFallback "engine\node_modules\@gitlawb\openclaude\bin\openclaude"
}

# Clear any inherited NODE_OPTIONS that could break portable node (e.g., win32-rm-patch.cjs path issues)
$env:NODE_OPTIONS = ""

# ── Also load ai_settings.env into environment ────────────
$EnvFile = Join-Path $DataDir "ai_settings.env"
if (Test-Path $EnvFile) {
  Get-Content $EnvFile | ForEach-Object {
    if ($_ -match "^\s*([^#=]+)\s*=\s*(.+)\s*$") {
      $key = $matches[1].Trim()
      $val = $matches[2].Trim()
      Set-Item -Path "env:$key" -Value $val -ErrorAction SilentlyContinue
    }
  }
}

# ── claude wrapper: invoke portable openclaude via portable Node.js ──
function global:claude {
  # Recalculate paths if not set (handles interactive session where $EngineDir might be $null)
  if (-not $script:NodeExe -or -not (Test-Path $script:NodeExe)) {
    $scriptRoot = Split-Path -Parent $PSCommandPath
    if (-not $scriptRoot) { $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
    if ($scriptRoot) {
      $engineDir = Split-Path -Parent $scriptRoot
      $script:NodeExe = Join-Path $engineDir "engine\node-win-x64\node.exe"
      $script:OpenClaundBin = Join-Path $engineDir "engine\node_modules\@gitlawb\openclaude\bin\openclaude"
    }
  }
  if ($script:NodeExe -and (Test-Path $script:NodeExe)) {
    # Pass API credentials explicitly as environment variables to override any inherited values
    $env:ANTHROPIC_API_KEY = $env:ANTHROPIC_API_KEY
    $env:ANTHROPIC_BASE_URL = $env:ANTHROPIC_BASE_URL
    $env:ANTHROPIC_MODEL = $env:ANTHROPIC_MODEL
    & $script:NodeExe $script:OpenClaundBin $args
    $global:LASTEXITCODE = $LASTEXITCODE
  } else {
    Write-Error "Portable Node.js not found. EngineDir: $script:NodeExe"
    $global:LASTEXITCODE = 1
  }
}

# ── Also define 'openclaude' alias ──────────────────────────
function global:openclaude {
  & $script:NodeExe $script:OpenClaundBin $args
  $global:LASTEXITCODE = $LASTEXITCODE
}

# ── Run command or drop into subshell ──────────────────────
if ($Command.Count -gt 0) {
  $cmdLine = $Command -join " "
  Write-Host "Running in portable context:" -ForegroundColor Yellow
  Write-Host "  $cmdLine" -ForegroundColor Gray
  Write-Host ""
  & $Command[0] $Command[1..($Command.Count-1)]
  exit $LASTEXITCODE
} else {
  # Save old prompt function and override globally
  $script:oldPrompt = ${function:prompt}
  function global:prompt { "USB-OC> " }
  Write-Host "Entered portable environment." -ForegroundColor Green
  Write-Host "Env vars are set for this PowerShell session." -ForegroundColor Yellow
  Write-Host "Run 'openclaude' to start, or type EXIT and close the window to leave." -ForegroundColor Green
  Write-Host ""
}
