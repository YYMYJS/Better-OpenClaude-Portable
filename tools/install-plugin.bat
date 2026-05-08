@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ─── Detect USB root ──────────────────────────────────────
set "USB_ROOT=%~dp0.."
for %%i in ("%USB_ROOT%") do set "USB_ROOT=%%~fi"
set "CACHE_DIR=%USB_ROOT%\data\openclaude\plugins\cache"

:: ─── Step 1: Ensure cache is fully writable ──────────────
echo [1/3] Fixing permissions on plugin cache...
if exist "%CACHE_DIR%" (
    attrib -R "%CACHE_DIR%" /S /D >nul 2>&1
    echo       Permissions fixed.
)

:: ─── Step 2: Remove any leftover temp directories ────────
echo [2/3] Cleaning up temp directories...
for /d %%D in ("%CACHE_DIR%\temp_local_*") do (
    attrib -R "%%D" /S /D >nul 2>&1
    rmdir /s /q "%%D" >nul 2>&1
)

:: ─── Step 3: Install the plugin ──────────────────────────
if "%*"=="" (
    echo [ERROR] No plugin specified.
    echo   Usage: install-plugin.bat ^<plugin-name^>
    echo   Example: install-plugin.bat planning-with-files
    pause
    exit /b 1
)

echo [3/3] Installing plugin: %*
echo.
call claude plugin install %*
if !ERRORLEVEL! EQU 0 (
    echo.
    echo [OK] Plugin installed successfully.
) else (
    echo.
    echo [RETRY] Permission issue detected. Trying again with forced cleanup...
    :: Clean temp dirs again (read-only files left by git)
    if exist "%CACHE_DIR%" (
        attrib -R "%CACHE_DIR%" /S /D >nul 2>&1
        for /d %%D in ("%CACHE_DIR%\temp_local_*") do (
            attrib -R "%%D" /S /D >nul 2>&1
            rmdir /s /q "%%D" >nul 2>&1
        )
    )
    call claude plugin install %*
    if !ERRORLEVEL! EQU 0 (
        echo.
        echo [OK] Plugin installed on retry.
    ) else (
        echo.
        echo [WARN] Installation still failed. Run this manually to clean:
        echo   attrib -R "%%CACHE_DIR%%" /S /D
    )
)

echo.
pause
