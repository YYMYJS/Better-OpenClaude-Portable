# OpenClaude Portable - 便携式 AI 编程助手

> **U盘上的 AI 编程助手 — 插入即用，无痕运行，不留任何数据在宿主机。**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey.svg)]()

---

## 功能特性

| 特性 | 说明 |
|------|------|
| **9 大 AI 提供商** | OpenRouter · NVIDIA NIM · DeepSeek · Gemini · Claude (Anthropic) · OpenAI · Ollama (离线) · Custom OpenAI · Custom Anthropic |
| **零痕迹** | 所有数据、密钥、日志都保存在 `data/` 目录，绝不触碰宿主机 |
| **配置同步** | 选择任意 Provider 时自动同步更新所有配置文件 |
| **Custom Provider** | 支持任意 OpenAI/Anthropic 兼容 API，包括 MiniMax 等国内模型 |
| **本地加速代理** | 为 Ollama 裁剪系统提示词，CPU 环境下首token延迟从 60-120s 降至 5-20s |
| **自动更新** | 每天检查一次引擎更新（重复启动跳过网络检查） |
| **会话恢复** | 使用 `RESUME.bat <session-id>` 恢复中断的会话 |
| **Web 仪表盘** | 浏览器内的 ChatGPT 风格界面，带 Agent 模式、工具卡片和思维可视化 |
| **Limitless 模式** | 完全自治模式，无需批准即可执行所有操作 |
| **跨平台** | Windows / Linux / macOS 共用同一份 `data/` 文件夹 |

---

## 快速开始

### Windows

```cmd
# 方法一：双击 START.bat（推荐）
.\START.bat

# 方法二：快速启动（进入便携环境）
.\USB-OC.bat
```

### Linux / macOS

```bash
chmod +x start.sh
./start.sh
```

> **首次启动需要网络连接。** 之后只有 API 调用需要网络（使用 Ollama 离线模式则完全不需要网络）。

---

## 支持的 AI 提供商

