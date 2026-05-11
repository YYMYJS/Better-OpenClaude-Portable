@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title Portable AI USB - Starting...

:: Define ANSI Colors
for /F %%a in ('powershell -NoProfile -Command "[char]27"') do set "ESC=%%a"
set "CYAN=!ESC![36m"
set "GREEN=!ESC![32m"
set "YELLOW=!ESC![33m"
set "RED=!ESC![31m"
set "DIM=!ESC![90m"
set "RESET=!ESC![0m"
set "BOLD=!ESC![1m"

set "USB_ROOT=%~dp0"
set "ENGINE_DIR=%USB_ROOT%engine"
set "DATA_DIR=%USB_ROOT%data"
set "ENV_FILE=%DATA_DIR%\ai_settings.env"
set "NODE_VERSION=22.14.0"
set "NODE_DIR_NAME=node-win-x64"
set "NODE_DIR=%ENGINE_DIR%\%NODE_DIR_NAME%"
set "GIT_VERSION=2.54.0"
set "GIT_DIR_NAME=git-win-x64"
set "GIT_DIR=%ENGINE_DIR%\%GIT_DIR_NAME%"
set "GIT_BASH=%GIT_DIR%\bin\bash.exe"
set "GIT_EXE=%GIT_DIR%\bin\git.exe"
set "OPENCLAUDE_DIR=%ENGINE_DIR%\node_modules\@gitlawb\openclaude"
set "OC_BIN=%OPENCLAUDE_DIR%\bin\openclaude"
set "OC_CLI=%OPENCLAUDE_DIR%\dist\cli.mjs"

:: 1. Force the portable AI to save logs/memory strictly to the USB
set "CLAUDE_CONFIG_DIR=%DATA_DIR%\openclaude"
set "XDG_CONFIG_HOME=%DATA_DIR%\config"
set "XDG_DATA_HOME=%DATA_DIR%\app_data"

:: Redirect caches from host to USB
set "LOCALAPPDATA=%DATA_DIR%\app_data"
set "npm_config_cache=%DATA_DIR%\npm-cache"

if not exist "%CLAUDE_CONFIG_DIR%" mkdir "%CLAUDE_CONFIG_DIR%"
if not exist "%XDG_CONFIG_HOME%" mkdir "%XDG_CONFIG_HOME%"
if not exist "%XDG_DATA_HOME%" mkdir "%XDG_DATA_HOME%"
if not exist "%LOCALAPPDATA%" mkdir "%LOCALAPPDATA%"
if not exist "%npm_config_cache%" mkdir "%npm_config_cache%"

:: ── Auto-copy .claude-memory to data/openclaude/projects/<项目名>/memory/ ──
:: Extract project name from USB root directory
for %%i in ("%USB_ROOT%") do set "PROJECT_NAME=%%~ni"
set "MEMORY_SRC=%USB_ROOT%.claude-memory"
set "MEMORY_DST=%DATA_DIR%\openclaude\projects\%PROJECT_NAME%\memory"
if exist "%MEMORY_SRC%" (
    if not exist "%MEMORY_DST%" (
        mkdir "%MEMORY_DST%" 2>nul
        xcopy /E /I /Y "%MEMORY_SRC%" "%MEMORY_DST%" >nul 2>&1
    )
)

