# OpenClaude Portable 修改记录 - 2026-05-07

## 1. 修复 MiniMax API (custom profile) 401 错误

### 问题
OpenClaude 使用 custom profile 时返回 401 invalid api key 错误。

### 根本原因
`isProviderProfile("custom")` 返回 `false`，导致 `.openclaude-profile.json` 被拒绝。

### 修复文件
- `engine/node_modules/@gitlawb/openclaude/dist/cli.mjs` 第 39602 行

### 修改内容
在 `isProviderProfile()` 函数中添加了 `"custom"` 到有效 provider 列表：

```javascript
function isProviderProfile(value) {
  return value === "anthropic" || value === "openai" || value === "ollama" ||
    value === "codex" || value === "gemini" || value === "atomic-chat" ||
    value === "nvidia-nim" || value === "minimax" || value === "mistral" ||
    value === "github" || value === "bedrock" || value === "vertex" ||
    value === "xai" || value === "custom";  // 新增
}
```

### 已有的自定义 handler（无需修改）
- `buildLaunchEnv` 中的 custom profile handler（设置 `__OC_CUSTOM_PROFILE: "1"`）
- 启动验证绕过（检查 `isCustomProfile`）

---

## 2. 更新 patch-custom-profile.js 补丁脚本

### 文件位置
`tools/patch-custom-profile.js`

### 功能
在 `npm update` 后自动重新应用所有 custom profile 相关补丁：
1. 在 `isProviderProfile()` 中添加 `"custom"`
2. 插入 custom profile handler 到 `buildLaunchEnv`
3. 添加 startup validation bypass

### 使用方法
```bash
node tools/patch-custom-profile.js
```

---

## 3. START.bat 配置同步更新

### 修改目的
当用户在 START.bat 中选择任意 Provider 时，同步更新所有相关配置文件。

### 修改的文件
`START.bat`

### 新增函数
`:update_all_config_files` - 统一更新所有配置文件

### 调用点（共9处）
在所有 Provider 保存设置后添加 `call :update_all_config_files`：

| 行号 | Provider |
|------|----------|
| 370 | OpenRouter |
| 454 | NVIDIA NIM |
| 521 | DeepSeek |
| 586 | Gemini |
| 622 | Claude (Anthropic) |
| 642 | Ollama |
| 695 | Custom OpenAI |
| 728 | Custom Anthropic |
| 765 | OpenAI |

### 更新的配置文件

| 文件 | 位置 |
|------|------|
| `ai_settings.env` | `data/ai_settings.env` |
| `.openclaude-profile.json` | `data/openclaude/.openclaude-profile.json` |
| `.claude.json` | `data/openclaude/.claude.json` |

### 不需要更新的文件
- `.openclaude.json` - 仅包含 UI/插件设置
- `settings.json` - 仅包含权限/插件设置

### 各 Provider 配置结构

**OpenRouter / NVIDIA NIM / DeepSeek / OpenAI (OpenAI-compatible)**
```json
{
  "profile": "openai",
  "env": {
    "CLAUDE_CODE_USE_OPENAI": "1",
    "OPENAI_API_KEY": "...",
    "OPENAI_BASE_URL": "...",
    "OPENAI_MODEL": "...",
    "AI_DISPLAY_MODEL": "..."
  }
}
```

**Claude (Anthropic)**
```json
{
  "profile": "anthropic",
  "env": {
    "CLAUDE_CODE_USE_OPENAI": "0",
    "ANTHROPIC_API_KEY": "...",
    "ANTHROPIC_BASE_URL": "https://api.anthropic.com/v1",
    "ANTHROPIC_MODEL": "...",
    "AI_DISPLAY_MODEL": "..."
  }
}
```

**Gemini**
```json
{
  "profile": "gemini",
  "env": {
    "CLAUDE_CODE_USE_GEMINI": "1",
    "GEMINI_API_KEY": "...",
    "GEMINI_MODEL": "...",
    "AI_DISPLAY_MODEL": "..."
  }
}
```

**Ollama**
```json
{
  "profile": "ollama",
  "env": {
    "CLAUDE_CODE_USE_OPENAI": "1",
    "OPENAI_API_KEY": "ollama",
    "OPENAI_BASE_URL": "http://localhost:11434/v1",
    "OPENAI_MODEL": "...",
    "AI_DISPLAY_MODEL": "..."
  }
}
```

**Custom OpenAI-compatible**
```json
{
  "profile": "openai",
  "env": {
    "CLAUDE_CODE_USE_OPENAI": "1",
    "OPENAI_API_KEY": "...",
    "OPENAI_BASE_URL": "...",
    "OPENAI_MODEL": "...",
    "AI_DISPLAY_MODEL": "..."
  }
}
```

**Custom Anthropic-compatible**
```json
{
  "profile": "custom",
  "env": {
    "CLAUDE_CODE_USE_OPENAI": "0",
    "ANTHROPIC_API_KEY": "...",
    "ANTHROPIC_BASE_URL": "...",
    "ANTHROPIC_MODEL": "...",
    "AI_DISPLAY_MODEL": "..."
  }
}
```

---

## 4. 清理调试日志

从 `cli.mjs` 中移除了以下调试语句：
- `[DEBUG] CUSTOM PROFILE HANDLER REACHED`
- `[DEBUG buildStartupEnvFromProfile]`
- `[DEBUG] startupEnv has __OC_CUSTOM_PROFILE...`

---

## 继续修改时的检查清单

1. **验证 MiniMax 可用**：
   ```bash
   NODE_OPTIONS="" \
     ANTHROPIC_API_KEY="your-minimax-api-key" \
     ANTHROPIC_BASE_URL="https://api.minimaxi.com/anthropic" \
     ANTHROPIC_MODEL="MiniMax-M2.7-highspeed" \
     CLAUDE_CONFIG_DIR="data/openclaude" \
     ./engine/node-win-x64/node.exe ./engine/node_modules/@gitlawb/openclaude/bin/openclaude -p "what model are you"
   ```

2. **验证补丁脚本**：
   ```bash
   node tools/patch-custom-profile.js
   ```

3. **START.bat 修改后验证**：
   - 选择各 Provider 后检查 `.openclaude-profile.json` 和 `.claude.json` 是否正确更新
