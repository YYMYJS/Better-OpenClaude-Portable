# OpenClaude Portable - 便携式 AI 编程助手

> **U盘上的 AI 编程助手 — 插入即用，无痕运行，不留任何数据在宿主机。**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey.svg)]()

---

## 目录

- [特性](#特性)
- [快速开始](#快速开始)
- [支持的 AI 提供商](#支持的-ai-提供商)
- [项目结构](#项目结构)
- [配置说明](#配置说明)
- [常见问题](#常见问题)

---

## 特性

| 特性 | 说明 |
|------|------|
| **9 大 AI 提供商** | OpenRouter · NVIDIA NIM · DeepSeek · Gemini · Claude · OpenAI · Ollama · Custom OpenAI · Custom Anthropic |
| **零痕迹** | 所有数据、密钥、日志都保存在 `data/` 目录，绝不触碰宿主机 |
| **配置同步** | 选择任意 Provider 时自动同步更新所有配置文件 |
| **Custom Provider** | 支持任意 OpenAI/Anthropic 兼容 API（MiniMax、Groq、LM Studio 等） |
| **本地加速代理** | 为 Ollama 裁剪系统提示词，CPU 环境下首 token 延迟大幅降低 |
| **自动更新** | 每天检查一次引擎更新 |
| **会话恢复** | 使用 `RESUME.bat <session-id>` 恢复中断的会话 |
| **Web 仪表盘** | 浏览器内的 ChatGPT 风格界面 |
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

| 提供商 | 费用 | API Key 获取地址 |
|--------|------|-----------------|
| **OpenRouter** | 免费+付费模型 | [openrouter.ai](https://openrouter.ai) |
| **NVIDIA NIM** | 每月 1000 免费额度 | [build.nvidia.com](https://build.nvidia.com) |
| **DeepSeek** | 付费 API | [platform.deepseek.com](https://platform.deepseek.com) |
| **Google Gemini** | 有免费额度 | [aistudio.google.com](https://aistudio.google.com) |
| **Anthropic Claude** | 付费 | [console.anthropic.com](https://console.anthropic.com) |
| **OpenAI** | 付费 | [platform.openai.com](https://platform.openai.com) |
| **Ollama** | 免费，完全离线 | [ollama.com](https://ollama.com) |
| **Custom OpenAI** | 自定义 | 任意 OpenAI 兼容 API |
| **Custom Anthropic** | 自定义 | 任意 Anthropic 兼容 API |

### Custom Provider 配置示例

#### MiniMax API
```
API Type: Anthropic-compatible
API Base URL: https://api.minimaxi.com/anthropic
API Key: your-minimax-api-key
Model: MiniMax-M2.7-highspeed
```

#### 其他支持的 Custom API
- Groq
- LM Studio
- Jan
- LocalAI
- 以及任何 OpenAI/Anthropic 兼容 API

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

## 项目结构

```
OpenClaude-Portable/
│
├── START.bat                      # Windows 启动入口
├── USB-OC.bat                    # 快速启动（进入便携环境）
├── start.sh                      # Linux/macOS 启动入口
│
├── engine/                       # 引擎目录
│   ├── node-win-x64/            # 捆绑的 Node.js
│   ├── git-win-x64/             # 捆绑的 Git
│   └── node_modules/@gitlawb/   # OpenClaude 引擎
│
├── data/                        # 所有持久化数据
│   ├── ai_settings.env          # 批处理配置文件
│   ├── openclaude/             # 主配置目录
│   │   ├── .claude.json         # 核心配置
│   │   ├── .openclaude-profile.json  # Provider Profile
│   │   ├── settings.json        # 用户权限设置
│   │   ├── plugins/            # 已安装插件
│   │   └── sessions/          # 会话历史
│   ├── bin/                   # 便携工具（uv 等）
│   └── npm-cache/             # npm 缓存
│
├── tools/                       # 辅助脚本
│   ├── enter-portable.ps1      # PowerShell 环境切换
│   ├── Change_Provider.bat      # 更换 AI 提供商
│   └── patch-custom-profile.js  # Custom Provider 补丁
│
└── dashboard/                   # Web 仪表盘
```

---

## 配置说明

### 首次配置

首次运行 `START.bat` 时会引导你选择 AI 提供商并输入 API Key。

### 手动配置

配置文件位于 `data/openclaude/` 目录：

| 文件 | 说明 |
|------|------|
| `.claude.json` | 核心配置，含 API keys 和环境变量 |
| `.openclaude-profile.json` | Provider profile 配置 |
| `settings.json` | 用户权限设置 |

### 环境变量

| 变量 | 说明 |
|------|------|
| `CLAUDE_CONFIG_DIR` | 配置目录（默认 `data/openclaude/`） |
| `LOCALAPPDATA` | 本地数据目录 |
| `XDG_CONFIG_HOME` | XDG 配置目录 |
| `npm_config_cache` | npm 缓存目录 |

---

## Custom Provider 补丁

OpenClaude 原生支持有限，本项目已通过补丁添加 Custom Provider 支持：

- **`isProviderProfile()`** — 支持 "custom" profile 类型
- **`buildLaunchEnv()`** — 处理自定义 API 端点和密钥
- **启动验证绕过** — 允许 custom profile 通过验证

补丁由 `tools/patch-custom-profile.js` 管理，`npm update` 后自动重新应用。

---

## 安全与隐私

- **零痕迹** — 所有配置、数据、插件、记忆都保存在 U 盘
- **不发送遥测** — 只向您选择的 AI 提供商发送请求
- **API Key 安全** — 密钥仅存储在 `data/` 目录
- **批准模式** — 正常模式下，agent 在执行危险操作前会询问

---

## 常见问题

### Q1: 换电脑需要重新配置吗？

**不需要。** 所有配置都在 `data/` 目录，插到任何电脑上双击 `START.bat` 就能用。

### Q2: 如何更换 AI 提供商？

运行 `START.bat` 选择 **4) Change Provider**，或直接修改 `data/ai_settings.env`。

### Q3: 支持哪些本地模型？

推荐使用 **Ollama**，支持 llama、qwen、phi 等主流开源模型。

### Q4: Custom Provider 报 401 错误？

运行以下命令重新应用补丁：
```bash
node tools/patch-custom-profile.js
```

### Q5: npm update 后 custom profile 不工作？

补丁会在 `npm update` 后自动重新应用。如果没有，运行：
```bash
node tools/patch-custom-profile.js
```

### Q6: 如何确认当前在便携环境？

终端提示符会显示 `USB-OC>`，或运行：
```powershell
$env:CLAUDE_CONFIG_DIR
```
如果包含你的 U 盘路径，说明在便携环境。

---

## 系统要求

| 平台 | 要求 |
|------|------|
| **Windows** | Windows 10 或更高版本 |
| **Linux** | `curl`（大多数发行版已预装）|
| **macOS** | `curl`（已预装）|

**磁盘空间：** Node.js + 引擎约 150 MB。本地 Ollama 模型需要额外 800 MB - 8 GB。

---

## 故障排除

| 问题 | 解决方法 |
|------|---------|
| Custom Provider 401 错误 | 运行 `node tools/patch-custom-profile.js` |
| Node.js 未找到 | 运行 `START.bat`，它会自动下载 |
| API Key 被拒绝 | 验证密钥，重新运行选项 4 更新 |
| 端口 30010 被占用 | 仪表盘已在运行，访问 http://localhost:30010 |
| Ollama 响应很慢 | 使用更小的模型（如 `gemma3:1b`） |

---

## License

MIT — 可以自由使用、修改和分发。

---

## 致谢

基于 [OpenClaude](https://github.com/gitlawb/openclaude) 开发。
