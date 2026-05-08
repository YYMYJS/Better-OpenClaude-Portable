#!/usr/bin/env bash
# ============================================================
# Switch to Portable OpenClaude environment on this USB drive.
# Source this script to enter the portable context:
#   source tools/enter-portable.sh
# Or run a command in the portable context:
#   ./tools/enter-portable.sh openclaude /plugins
# ============================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USB_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="$USB_ROOT/data"
ENGINE_DIR="$USB_ROOT/engine"

echo "=== Portable OpenClaude Environment ==="
echo "  USB Root:  $USB_ROOT"
echo "  Config:    $DATA_DIR/openclaude"
echo "  Plugins:   $DATA_DIR/openclaude/plugins"
echo "  Skills:    $DATA_DIR/openclaude/skills"
echo "  Cache:     $DATA_DIR/cache/claude-cli"
echo ""

# Verify
if [ ! -f "$ENGINE_DIR/package.json" ] || [ ! -f "$DATA_DIR/ai_settings.env" ]; then
  echo "[ERROR] Doesn't look like an OpenClaude Portable USB!"
  echo "        Missing engine/package.json or data/ai_settings.env"
  exit 1
fi

# Export all portable env vars
export CLAUDE_CONFIG_DIR="$DATA_DIR/openclaude"
export XDG_CONFIG_HOME="$DATA_DIR/config"
export XDG_DATA_HOME="$DATA_DIR/app_data"
export XDG_CACHE_HOME="$DATA_DIR/cache"
export npm_config_cache="$DATA_DIR/npm-cache"
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1"

# Preload fs.promises.rm patch (Windows only, harmless elsewhere)
RM_PATCH="$ENGINE_DIR/win32-rm-patch.cjs"
[ -f "$RM_PATCH" ] && export NODE_OPTIONS="--require $RM_PATCH"

# Add portable Node to PATH
NODE_DIR="$ENGINE_DIR/node-$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m)"
if [ -d "$NODE_DIR/bin" ]; then
  export PATH="$NODE_DIR/bin:$PATH"
fi

# Source ai_settings.env
if [ -f "$DATA_DIR/ai_settings.env" ]; then
  while IFS='=' read -r key val; do
    if [[ "$key" != "#"* ]] && [ -n "$key" ]; then
      export "$key=$val"
    fi
  done < "$DATA_DIR/ai_settings.env"
fi

# Check if being sourced or executed
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  # Being sourced — modify PS1 to remind user
  export PS1="USB-OC> "
  echo "Entering portable subshell. Type exit to return to host."
else
  # Execute a command
  if [ $# -gt 0 ]; then
    echo "Running in portable context: $*"
    exec "$@"
  else
    echo "Entering portable subshell. Type exit to return to host."
    export PS1="USB-OC> "
    exec "$SHELL"
  fi
fi
