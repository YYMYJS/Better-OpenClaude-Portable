@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ── Detect USB root ────────────────────────────────────────
set "USB_ROOT=%~dp0.."
for %%i in ("%USB_ROOT%") do set "USB_ROOT=%%~fi"
set "DATA_DIR=%USB_ROOT%\data"
set "ENGINE_DIR=%USB_ROOT%\engine"

echo === Portable OpenClaude Environment ===
echo   USB Root:  %USB_ROOT%
echo   Config:    %DATA_DIR%\openclaude
echo   Plugins:   %DATA_DIR%\openclaude\plugins
echo   Skills:    %DATA_DIR%\openclaude\skills
echo   Cache:     %DATA_DIR%\app_data\claude-cli\Cache
echo.

:: ── Verify ─────────────────────────────────────────────────
if not exist "%ENGINE_DIR%\package.json" goto :not_found
if not exist "%DATA_DIR%\ai_settings.env" goto :not_found

:: ── Set all portable env vars ──────────────────────────────
set "CLAUDE_CONFIG_DIR=%DATA_DIR%\openclaude"
set "LOCALAPPDATA=%DATA_DIR%\app_data"
set "XDG_CONFIG_HOME=%DATA_DIR%\config"
set "XDG_DATA_HOME=%DATA_DIR%\app_data"
set "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1"
set "npm_config_cache=%DATA_DIR%\npm-cache"

:: ── Add portable Node to PATH ──────────────────────────────
if exist "%ENGINE_DIR%\node-win-x64\node.exe" (
    set "PATH=%ENGINE_DIR%\node-win-x64;%PATH%"
)
:: ── Add portable Git to PATH ───────────────────────────────
if exist "%ENGINE_DIR%\git-win-x64\bin\git.exe" (
    set "PATH=%ENGINE_DIR%\git-win-x64\bin;%PATH%"
    set "CLAUDE_CODE_GIT_BASH_PATH=%ENGINE_DIR%\git-win-x64\bin\bash.exe"
)

:: ── Preload fs.promises.rm patch for Windows read-only .git files ──
if exist "%ENGINE_DIR%\win32-rm-patch.cjs" (
    set "NODE_OPTIONS=--require "%ENGINE_DIR%\win32-rm-patch.cjs""
)

:: ── Load ai_settings.env ───────────────────────────────────
for /f "usebackq tokens=1,* delims==" %%A in ("%DATA_DIR%\ai_settings.env") do (
    set "%%A=%%~B"
)

echo.
echo Now running CMD in portable context.
echo Type EXIT to return to host environment.
echo.
cd /d "%USB_ROOT%"

:: ── Run command or drop into CMD ───────────────────────────
if "%1"=="" (
    cmd /k "prompt USB-OC$G"
) else (
    cmd /c "%*"
)
goto :eof

:not_found
echo [ERROR] Doesn't look like an OpenClaude Portable USB!
echo         Missing engine\package.json or data\ai_settings.env
pause
exit /b 1