:: Display Banner
echo.
echo !CYAN!    ____            __        __    __        ___    ____!RESET!
echo !CYAN!   / __ \____  ____/ /_____ _/ /_  / /__     /   ^|  /  _/!RESET!
echo !CYAN!  / /_/ / __ \/ __/ __/ __ `/ __ \/ / _ \   / /^| ^|  / /  !RESET!
echo !CYAN! / ____/ /_/ / / / /_/ /_/ / /_/ / /  __/  / ___ ^|_/ /   !RESET!
echo !CYAN!/_/    \____/_/  \__/\__,_/_.___/_/\___/  /_/  ^|_/___/   !RESET!
echo.
echo !CYAN!=========================================================!RESET!
echo   !BOLD!Claude Code - Open Source Multi-Platform!RESET!
echo !CYAN!=========================================================!RESET!
echo.

if not exist "%ENGINE_DIR%" mkdir "%ENGINE_DIR%"

goto after_install_engine_func
:install_engine
set "INSTALL_ACTION=%~1"
if "%INSTALL_ACTION%"=="" set "INSTALL_ACTION=Installing"
echo   !YELLOW![~] !INSTALL_ACTION! OpenClaude Engine...!RESET!
echo   !DIM!    This can take several minutes on slower USB drives or networks.!RESET!
pushd "%ENGINE_DIR%"
call npm.cmd install @gitlawb/openclaude@latest --no-audit --no-fund --loglevel=warn --no-bin-links
set "NPM_STATUS=!ERRORLEVEL!"
popd
if not "!NPM_STATUS!"=="0" (
    echo   !RED![ERROR] OpenClaude Engine install failed ^(npm exit !NPM_STATUS!^).!RESET!
    pause
    exit /b 1
)
if not exist "%OC_BIN%" goto incomplete_engine
if not exist "%OC_CLI%" goto incomplete_engine
echo   !GREEN![OK] Engine installed!!RESET!
exit /b 0

:incomplete_engine
echo   !RED![ERROR] OpenClaude Engine install is incomplete.!RESET!
echo   !DIM!        Missing expected files under %OPENCLAUDE_DIR%!RESET!
pause
exit /b 1
:after_install_engine_func

:: 2. Check Node.js
if not exist "%NODE_DIR%\node.exe" (
    echo   !YELLOW![~] Node.js not found for Windows-x64. Downloading...!RESET!
    curl.exe -L "https://nodejs.org/dist/v%NODE_VERSION%/node-v%NODE_VERSION%-win-x64.zip" -o "%ENGINE_DIR%\node.zip"
    if errorlevel 1 (
        echo   !RED![ERROR] Failed to download Node.js!!RESET!
        pause
        exit /b 1
    )
    echo   !YELLOW![~] Extracting Node.js...!RESET!
    echo   !DIM!    This can be silent for a few minutes on external drives.!RESET!
    if exist "%NODE_DIR%" rmdir /s /q "%NODE_DIR%"
    powershell -NoProfile -Command "Expand-Archive -Path '%ENGINE_DIR%\node.zip' -DestinationPath '%ENGINE_DIR%' -Force"
    if errorlevel 1 (
        echo   !RED![ERROR] Failed to extract Node.js!!RESET!
        del "%ENGINE_DIR%\node.zip" >nul 2>&1
        pause
        exit /b 1
    )
    ren "%ENGINE_DIR%\node-v%NODE_VERSION%-win-x64" "%NODE_DIR_NAME%"
    del "%ENGINE_DIR%\node.zip"
    echo   !GREEN![OK] Node.js installed to %NODE_DIR%!RESET!
)

set "PATH=%NODE_DIR%;%PATH%"

if not exist "%OC_BIN%" goto repair_engine
if not exist "%OC_CLI%" goto repair_engine
goto engine_ready
:repair_engine
if exist "%OPENCLAUDE_DIR%" (
    echo   !YELLOW![~] Incomplete OpenClaude Engine detected. Reinstalling...!RESET!
    rmdir /s /q "%OPENCLAUDE_DIR%"
)
call :install_engine "Installing"
if errorlevel 1 exit /b 1
:engine_ready

:: 2.1 Check GitPortable
if not exist "%GIT_BASH%" goto repair_git
if not exist "%GIT_EXE%" goto repair_git
goto git_ready
:repair_git
if exist "%GIT_DIR%" (
    echo   !YELLOW![~] Incomplete GitPortable detected. Reinstalling...!RESET!
    rmdir /s /q "%GIT_DIR%"
)
if not exist "%GIT_BASH%" (
    echo   !YELLOW![~] GitPortable not found for Windows-x64. Downloading...!RESET!
	curl.exe -L "https://github.com/git-for-windows/git/releases/download/v%GIT_VERSION%.windows.1/PortableGit-%GIT_VERSION%-64-bit.7z.exe" -o "%ENGINE_DIR%\GitPortable.exe"
    if errorlevel 1 (
        echo   !RED![ERROR] Failed to download GitPortable!!RESET!
        pause
        exit /b 1
    )
    echo   !YELLOW![~] Extracting GitPortable...!RESET!
    echo   !DIM!    This can be silent for a few minutes on external drives.!RESET!
    "%ENGINE_DIR%\GitPortable.exe" -o"%GIT_DIR%" -y
    if errorlevel 1 (
        echo   !RED![ERROR] Failed to extract GitPortable!!RESET!
        del "%ENGINE_DIR%\GitPortable.exe" >nul 2>&1
        pause
        exit /b 1
    )
    del "%ENGINE_DIR%\GitPortable.exe"
    if not exist "%GIT_BASH%" goto incomplete_git
    if not exist "%GIT_EXE%" goto incomplete_git
    echo   !GREEN![OK] GitPortable installed to %GIT_DIR%!RESET!
)

goto git_ready
:incomplete_git
echo   !RED![ERROR] GitPortable install is incomplete.!RESET!
echo   !DIM!        Missing expected files under %GIT_DIR%\bin!RESET!
pause
exit /b 1
:git_ready
set "CLAUDE_CODE_GIT_BASH_PATH=%GIT_BASH%"
set "GIT_BASH=%GIT_BASH%"
set "PATH=%GIT_DIR%\cmd;%GIT_DIR%\bin;%GIT_DIR%\usr\bin;%PATH%"

:: 3. Check for flags (--offline, --quick)
set "SKIP_UPDATE=0"
set "QUICK_MODE=0"
for %%A in (%*) do (
    if /I "%%A"=="--offline" set "SKIP_UPDATE=1"
    if /I "%%A"=="--quick" set "QUICK_MODE=1"
)

if !SKIP_UPDATE!==1 (
    echo   !DIM![~] Offline mode - skipping update check!RESET!
) else (
    :: Only check for updates once per day using a timestamp file
    set "UPDATE_STAMP=%DATA_DIR%\last_update_check.txt"
    set "TODAY_DATE="
    for /f "tokens=*" %%D in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd"') do set "TODAY_DATE=%%D"

    set "LAST_CHECK="
    if exist "!UPDATE_STAMP!" (
        set /p "LAST_CHECK="<"!UPDATE_STAMP!"
    )

    if "!LAST_CHECK!"=="!TODAY_DATE!" (
        echo   !DIM![~] Update check already done today - skipping!RESET!
    ) else (
        echo   !YELLOW![~] Checking for engine updates...!RESET!
        pushd "%ENGINE_DIR%"
        call npm.cmd outdated @gitlawb/openclaude >nul 2>&1
        if errorlevel 1 (
            echo   !YELLOW![~] New version detected! Upgrading...!RESET!
            call :install_engine "Upgrading"
            if errorlevel 1 exit /b 1
            echo   !GREEN![OK] Engine upgraded to latest version!!RESET!
        ) else (
            echo   !GREEN![OK] Engine is up to date!!RESET!
        )
        popd
        echo !TODAY_DATE!>"!UPDATE_STAMP!"
    )
)
echo.

:: 4. Check for settings file
if exist "%ENV_FILE%" (
    findstr /C:"AI_PROVIDER=" "%ENV_FILE%" >nul
    if errorlevel 1 (
        echo   !YELLOW![INFO] Legacy configuration detected. Upgrading format...!RESET!
        del "%ENV_FILE%"
    ) else (
        goto load_settings
    )
)

:: ---------------------------------------------------------
::   PROVIDER SELECTION MENU
:: ---------------------------------------------------------
echo !CYAN!=========================================================!RESET!
echo   !BOLD!AI PROVIDER SELECTION!RESET!
echo !CYAN!=========================================================!RESET!
echo.
echo   !CYAN!1)!RESET! !BOLD!OpenRouter!RESET!   !DIM!- 200+ Free and Paid Models!RESET!  !GREEN![RECOMMENDED]!RESET!
echo   !CYAN!2)!RESET! !BOLD!NVIDIA NIM!RESET!   !DIM!- High-Speed GPU Free Tier!RESET!   !GREEN![RECOMMENDED]!RESET!
echo   !CYAN!3)!RESET! !BOLD!DeepSeek!RESET!     !DIM!- DeepSeek API (OpenAI-compatible)!RESET!
echo   !CYAN!4)!RESET! !BOLD!Gemini!RESET!       !DIM!- Google AI API!RESET!
echo   !CYAN!5)!RESET! !BOLD!Claude!RESET!       !DIM!- Anthropic API!RESET!
echo   !CYAN!6)!RESET! !BOLD!OpenAI!RESET!       !DIM!- GPT / Codex API!RESET!
echo   !CYAN!7)!RESET! !BOLD!Ollama!RESET!       !DIM!- Local Offline AI (No internet)!RESET!
echo   !CYAN!8)!RESET! !BOLD!Custom!RESET!       !DIM!- Custom OpenAI-compatible API!RESET!
echo.
:prompt_provider
set "PROVIDER_SEL="
set /p "PROVIDER_SEL=  Select your provider !CYAN!(1-8)!RESET!: "

if "!PROVIDER_SEL!"=="1" goto setup_openrouter
if "!PROVIDER_SEL!"=="2" goto setup_nvidia
if "!PROVIDER_SEL!"=="3" goto setup_deepseek
if "!PROVIDER_SEL!"=="4" goto setup_gemini
if "!PROVIDER_SEL!"=="5" goto setup_claude
if "!PROVIDER_SEL!"=="6" goto setup_openai
if "!PROVIDER_SEL!"=="7" goto setup_ollama
if "!PROVIDER_SEL!"=="8" goto setup_custom
echo   !RED![ERROR] Invalid selection. Please choose 1-8.!RESET!
goto prompt_provider

:: ---------------------------------------------------------
::   OPENROUTER SETUP
:: ---------------------------------------------------------
:setup_openrouter
echo.
echo   !CYAN!--- OPENROUTER SETUP ---!RESET!
echo.
set /p "USER_API_KEY=  Enter your OpenRouter API Key: "
if "!USER_API_KEY!"=="" (
    echo   !RED![ERROR] API Key cannot be empty!!RESET!
    goto setup_openrouter
)
set "USER_API_KEY=!USER_API_KEY: =!"
:: Mask key for display
set "KEY_MASK=!USER_API_KEY:~0,6!****!USER_API_KEY:~-4!"
echo   !DIM!Key: !KEY_MASK!!RESET!
echo.
echo   !YELLOW![~] Verifying API Key... Please wait...!RESET!
powershell -NoProfile -Command "$headers = @{ 'Authorization' = 'Bearer !USER_API_KEY!' }; try { $response = Invoke-RestMethod -Uri 'https://openrouter.ai/api/v1/auth/key' -Headers $headers -ErrorAction Stop; exit 0 } catch { exit 1 }"
if errorlevel 1 (
    echo   !RED![ERROR] Invalid or expired OpenRouter API Key!!RESET!
    goto setup_openrouter
)
echo   !GREEN![OK] Key Verified!!RESET!
echo.
echo   Do you want to use !GREEN!Free!RESET! or !YELLOW!Paid!RESET! models?
echo   !CYAN!1)!RESET! Free Models
echo   !CYAN!2)!RESET! Paid Models
:prompt_tier
set "MODEL_TIER="
set /p "MODEL_TIER=  Select category !CYAN!(1 or 2)!RESET!: "

if "!MODEL_TIER!"=="1" goto setup_free
if "!MODEL_TIER!"=="2" goto setup_paid
echo   !RED![ERROR] Invalid selection. Please choose 1 or 2.!RESET!
goto prompt_tier

:setup_free
echo.
echo   !CYAN!--- FREE MODELS ---!RESET! !DIM!(Live Fetching...)!RESET!
set "idx=1"
for /f "delims=" %%I in ('powershell -NoProfile -Command "$d = (Invoke-RestMethod 'https://openrouter.ai/api/v1/models').data; $free = $d | Where-Object { $_.id -match ':free$' } | Select-Object -First 20 -ExpandProperty id; $free"') do (
    set "FREE_MODEL_!idx!=%%I"
    echo   !CYAN!!idx!^)!RESET! %%I
    set /a "idx+=1"
)
if "!idx!"=="1" (
    echo   !YELLOW![API Error] Could not fetch models, using fallback...!RESET!
    set "FREE_MODEL_1=qwen/qwen-2.5-coder-32b-instruct:free"
    echo   !CYAN!1^)!RESET! qwen/qwen-2.5-coder-32b-instruct:free
    set /a "idx=2"
)
set "FREE_MAX=!idx!"
echo   !CYAN!!FREE_MAX!^)!RESET! !DIM!Custom Free Model...!RESET!
echo.
:prompt_free_sel
set "FREE_SEL="
set /p "FREE_SEL=  Choose a model !CYAN!(1-!FREE_MAX!)!RESET!: "
if defined FREE_SEL (
    if "!FREE_SEL!"=="!FREE_MAX!" (
        set /p "USER_MODEL=  Enter custom model string: "
    ) else (
        for %%V in (!FREE_SEL!) do set "USER_MODEL=!FREE_MODEL_%%V!"
    )
)
if "!USER_MODEL!"=="" (
    echo   !RED![ERROR] Invalid selection. Please choose 1 to !FREE_MAX!.!RESET!
    goto prompt_free_sel
)
goto save_settings_openrouter

:setup_paid
echo.
echo   !CYAN!--- PAID MODELS ---!RESET! !DIM!(Live Fetching...)!RESET!
set "idx=1"
for /f "delims=" %%I in ('powershell -NoProfile -Command "$d = (Invoke-RestMethod 'https://openrouter.ai/api/v1/models').data; $paid = $d | Where-Object { $_.id -notmatch ':free$' } | Select-Object -First 20 -ExpandProperty id; $paid"') do (
    set "PAID_MODEL_!idx!=%%I"
    echo   !CYAN!!idx!^)!RESET! %%I
    set /a "idx+=1"
)
if "!idx!"=="1" (
    echo   !YELLOW![API Error] Could not fetch models, using fallback...!RESET!
    set "PAID_MODEL_1=anthropic/claude-3.5-sonnet"
    echo   !CYAN!1^)!RESET! anthropic/claude-3.5-sonnet
    set /a "idx=2"
)
set "PAID_MAX=!idx!"
echo   !CYAN!!PAID_MAX!^)!RESET! !DIM!Custom Paid Model...!RESET!
echo.
:prompt_paid_sel
set "PAID_SEL="
set /p "PAID_SEL=  Choose a model !CYAN!(1-!PAID_MAX!)!RESET!: "
if defined PAID_SEL (
    if "!PAID_SEL!"=="!PAID_MAX!" (
        set /p "USER_MODEL=  Enter custom model string: "
    ) else (
        for %%V in (!PAID_SEL!) do set "USER_MODEL=!PAID_MODEL_%%V!"
    )
)
if "!USER_MODEL!"=="" (
    echo   !RED![ERROR] Invalid selection. Please choose 1 to !PAID_MAX!.!RESET!
    goto prompt_paid_sel
)
goto save_settings_openrouter

:save_settings_openrouter
(
    echo # ========================================================
    echo # Portable AI - Master Switchboard
    echo # ========================================================
    echo AI_PROVIDER=openai
    echo CLAUDE_CODE_USE_OPENAI=1
    echo OPENAI_API_KEY=%USER_API_KEY%
    echo OPENAI_BASE_URL=https://openrouter.ai/api/v1
    echo OPENAI_MODEL=%USER_MODEL%
    echo AI_DISPLAY_MODEL=%USER_MODEL%
) > "%ENV_FILE%"
call :update_all_config_files
goto finish_setup

:: ---------------------------------------------------------
::   NVIDIA NIM SETUP
:: ---------------------------------------------------------
:setup_nvidia
echo.
echo   !CYAN!--- NVIDIA NIM SETUP ---!RESET!
echo.
set /p "USER_API_KEY=  Enter your NVIDIA API Key: "
if "!USER_API_KEY!"=="" (
    echo   !RED![ERROR] API Key cannot be empty!!RESET!
    goto setup_nvidia
)
set "USER_API_KEY=!USER_API_KEY: =!"
set "KEY_MASK=!USER_API_KEY:~0,6!****!USER_API_KEY:~-4!"
echo   !DIM!Key: !KEY_MASK!!RESET!
echo.
echo   !YELLOW![~] Verifying API Key... Please wait...!RESET!
powershell -NoProfile -Command "$headers = @{ 'Authorization' = 'Bearer !USER_API_KEY!' }; try { $response = Invoke-RestMethod -Uri 'https://integrate.api.nvidia.com/v1/models' -Headers $headers -ErrorAction Stop; exit 0 } catch { exit 1 }"
if errorlevel 1 (
    echo   !RED![ERROR] Invalid or expired NVIDIA API Key!!RESET!
    goto setup_nvidia
)
echo   !GREEN![OK] Key Verified!!RESET!
echo.
echo   !CYAN!--- NVIDIA MODELS ---!RESET! !DIM!(Live + Curated)!RESET!
set "idx=1"
for %%M in (
    "moonshotai/kimi-k2-instruct" "moonshotai/kimi-k2-thinking" "z-ai/glm4.7"
    "deepseek-ai/deepseek-v3.2" "deepseek-ai/deepseek-v3.1-terminus" "stepfun-ai/step-3.5-flash"
    "mistralai/mistral-large-3-675b-instruct-2512" "qwen/qwen3-coder-480b-a35b-instruct"
    "mistralai/mistral-nemotron" "bytedance/seed-oss-36b-instruct" "mistralai/mamba-codestral-7b-v0.1"
    "google/gemma-7b" "tiiuae/falcon3-7b-instruct" "minimaxai/minimax-m2.7"
) do (
    set "NVIDIA_MODEL_!idx!=%%~M"
    echo   !CYAN!!idx!^)!RESET! %%~M
    set /a "idx+=1"
)
for /f "delims=" %%I in ('powershell -NoProfile -Command "$headers = @{ 'Authorization' = 'Bearer !USER_API_KEY!' }; try { $d = (Invoke-RestMethod -Uri 'https://integrate.api.nvidia.com/v1/models' -Headers $headers).data; $d | Select-Object -ExpandProperty id | Select-Object -First 40 } catch { }"') do (
    set "EXISTS=0"
    for /L %%K in (1,1,14) do (
        if "%%I"=="!NVIDIA_MODEL_%%K!" set "EXISTS=1"
    )
    if !EXISTS!==0 (
        set "NVIDIA_MODEL_!idx!=%%I"
        echo   !CYAN!!idx!^)!RESET! %%I
        set /a "idx+=1"
    )
)
if "!idx!"=="1" (
    echo   !YELLOW![API Error] Could not fetch models, using fallback...!RESET!
    set "NVIDIA_MODEL_1=meta/llama-3.1-70b-instruct"
    echo   !CYAN!1^)!RESET! meta/llama-3.1-70b-instruct
    set /a "idx=2"
)
set "MAX_IDX=!idx!"
echo   !CYAN!!MAX_IDX!^)!RESET! !DIM!Custom NVIDIA Model...!RESET!
echo.
:prompt_nvidia_sel
set "MODEL_SEL="
set /p "MODEL_SEL=  Choose a model !CYAN!(1-!MAX_IDX!)!RESET!: "
if defined MODEL_SEL (
    if "!MODEL_SEL!"=="!MAX_IDX!" (
        set /p "USER_MODEL=  Enter custom model string: "
    ) else (
        for %%V in (!MODEL_SEL!) do set "USER_MODEL=!NVIDIA_MODEL_%%V!"
    )
)
if "!USER_MODEL!"=="" (
    echo   !RED![ERROR] Invalid selection. Please choose 1 to !MAX_IDX!.!RESET!
    goto prompt_nvidia_sel
)

:save_settings_nvidia
(
    echo AI_PROVIDER=openai
    echo CLAUDE_CODE_USE_OPENAI=1
    echo OPENAI_API_KEY=%USER_API_KEY%
    echo OPENAI_BASE_URL=https://integrate.api.nvidia.com/v1
    echo OPENAI_MODEL=%USER_MODEL%
    echo AI_DISPLAY_MODEL=%USER_MODEL%
) > "%ENV_FILE%"
call :update_all_config_files
goto finish_setup

:: ---------------------------------------------------------
::   DEEPSEEK SETUP
:: ---------------------------------------------------------
:setup_deepseek
echo.
echo   !CYAN!--- DEEPSEEK SETUP ---!RESET!
echo.
set /p "USER_API_KEY=  Enter your DeepSeek API Key: "
if "!USER_API_KEY!"=="" (
    echo   !RED![ERROR] API Key cannot be empty!!RESET!
    goto setup_deepseek
)
set "USER_API_KEY=!USER_API_KEY: =!"
set "KEY_MASK=!USER_API_KEY:~0,6!****!USER_API_KEY:~-4!"
echo   !DIM!Key: !KEY_MASK!!RESET!
echo.
echo   !YELLOW![~] Verifying API Key... Please wait...!RESET!
powershell -NoProfile -Command "$headers = @{ 'Authorization' = 'Bearer !USER_API_KEY!' }; try { $response = Invoke-RestMethod -Uri 'https://api.deepseek.com/models' -Headers $headers -ErrorAction Stop; exit 0 } catch { exit 1 }"
if errorlevel 1 (
    echo   !RED![ERROR] Invalid or expired DeepSeek API Key!!RESET!
    goto setup_deepseek
)
echo   !GREEN![OK] Key Verified!!RESET!
echo.
echo   !CYAN!--- DEEPSEEK MODELS ---!RESET! !DIM!(Live Fetching...)!RESET!
set "idx=1"
for /f "delims=" %%I in ('powershell -NoProfile -Command "$headers = @{ 'Authorization' = 'Bearer !USER_API_KEY!' }; try { $d = (Invoke-RestMethod -Uri 'https://api.deepseek.com/models' -Headers $headers).data; $d | Select-Object -ExpandProperty id } catch { }"') do (
    set "DEEPSEEK_MODEL_!idx!=%%I"
    echo   !CYAN!!idx!^)!RESET! %%I
    set /a "idx+=1"
)
if "!idx!"=="1" (
    echo   !YELLOW![API Error] Could not fetch models, using fallback...!RESET!
    set "DEEPSEEK_MODEL_1=deepseek-v4-flash"
    echo   !CYAN!1^)!RESET! deepseek-v4-flash
    set "DEEPSEEK_MODEL_2=deepseek-v4-pro"
    echo   !CYAN!2^)!RESET! deepseek-v4-pro
    set /a "idx=3"
)
set "MAX_IDX=!idx!"
echo   !CYAN!!MAX_IDX!^)!RESET! !DIM!Custom DeepSeek Model...!RESET!
echo.
:prompt_deepseek_sel
set "MODEL_SEL="
set /p "MODEL_SEL=  Choose a model !CYAN!(1-!MAX_IDX!)!RESET! [Enter for 1]: "
if not defined MODEL_SEL set "MODEL_SEL=1"
if "!MODEL_SEL!"=="" set "MODEL_SEL=1"
if "!MODEL_SEL!"=="!MAX_IDX!" (
    set /p "USER_MODEL=  Enter custom model string: "
) else (
    for %%V in (!MODEL_SEL!) do set "USER_MODEL=!DEEPSEEK_MODEL_%%V!"
)
if "!USER_MODEL!"=="" (
    echo   !RED![ERROR] Invalid selection.!RESET!
    goto prompt_deepseek_sel
)
(
    echo AI_PROVIDER=openai
    echo CLAUDE_CODE_USE_OPENAI=1
    echo OPENAI_API_KEY=%USER_API_KEY%
    echo OPENAI_BASE_URL=https://api.deepseek.com
    echo OPENAI_MODEL=%USER_MODEL%
    echo AI_DISPLAY_MODEL=%USER_MODEL%
) > "%ENV_FILE%"
call :update_all_config_files
goto finish_setup

:: ---------------------------------------------------------
::   GEMINI SETUP
:: ---------------------------------------------------------
:setup_gemini
echo.
echo   !CYAN!--- GEMINI SETUP ---!RESET!
echo.
set /p "USER_API_KEY=  Enter your Gemini API Key: "
if "!USER_API_KEY!"=="" (
    echo   !RED![ERROR] API Key cannot be empty!!RESET!
    goto setup_gemini
)
set "USER_API_KEY=!USER_API_KEY: =!"
set "KEY_MASK=!USER_API_KEY:~0,6!****!USER_API_KEY:~-4!"
echo   !DIM!Key: !KEY_MASK!!RESET!
echo.
echo   !YELLOW![~] Verifying API Key... Please wait...!RESET!
powershell -NoProfile -Command "try { $response = Invoke-RestMethod -Uri 'https://generativelanguage.googleapis.com/v1beta/models?key=!USER_API_KEY!' -ErrorAction Stop; exit 0 } catch { exit 1 }"
if errorlevel 1 (
    echo   !RED![ERROR] Invalid or expired Gemini API Key!!RESET!
    goto setup_gemini
)
echo   !GREEN![OK] Key Verified!!RESET!
echo.
echo   !CYAN!--- GEMINI MODELS ---!RESET! !DIM!(Live Fetching...)!RESET!
set "idx=1"
    set "FETCH_CMD=$d = (Invoke-RestMethod 'https://generativelanguage.googleapis.com/v1alpha/models?key=!USER_API_KEY!').models; if ($null -ne $d) { $d | Where-Object { $_.supportedGenerationMethods -contains 'generateContent' -and $_.name -notmatch 'vision|embedding|banana|lyria|robot|research|computer' } | Select-Object -ExpandProperty name | ForEach-Object { $_.Replace('models/', '') } | Select-Object -First 40 }"
for /f "delims=" %%I in ('powershell -NoProfile -Command "!FETCH_CMD!"') do (
    set "GEMINI_MODEL_!idx!=%%I"
    echo   !CYAN!!idx!^)!RESET! %%I
    set /a "idx+=1"
)
if "!idx!"=="1" (
    echo   !YELLOW![API Error] Could not fetch models, using fallback...!RESET!
    set "GEMINI_MODEL_1=gemini-2.5-pro"
    echo   !CYAN!1^)!RESET! gemini-2.5-pro
    set /a "idx=2"
)
set "MAX_IDX=!idx!"
echo   !CYAN!!MAX_IDX!^)!RESET! !DIM!Custom Gemini Model...!RESET!
echo.
:prompt_gemini_sel
set "MODEL_SEL="
set /p "MODEL_SEL=  Choose a model !CYAN!(1-!MAX_IDX!)!RESET! [Enter for 1]: "
if not defined MODEL_SEL set "MODEL_SEL=1"
if "!MODEL_SEL!"=="" set "MODEL_SEL=1"
if "!MODEL_SEL!"=="!MAX_IDX!" (
    set /p "USER_MODEL=  Enter custom model string: "
) else (
    for %%V in (!MODEL_SEL!) do set "USER_MODEL=!GEMINI_MODEL_%%V!"
)
if "!USER_MODEL!"=="" (
    echo   !RED![ERROR] Invalid selection.!RESET!
    goto prompt_gemini_sel
)
(
    echo AI_PROVIDER=gemini
    echo CLAUDE_CODE_USE_GEMINI=1
    echo GEMINI_API_KEY=%USER_API_KEY%
    echo GEMINI_MODEL=%USER_MODEL%
    echo AI_DISPLAY_MODEL=%USER_MODEL%
) > "%ENV_FILE%"
call :update_all_config_files
goto finish_setup

:: ---------------------------------------------------------
::   CLAUDE SETUP
:: ---------------------------------------------------------
:setup_claude
echo.
echo   !CYAN!--- CLAUDE SETUP ---!RESET!
echo.
set /p "USER_API_KEY=  Enter your Anthropic API Key: "
if "!USER_API_KEY!"=="" (
    echo   !RED![ERROR] API Key cannot be empty!!RESET!
    goto setup_claude
)
set "USER_API_KEY=!USER_API_KEY: =!"
set "KEY_MASK=!USER_API_KEY:~0,6!****!USER_API_KEY:~-4!"
echo   !DIM!Key: !KEY_MASK!!RESET!
echo.
echo   !YELLOW![~] Verifying API Key... Please wait...!RESET!
powershell -NoProfile -Command "$headers = @{ 'x-api-key' = '!USER_API_KEY!'; 'anthropic-version' = '2023-06-01' }; try { $response = Invoke-RestMethod -Uri 'https://api.anthropic.com/v1/models' -Headers $headers -ErrorAction Stop; exit 0 } catch { exit 1 }"
if errorlevel 1 (
    echo   !RED![ERROR] Invalid or expired Anthropic API Key!!RESET!
    goto setup_claude
)
echo   !GREEN![OK] Key Verified!!RESET!
echo.
set /p "USER_MODEL=  Enter Model !DIM!(Enter for claude-3-7-sonnet-20250219)!RESET!: "
if "%USER_MODEL%"=="" set "USER_MODEL=claude-3-7-sonnet-20250219"
(
    echo AI_PROVIDER=anthropic
    echo ANTHROPIC_AUTH_TOKEN=%USER_API_KEY%
    echo ANTHROPIC_BASE_URL=https://api.anthropic.com/v1
    echo ANTHROPIC_MODEL=%USER_MODEL%
    echo AI_DISPLAY_MODEL=%USER_MODEL%
) > "%ENV_FILE%"
call :update_all_config_files
goto finish_setup

:: ---------------------------------------------------------
::   OLLAMA SETUP
:: ---------------------------------------------------------
:setup_ollama
echo.
echo   !CYAN!--- OLLAMA LOCAL SETUP ---!RESET!
echo.
set /p "USER_MODEL=  Enter local model !DIM!(Enter for llama3.2:3b)!RESET!: "
if "%USER_MODEL%"=="" set "USER_MODEL=llama3.2:3b"
(
    echo AI_PROVIDER=ollama
    echo CLAUDE_CODE_USE_OPENAI=1
    echo OPENAI_API_KEY=ollama
    echo OPENAI_BASE_URL=http://localhost:11434/v1
    echo OPENAI_MODEL=%USER_MODEL%
    echo AI_DISPLAY_MODEL=%USER_MODEL%
) > "%ENV_FILE%"
call :update_all_config_files
goto finish_setup

:: ---------------------------------------------------------
::   CUSTOM PROVIDER SETUP
:: ---------------------------------------------------------
:setup_custom
echo.
echo   !CYAN!--- CUSTOM PROVIDER SETUP ---!RESET!
echo.
echo   Select API Type:
echo   !CYAN!1)!RESET! OpenAI-compatible API
echo   !CYAN!2)!RESET! Anthropic-compatible API
echo.
:prompt_api_type
set "API_TYPE="
set /p "API_TYPE=  Select API type !CYAN!(1 or 2)!RESET!: "
if "!API_TYPE!"=="" goto prompt_api_type
if "!API_TYPE!"=="1" set "CUSTOM_API_TYPE=openai" && goto custom_openai
if "!API_TYPE!"=="2" set "CUSTOM_API_TYPE=anthropic" && goto custom_anthropic
echo   !RED![ERROR] Invalid selection. Please choose 1 or 2.!RESET!
goto prompt_api_type

:custom_openai
echo.
set /p "USER_API_URL=  Enter API Base URL !DIM!(e.g., https://api.example.com/v1)!RESET!: "
if "!USER_API_URL!"=="" (
    echo   !RED![ERROR] API Base URL cannot be empty!!RESET!
    goto custom_openai
)
echo.
set /p "USER_API_KEY=  Enter your API Key: "
if "!USER_API_KEY!"=="" (
    echo   !RED![ERROR] API Key cannot be empty!!RESET!
    goto custom_openai
)
set "USER_API_KEY=!USER_API_KEY: =!"
set "KEY_MASK=!USER_API_KEY:~0,6!****!USER_API_KEY:~-4!"
echo   !DIM!Key: !KEY_MASK!!RESET!
echo.
set /p "USER_MODEL=  Enter Model Name !DIM!(e.g., gpt-4o)!RESET!: "
if "!USER_MODEL!"=="" (
    echo   !RED![ERROR] Model name cannot be empty!!RESET!
    goto custom_openai
)
(
    echo AI_PROVIDER=custom
    echo CLAUDE_CODE_USE_OPENAI=1
    echo OPENAI_API_KEY=!USER_API_KEY!
    echo OPENAI_BASE_URL=!USER_API_URL!
    echo OPENAI_MODEL=!USER_MODEL!
    echo AI_DISPLAY_MODEL=!USER_MODEL!
) > "%ENV_FILE%"
call :update_all_config_files
goto finish_setup

:custom_anthropic
echo.
set /p "USER_API_URL=  Enter API Base URL !DIM!(e.g., https://api.anthropic.com/v1)!RESET!: "
if "!USER_API_URL!"=="" (
    echo   !RED![ERROR] API Base URL cannot be empty!!RESET!
    goto custom_anthropic
)
echo.
set /p "USER_API_KEY=  Enter your API Key: "
if "!USER_API_KEY!"=="" (
    echo   !RED![ERROR] API Key cannot be empty!!RESET!
    goto custom_anthropic
)
set "USER_API_KEY=!USER_API_KEY: =!"
set "KEY_MASK=!USER_API_KEY:~0,6!****!USER_API_KEY:~-4!"
echo   !DIM!Key: !KEY_MASK!!RESET!
echo.
set /p "USER_MODEL=  Enter Model Name !DIM!(e.g., claude-3-5-sonnet)!RESET!: "
if "!USER_MODEL!"=="" (
    echo   !RED![ERROR] Model name cannot be empty!!RESET!
    goto custom_anthropic
)
(
    echo AI_PROVIDER=custom
    echo CLAUDE_CODE_USE_OPENAI=0
    echo ANTHROPIC_AUTH_TOKEN=!USER_API_KEY!
    echo ANTHROPIC_BASE_URL=!USER_API_URL!
    echo ANTHROPIC_MODEL=!USER_MODEL!
    echo AI_DISPLAY_MODEL=!USER_MODEL!
) > "%ENV_FILE%"
call :update_all_config_files
goto finish_setup

:: ---------------------------------------------------------
::   OPENAI SETUP
:: ---------------------------------------------------------
:setup_openai
echo.
echo   !CYAN!--- OPENAI / CODEX SETUP ---!RESET!
echo.
set /p "USER_API_KEY=  Enter your OpenAI API Key: "
if "!USER_API_KEY!"=="" (
    echo   !RED![ERROR] API Key cannot be empty!!RESET!
    goto setup_openai
)
set "USER_API_KEY=!USER_API_KEY: =!"
set "KEY_MASK=!USER_API_KEY:~0,6!****!USER_API_KEY:~-4!"
echo   !DIM!Key: !KEY_MASK!!RESET!
echo.
echo   !YELLOW![~] Verifying API Key... Please wait...!RESET!
powershell -NoProfile -Command "$headers = @{ 'Authorization' = 'Bearer !USER_API_KEY!' }; try { $response = Invoke-RestMethod -Uri 'https://api.openai.com/v1/models' -Headers $headers -ErrorAction Stop; exit 0 } catch { exit 1 }"
if errorlevel 1 (
    echo   !RED![ERROR] Invalid or expired OpenAI API Key!!RESET!
    goto setup_openai
)
echo   !GREEN![OK] Key Verified!!RESET!
echo.
set /p "USER_MODEL=  Enter Model !DIM!(Enter for gpt-4o)!RESET!: "
if "%USER_MODEL%"=="" set "USER_MODEL=gpt-4o"
(
    echo AI_PROVIDER=openai
    echo CLAUDE_CODE_USE_OPENAI=1
    echo OPENAI_API_KEY=%USER_API_KEY%
    echo OPENAI_BASE_URL=https://api.openai.com/v1
    echo OPENAI_MODEL=%USER_MODEL%
    echo AI_DISPLAY_MODEL=%USER_MODEL%
) > "%ENV_FILE%"
call :update_all_config_files
goto finish_setup

:: ---------------------------------------------------------
::   UPDATE ALL CONFIG FILES (Provider Settings)
:: ---------------------------------------------------------
:update_all_config_files
set "PROFILE_DIR=%DATA_DIR%\openclaude"
if not exist "!PROFILE_DIR!" mkdir "!PROFILE_DIR!"

:: Read current settings from env file
for /f "usebackq tokens=1,* delims==" %%A in ("%ENV_FILE%") do (
    set "%%A=%%B"
)

:: Write .openclaude-profile.json
set "PS1_FILE=%TEMP%\oc_profile.ps1"
(
    echo $f = '!PROFILE_DIR!\.openclaude-profile.json'
    echo if ^(Test-Path $f^) { try { $p = Get-Content $f -Raw ^| ConvertFrom-Json } catch { $p = [pscustomobject]@{} } } else { $p = [pscustomobject]@{} }
    echo if ^($null -eq $p.env^) { $p ^| Add-Member -NotePropertyName env -NotePropertyValue ^(@{}^) -Force }
    echo if ^($null -eq $p.profile^) { $p ^| Add-Member -NotePropertyName profile -NotePropertyValue '' -Force }
    echo $p.profile = '!AI_PROVIDER!'
    echo $p.env = @{}
    echo $p.env['CLAUDE_CODE_USE_OPENAI'] = '!CLAUDE_CODE_USE_OPENAI!'
    echo $p.env['OPENAI_API_KEY'] = '!OPENAI_API_KEY!'
    echo $p.env['OPENAI_BASE_URL'] = '!OPENAI_BASE_URL!'
    echo $p.env['OPENAI_MODEL'] = '!OPENAI_MODEL!'
    echo $p.env['ANTHROPIC_API_KEY'] = '!ANTHROPIC_AUTH_TOKEN!'
    echo $p.env['ANTHROPIC_BASE_URL'] = '!ANTHROPIC_BASE_URL!'
    echo $p.env['ANTHROPIC_MODEL'] = '!ANTHROPIC_MODEL!'
    echo $p.env['GEMINI_API_KEY'] = '!GEMINI_API_KEY!'
    echo $p.env['GEMINI_MODEL'] = '!GEMINI_MODEL!'
    echo $p.env['AI_DISPLAY_MODEL'] = '!AI_DISPLAY_MODEL!'
    echo $p.env['CLAUDE_CODE_USE_GEMINI'] = '!CLAUDE_CODE_USE_GEMINI!'
    echo $p ^| ConvertTo-Json -Depth 10 ^| Set-Content $f -Encoding UTF8
) > "!PS1_FILE!"
powershell -NoProfile -ExecutionPolicy Bypass -File "!PS1_FILE!"
del "!PS1_FILE!" 2>nul

:: Update .claude.json
set "PS1_FILE=%TEMP%\oc_claude.ps1"
(
    echo $f = '!PROFILE_DIR!\.claude.json'
    echo if ^(Test-Path $f^) { try { $j = Get-Content $f -Raw ^| ConvertFrom-Json } catch { $j = [pscustomobject]@{} } } else { $j = [pscustomobject]@{} }
    echo if ^($null -eq $j.env^) { $j ^| Add-Member -NotePropertyName env -NotePropertyValue ^(@{}^) -Force }
    echo $j.env = @{}
    echo $j.env['CLAUDE_CODE_USE_OPENAI'] = '!CLAUDE_CODE_USE_OPENAI!'
    echo $j.env['OPENAI_API_KEY'] = '!OPENAI_API_KEY!'
    echo $j.env['OPENAI_BASE_URL'] = '!OPENAI_BASE_URL!'
    echo $j.env['OPENAI_MODEL'] = '!OPENAI_MODEL!'
    echo $j.env['ANTHROPIC_API_KEY'] = '!ANTHROPIC_AUTH_TOKEN!'
    echo $j.env['ANTHROPIC_BASE_URL'] = '!ANTHROPIC_BASE_URL!'
    echo $j.env['ANTHROPIC_MODEL'] = '!ANTHROPIC_MODEL!'
    echo $j.env['GEMINI_API_KEY'] = '!GEMINI_API_KEY!'
    echo $j.env['GEMINI_MODEL'] = '!GEMINI_MODEL!'
    echo $j.env['AI_DISPLAY_MODEL'] = '!AI_DISPLAY_MODEL!'
    echo $j.env['CLAUDE_CODE_USE_GEMINI'] = '!CLAUDE_CODE_USE_GEMINI!'
    echo $j.env['API_TIMEOUT_MS'] = '3000000'
    echo $j.env['CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC'] = '1'
    echo $j ^| ConvertTo-Json -Depth 10 ^| Set-Content $f -Encoding UTF8
) > "!PS1_FILE!"
powershell -NoProfile -ExecutionPolicy Bypass -File "!PS1_FILE!"
del "!PS1_FILE!" 2>nul
exit /b 0

:finish_setup
echo.
echo   !GREEN![OK] Settings saved!!RESET!
echo.

:: ---------------------------------------------------------
::   LOAD SETTINGS + WELCOME BACK SCREEN
:: ---------------------------------------------------------
:load_settings
:: Load the settings from ai_settings.env
for /f "usebackq tokens=1,* delims==" %%A in ("%ENV_FILE%") do (
    set "%%A=%%~B"
)

if not "!AI_PROVIDER!"=="anthropic" (
    if not "!AI_PROVIDER!"=="custom" (
        set "ANTHROPIC_AUTH_TOKEN="
    )
)
if "!AI_PROVIDER!"=="custom" (
    if "!CLAUDE_CODE_USE_OPENAI!"=="0" (
        set "CLAUDE_CODE_USE_GEMINI=0"
        set "OPENAI_API_KEY="
    )
    if "!CLAUDE_CODE_USE_OPENAI!"=="1" (
        set "CLAUDE_CODE_USE_GEMINI=0"
        set "ANTHROPIC_AUTH_TOKEN="
    )
)

:: Friendly provider name
set "PROVIDER_NAME=!AI_PROVIDER!"
if "!AI_PROVIDER!"=="openai" (
    if defined OPENAI_BASE_URL (
        echo !OPENAI_BASE_URL! | findstr /C:"openrouter" >nul && set "PROVIDER_NAME=OpenRouter"
        echo !OPENAI_BASE_URL! | findstr /C:"integrate.api.nvidia.com" >nul && set "PROVIDER_NAME=NVIDIA NIM"
        echo !OPENAI_BASE_URL! | findstr /C:"api.deepseek.com" >nul && set "PROVIDER_NAME=DeepSeek"
        echo !OPENAI_BASE_URL! | findstr /C:"api.openai.com" >nul && set "PROVIDER_NAME=OpenAI"
        echo !OPENAI_BASE_URL! | findstr /C:"localhost:11434" >nul && set "PROVIDER_NAME=Ollama"
    )
)
if "!AI_PROVIDER!"=="gemini" set "PROVIDER_NAME=Google Gemini"
if "!AI_PROVIDER!"=="anthropic" set "PROVIDER_NAME=Anthropic Claude"
if "!AI_PROVIDER!"=="ollama" set "PROVIDER_NAME=Ollama (Local)"
if "!AI_PROVIDER!"=="custom" set "PROVIDER_NAME=Custom"

title Portable AI USB - !PROVIDER_NAME! - !AI_DISPLAY_MODEL!

echo !CYAN!=========================================================!RESET!
echo   !BOLD!Claude Code - Ready (Multi-Platform)!RESET!
echo !CYAN!=========================================================!RESET!
echo.
echo   !BOLD!Provider!RESET! : !GREEN!!PROVIDER_NAME!!RESET!
echo   !BOLD!Model!RESET!    : !GREEN!!AI_DISPLAY_MODEL!!RESET!
echo   !BOLD!Data!RESET!     : !DIM!Portable Mode (No PC Leaks)!RESET!
echo.
echo !CYAN!=========================================================!RESET!
echo.

:prompt_launch_mode
:: Quick mode: skip menu, go straight to limitless
if !QUICK_MODE!==1 (
    echo   !RED!!BOLD!QUICK LAUNCH - Limitless Mode!RESET!
    goto launch_limitless
)
echo   !BOLD!Select Action:!RESET!
echo   🚀 !CYAN!1)!RESET! !GREEN!Launch AI!RESET!       !DIM!- Normal Mode (Auto-starts in 10s)!RESET!
echo   ⚡ !CYAN!2)!RESET! !RED!Limitless Mode!RESET!  !DIM!- Auto-executes everything (Advanced)!RESET!
echo   !DIM!─────────────────────────────────────────────────────────!RESET!
echo   📊 !CYAN!3)!RESET! !BOLD!Open Dashboard!RESET!  !DIM!- View your chats visually!RESET!
echo   ⚙️  !CYAN!4)!RESET! !BOLD!Change Provider!RESET! !DIM!- Switch your AI provider or API Key!RESET!
echo   💾 !CYAN!5)!RESET! !BOLD!Setup Offline!RESET!   !DIM!- Download local AI models (Ollama)!RESET!
echo.
echo   !DIM!  Auto-launching in 10 seconds... press a key to choose.!RESET!
echo.
set /p "=  Select action (1-5): " <nul
choice /c 12345 /n /t 10 /d 1
set "LAUNCH_MODE=!ERRORLEVEL!"
:menu_done
echo.

if "!LAUNCH_MODE!"=="1" goto launch_normal
if "!LAUNCH_MODE!"=="2" goto launch_limitless
if "!LAUNCH_MODE!"=="3" (
    echo.
    call "%USB_ROOT%tools\Open_Dashboard.bat"
    exit /b
)
if "!LAUNCH_MODE!"=="4" (
    echo.
    call "%USB_ROOT%tools\Change_Provider.bat"
    exit /b
)
if "!LAUNCH_MODE!"=="5" (
    echo.
    call "%USB_ROOT%tools\Setup_Local_Models.bat"
    exit /b
)
echo   !RED![ERROR] Invalid selection.!RESET!
echo.
goto prompt_launch_mode

:launch_limitless
echo.
echo   !RED!!BOLD![!] LIMITLESS MODE ACTIVATED!RESET!
set "CMD_ARGS=--dangerously-skip-permissions"
goto do_launch

:launch_normal
echo.
echo   !GREEN![OK] Normal mode selected.!RESET!
set "CMD_ARGS="
goto do_launch

:do_launch
if not "!AI_PROVIDER!"=="ollama" goto skip_ollama_start
if not exist "%DATA_DIR%\ollama\ollama.exe" goto skip_ollama_start

echo   !CYAN![~] Starting Local Ollama Server...!RESET!
set "OLLAMA_MODELS=%DATA_DIR%\ollama\data"
start "Ollama Portable" /B /MIN "%DATA_DIR%\ollama\ollama.exe" serve >nul 2>&1
timeout /t 3 /nobreak >nul
echo   !GREEN![OK] Ollama running!RESET!

if not exist "%USB_ROOT%tools\local-proxy.js" goto skip_proxy_start
echo   !CYAN![~] Starting local speed proxy (trims system prompt)...!RESET!
REM Surgical kill: find any node process running local-proxy.js and kill it
powershell -NoProfile -Command "Get-CimInstance Win32_Process -Filter 'Name = ''node.exe''' | Where-Object { $_.CommandLine -like '*local-proxy.js*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }" >nul 2>&1
start "LocalProxy" /B /MIN "%NODE_DIR%\node.exe" "%USB_ROOT%tools\local-proxy.js"
timeout /t 2 /nobreak >nul
set "OPENAI_BASE_URL=http://localhost:11435/v1"
echo   !GREEN![OK] Speed proxy active - system prompt trimming enabled!RESET!

:skip_proxy_start
echo.

:skip_ollama_start


echo   !CYAN![~] Starting AI Engine...!RESET!
echo.

set "PROVIDER_ARGS="
if defined AI_PROVIDER (
    if "!AI_PROVIDER!"=="custom" (
        if "!CLAUDE_CODE_USE_OPENAI!"=="0" (
            set "PROVIDER_ARGS=--provider custom"
        ) else (
            set "PROVIDER_ARGS=--provider openai"
        )
    ) else (
        set "PROVIDER_ARGS=--provider !AI_PROVIDER!"
    )
)

:: Preload fs.promises.rm patch for Windows read-only .git files
if exist "%ENGINE_DIR%\win32-rm-patch.cjs" (
    for %%P in ("%ENGINE_DIR%\win32-rm-patch.cjs") do set "NODE_OPTIONS=--require %%~fP"
)

pushd "%ENGINE_DIR%"
if exist "%OC_BIN%" goto use_oc_bin
echo   !RED![ERROR] OpenClaude Engine is missing. Restart START.bat to repair the install.!RESET!
goto engine_done
:use_oc_bin
call "%NODE_DIR%\node.exe" "%OC_BIN%" !PROVIDER_ARGS! !CMD_ARGS!
:engine_done
popd

:: Clear NODE_OPTIONS so host isn't affected
set "NODE_OPTIONS="

if not "!AI_PROVIDER!"=="ollama" goto skip_ollama_stop
if not exist "%DATA_DIR%\ollama\ollama.exe" goto skip_ollama_stop
echo.
echo   !CYAN![~] Stopping Local Ollama Server...!RESET!
taskkill /F /IM ollama.exe >nul 2>&1
powershell -NoProfile -Command "Get-CimInstance Win32_Process -Filter 'Name = ''node.exe''' | Where-Object { $_.CommandLine -like '*local-proxy.js*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }" >nul 2>&1
:skip_ollama_stop

pause