| 提供商 | 费用 | API Key 获取 |
|--------|------|-------------|
| **OpenRouter** | 免费+付费模型 | [openrouter.ai](https://openrouter.ai) |
| **NVIDIA NIM** | 每月 1000 免费额度 | [build.nvidia.com](https://build.nvidia.com) |
| **DeepSeek** | 付费 API | [platform.deepseek.com](https://platform.deepseek.com) |
| **Google Gemini** | 有免费额度 | [aistudio.google.com](https://aistudio.google.com) |
| **Anthropic Claude** | 付费 | [console.anthropic.com](https://console.anthropic.com) |
| **OpenAI** | 付费 | [platform.openai.com](https://platform.openai.com) |
| **Ollama** | 免费，完全离线 | [ollama.com](https://ollama.com) |
| **Custom OpenAI** | 自定义 | 任意 OpenAI 兼容 API |
| **Custom Anthropic** | 自定义 | 任意 Anthropic 兼容 API |

### Custom Provider 使用示例

**MiniMax API 配置：**
```
API Base URL: https://api.minimaxi.com/anthropic
API Key: sk-cp-xxxxx
Model: MiniMax-M2.7-highspeed
```

**其他支持的 Custom API：**
- Groq
- LM Studio
- Jan
- LocalAI
- 以及任何 OpenAI/Anthropic 兼容 API

---

## 项目结构

```
OpenClaude-Portable/
│
├── START.bat                      # Windows 启动入口（自动下载 Node.js 和引擎）
├── USB-OC.bat                    # 快速启动（进入便携环境）
├── start.sh                      # Linux/macOS 启动入口
│
├── engine/                       # 引擎目录（启动时的 CWD）
│   ├── node-win-x64/            # 捆绑的 Node.js 22.x
│   ├── git-win-x64/             # 捆绑的 GitPortable 2.54
│   ├── node_modules/@gitlawb/   # OpenClaude 引擎本体
│   │   └── dist/cli.mjs         # 主引擎文件
│   └── package.json             # postinstall 钩子自动应用补丁
│
├── data/                        # 所有持久化数据（跨平台共享）
│   ├── ai_settings.env          # 批处理配置文件（START.bat 使用）
│   ├── openclaude/             # CLAUDE_CONFIG_DIR 目录
│   │   ├── .claude.json         # ★ 核心配置（含 env 块）
│   │   ├── .openclaude-profile.json  # Provider Profile 配置
│   │   ├── .openclaude.json     # UI/插件设置
│   │   ├── settings.json        # 用户级权限设置
│   │   ├── plugins/            # 已安装插件
│   │   ├── skills/             # 自定义 Skills
│   │   ├── memory/             # 记忆持久化
│   │   └── sessions/           # 会话历史
│   ├── config/                 # XDG 配置（Linux）
│   ├── cache/                  # XDG 缓存
│   ├── app_data/              # Windows 本地数据
│   └── npm-cache/             # npm 缓存
│
├── tools/                       # 辅助脚本
│   ├── enter-portable.ps1      # ★ PowerShell 环境切换（便携模式）
│   ├── enter-portable.bat      # CMD 环境切换
│   ├── enter-portable.sh       # Bash 环境切换
│   ├── Change_Provider.bat      # 更换 AI 提供商（Windows）
│   ├── change_provider.sh       # 更换 AI 提供商（Linux/macOS）
│   ├── Open_Dashboard.bat      # 启动 Web 仪表盘
│   ├── patch-custom-profile.js  # Custom Provider 补丁持久化
│   └── setup_local_models.ps1  # Ollama 模型下载
│
└── dashboard/                   # Web 仪表盘 UI
    ├── server.mjs              # 仪表盘服务器
    └── index.html              # 聊天界面
```

---

## 主菜单选项

运行 `START.bat` 后显示：

```
1) Launch AI       — 正常模式（写入文件或运行命令前询问）
2) Limitless Mode  — 自动执行模式（无需批准）
3) Open Dashboard  — Web UI (http://localhost:3000)
4) Change Provider — 更换 AI 提供商或 API Key
5) Setup Offline   — 下载本地 Ollama 模型
```

10 秒无操作自动选择 **正常模式**。

---

## 环境变量重定向

| 环境变量 | 宿主机默认 | 便携模式重定向 |
|---------|-----------|--------------|
| `CLAUDE_CONFIG_DIR` | `%USERPROFILE%\.openclaude\` | `data\openclaude\` |
| `LOCALAPPDATA` | `%USERPROFILE%\AppData\Local\` | `data\app_data\` |
| `XDG_CONFIG_HOME` | `~/.config/` | `data/config/` |
| `XDG_DATA_HOME` | `~/.local/share/` | `data/app_data/` |
| `npm_config_cache` | `~/.npm/` | `data/npm-cache/` |

---

## 配置文件说明

### `data/openclaude/.openclaude-profile.json`

Provider Profile 配置文件。选择 Provider 时由 START.bat 自动更新。

```json
{
  "profile": "custom",
  "env": {
    "CLAUDE_CODE_USE_OPENAI": "0",
    "ANTHROPIC_API_KEY": "sk-cp-xxxxx",
    "ANTHROPIC_BASE_URL": "https://api.minimaxi.com/anthropic",
    "ANTHROPIC_MODEL": "MiniMax-M2.7-highspeed"
  }
}
```

### `data/openclaude/.claude.json`

核心配置文件。OpenClaude 读取 `env` 块并注入到进程环境变量。

```json
{
  "env": {
    "CLAUDE_CODE_USE_OPENAI": "0",
    "ANTHROPIC_API_KEY": "sk-cp-xxxxx",
    "ANTHROPIC_BASE_URL": "https://api.minimaxi.com/anthropic",
    "ANTHROPIC_MODEL": "MiniMax-M2.7-highspeed",
    "AI_DISPLAY_MODEL": "MiniMax-M2.7-highspeed",
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  }
}
```

### `data/ai_settings.env`

批处理配置文件。START.bat 读取并导出为环境变量。

```
AI_PROVIDER=custom
CLAUDE_CODE_USE_OPENAI=0
ANTHROPIC_API_KEY=sk-cp-xxxxx
ANTHROPIC_BASE_URL=https://api.minimaxi.com/anthropic
ANTHROPIC_MODEL=MiniMax-M2.7-highspeed
AI_DISPLAY_MODEL=MiniMax-M2.7-highspeed
```

---

## Custom Provider 补丁说明

OpenClaude 原生不支持 `custom` profile，已通过补丁修复：

1. **`isProviderProfile()`** — 添加 `"custom"` 到有效 provider 列表
2. **`buildLaunchEnv()`** — 添加 custom profile handler，支持 `ANTHROPIC_API_KEY` + `ANTHROPIC_BASE_URL`
3. **启动验证绕过** — 检查 `__OC_CUSTOM_PROFILE` 标记

补丁由 `tools/patch-custom-profile.js` 管理，在 `npm update` 后自动重新应用。

---

## 安全与隐私

- **零痕迹** — 所有配置、数据、插件、记忆都保存在 U 盘
- **不发送遥测** — 只向您选择的 AI 提供商发送请求
- **API Key 安全** — 密钥仅存储在 `data/` 目录
- **批准模式** — 正常模式下，agent 在写入文件或运行命令前会询问

---

## 故障排除

| 问题 | 解决方法 |
|------|---------|
| Custom Provider 401 错误 | 运行 `node tools/patch-custom-profile.js` 重新应用补丁 |
| Node.js 未找到 | 运行 `START.bat`，它会自动下载 |
| API Key 被拒绝 | 验证密钥，重新运行选项 4 更新 |
| 端口 3000 被占用 | 仪表盘已在运行，访问 http://localhost:3000 |
| Ollama 响应很慢 | 使用更小的模型（如 `gemma3:1b`）|

---

## 系统要求

| 平台 | 要求 |
|------|------|
| **Windows** | Windows 10 或更高版本 |
| **Linux** | `curl`（大多数发行版已预装）|
| **macOS** | `curl`（已预装）|

**磁盘空间：** Node.js + 引擎约 150 MB。本地 Ollama 模型需要额外 800 MB - 8 GB。

---

## License

MIT — 可以自由使用、修改和分发。
