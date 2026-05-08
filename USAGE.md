# OpenClaude Portable 使用手册

> 基于 [OpenClaude Portable](https://github.com/techjarves/OpenClaude-Portable) 的完整使用指南。
> 本工具将 [OpenClaude](https://github.com/Gitlawb/openclaude)（Claude Code 的开源替代）打包为即插即用的便携版。

---

## 目录

- [一、项目结构](#一项目结构)
- [二、如何启动（U盘 vs 宿主机）](#二如何启动u盘-vs-宿主机)
- [三、环境切换工具（重点）](#三环境切换工具重点)
  - [Windows PowerShell](#windows-powershell)
  - [Windows CMD 命令提示符](#windows-cmd-命令提示符)
  - [Linux / macOS（Bash / Zsh）](#linux--macosbash--zsh)
- [四、安装插件 / Skills / MCP 服务器](#四安装插件--skills--mcp-服务器)
  - [在 U 盘上安装](#在-u-盘上安装)
  - [在本机上安装](#在本机上安装)
  - [快速判断表](#快速判断表)
- [五、配置文件详解](#五配置文件详解)
- [六、便携性隔离原理](#六便携性隔离原理)
- [七、常见问题](#七常见问题)

---

## 一、项目结构

```
OpenClaude-Portable-main/
│
├── START.bat                        [Windows 启动入口]
├── start.sh                         [Linux/macOS 启动入口]
├── USAGE.md                         ← 本文件
│
├── engine/                          [引擎目录——启动时的 CWD]
│   ├── package.json
│   ├── node-win-x64/                [捆绑的 Node.js 22.x]
│   ├── git-win-x64/                 [捆绑的 GitPortable 2.54]
│   ├── node_modules/@gitlawb/       [OpenClaude 引擎本体]
│   └── .openclaude/
│       ├── settings.json            [项目级设置——用户可编辑]
│       └── settings.local.json      [本地覆盖设置——用户可编辑]
│
├── data/                            [所有持久化数据]
│   ├── ai_settings.env              [API 提供商配置（用户编辑此处换模型）]
│   ├── config/                      [XDG 配置（Linux）]
│   ├── cache/                       [XDG 缓存（Linux）]
│   ├── app_data/                    [Windows 本地数据 + 引擎缓存日志]
│   │   └── claude-cli/Cache/        ← 原先在宿主机 %LOCALAPPDATA%
│   ├── npm-cache/                   [npm 安装缓存]
│   └── openclaude/                  [CLAUDE_CONFIG_DIR——主配置目录]
│       ├── .claude.json             [★ 核心配置，含 env 块]
│       ├── settings.json            [用户级设置]
│       ├── plugins/                 [已安装的插件]
│       ├── skills/                  [自定义 Skills]
│       ├── commands/                [自定义命令]
│       ├── agents/                  [自定义 Agent]
│       ├── workflows/               [自定义 Workflows]
│       └── memory/                  [记忆持久化]
│
└── tools/
    ├── enter-portable.bat           [★ Windows CMD 环境切换]
    ├── enter-portable.ps1           [★ Windows PowerShell 环境切换]
    ├── enter-portable.sh            [★ Linux/macOS 环境切换]
    ├── Change_Provider.bat          [更换 AI 提供商（Windows）]
    ├── change_provider.sh           [更换 AI 提供商（Linux/macOS）]
    ├── Open_Dashboard.bat           [打开 Web 仪表盘]
    ├── open_dashboard.sh
    ├── local-proxy.js               [Ollama 本地加速代理]
    ├── setup_local_models.ps1       [下载本地 Ollama 模型]
    └── setup_local_models.sh
```

---

## 二、如何启动（U盘 vs 宿主机）

### ✅ 从 U 盘启动（推荐）

双击 U 盘根目录的 **`START.bat`**（Windows）或运行 **`./start.sh`**（Linux/macOS）。

脚本会自动：
1. 设置 `CLAUDE_CONFIG_DIR` → `data/openclaude/`
2. 设置 `LOCALAPPDATA` → `data/app_data/`
3. 设置所有环境变量指向 U 盘
4. 加载 `ai_settings.env` 中的 API 配置
5. 启动 OpenClaude

启动后，终端提示符会变为 `USB-OC>`，表明当前在 U 盘环境。

### ❌ 错误的启动方式

```powershell
# 在普通 PowerShell 中直接运行（没有设置环境变量）
cd E:\OpenClaude-Portable-main\engine
node .\node_modules\@gitlawb\openclaude\bin\openclaude

# 这样启动的 OpenClaude 会使用宿主机的 ~/.openclaude/ 配置！
```

---

## 三、环境切换工具（重点）

如果你已经打开了一个终端（PowerShell / CMD / Bash），想在这个终端里**临时**切换到 U 盘环境执行命令，用 `enter-portable` 脚本。

### Windows PowerShell

```powershell
# ─── 方法 A：进入 U 盘环境子进程，逐条输命令 ───
.\tools\enter-portable.ps1

# 运行后提示符变成 USB-OC>，所有命令都指向 U 盘
USB-OC> openclaude /plugins
USB-OC> openclaude /skills
# 输 exit 返回宿主机环境
USB-OC> exit
PS C:\>   # 回到宿主机


# ─── 方法 B：在 U 盘环境执行单条命令，自动退出 ───
.\tools\enter-portable.ps1 openclaude /plugins
.\tools\enter-portable.ps1 npm install -g some-tool
.\tools\enter-portable.ps1 npx @gitlawb/openclaude --version


# ─── 方法 C：不经过脚本，手动设环境变量 ───
$env:CLAUDE_CONFIG_DIR = "E:\OpenClaude-Portable-main\data\openclaude"
$env:LOCALAPPDATA      = "E:\OpenClaude-Portable-main\data\app_data"
openclaude /plugins     # ← 这条命令影响 U 盘
```

### Windows CMD 命令提示符

```cmd
:: 进入 U 盘环境
C:\> tools\enter-portable.bat
USB-OC>   :: 提示符变了

:: 在 U 盘环境执行一条命令后退出
C:\> tools\enter-portable.bat openclaude /plugins
```

### Linux / macOS（Bash / Zsh）

```bash
# ─── 方法 A：source 进入子进程 ───
source tools/enter-portable.sh
USB-OC>   # 提示符变了
USB-OC> openclaude /plugins
USB-OC> exit  # 回到宿主机


# ─── 方法 B：直接执行单条命令 ───
./tools/enter-portable.sh openclaude /plugins
./tools/enter-portable.sh npm install -g some-tool


# ─── 方法 C：手动设置（不进入子进程） ───
export CLAUDE_CONFIG_DIR="/Volumes/USB/OpenClaude-Portable-main/data/openclaude"
export XDG_CACHE_HOME="/Volumes/USB/OpenClaude-Portable-main/data/cache"
openclaude /plugins
```

---

## 四、安装插件 / Skills / MCP 服务器

### 在 U 盘上安装

**只有一个原则：从 U 盘的 START.bat 启动 OpenClaude，所有命令都自动装到 U 盘。**

```text
/plugin install <插件名>     → 装到 data/openclaude/plugins/
/skills                       → 管理 skills
/create-skill                  → 创建 skill
/config mcp add <name> <cmd>  → MCP 配置写到 data/openclaude/.claude.json
/plugins                       → 查看已安装的插件
```

### 在本机上安装

如果你打开的是**普通终端（没设环境变量）**，所有命令默认影响宿主机上的 OpenClaude。

```text
# 在普通终端里
openclaude /plugin install xxx   → 装到宿主机的 ~/.openclaude/plugins/
```

### 快速判断表

| 你的操作 | 影响哪个 OpenClaude | 依据 |
|---------|-------------------|------|
| 双击 `START.bat` 启动 | ✅ **U盘** | 脚本设了 `CLAUDE_CONFIG_DIR` |
| `.\tools\enter-portable.ps1` 后输命令 | ✅ **U盘** | 脚本设了环境变量 |
| `enter-portable.ps1 openclaude /xxx` | ✅ **U盘** | 在便携上下文执行 |
| 普通 PowerShell 输 `openclaude` | ❌ **本机** | 默认 `~/.openclaude/` |
| 普通终端 `cd` 到 U 盘目录再运行 | ❌ **本机** | `cd` 不改环境变量 |
| 直接双击引擎目录的 `openclaude.exe` | ❌ **本机** | `CLAUDE_CONFIG_DIR` 不是 U 盘路径 |

---

## 五、配置文件详解

### `data/openclaude/.claude.json`（★ 核心配置文件）

OpenClaude 从这个文件读取 `env` 块并注入到进程环境变量。

```json
{
  "hasCompletedOnboarding": true,
  "env": {
    "CLAUDE_CODE_USE_OPENAI": "1",
    "OPENAI_API_KEY": "sk-your-key",
    "OPENAI_BASE_URL": "https://api.deepseek.com",
    "OPENAI_MODEL": "deepseek-v4-flash",
    "AI_DISPLAY_MODEL": "deepseek-v4-flash",
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  },
  "numStartups": 11,
  "userID": "xxxxxxxxxx",
  "migrationVersion": 11,
  "showSpinnerTree": false
}
```

**用户编辑此文件的 `env` 块即可切换 AI 提供商**，不需要修改脚本。

### `data/ai_settings.env`（API 提供商配置）

START.bat 读取此文件并导出为环境变量。格式为 `KEY=VALUE`。

```
AI_PROVIDER=openai
CLAUDE_CODE_USE_OPENAI=1
OPENAI_API_KEY=sk-xxxxxxxxx
OPENAI_BASE_URL=https://api.deepseek.com
OPENAI_MODEL=deepseek-v4-flash
AI_DISPLAY_MODEL=deepseek-v4-flash
```

可通过运行 `tools\Change_Provider.bat`（Windows）或 `tools\change_provider.sh`（Linux）交互式修改。

### `engine/.openclaude/settings.json`（项目级设置）

```json
{
  "permissions": {
    "allow": ["Read", "Edit", "Write", "Glob", "Grep"],
    "deny": [],
    "ask": []
  },
  "model": "sonnet",
  "autoUpdaterDisabled": true,
  "disableNonEssentialTraffic": true
}
```

控制 OpenClaude 在 `engine/` 目录下运行时的权限和默认行为。

### `engine/.openclaude/settings.local.json`（本地覆盖，优先级更高）

```json
{
  "permissions": {
    "allow": ["Bash(*)"],
    "deny": ["Bash(rm -rf /:*)"],
    "ask": ["Write(C:\\*)", "Write(/etc/*)"]
  }
}
```

用于本地覆盖，比 `settings.json` 优先级高。适合放危险操作的确认规则。

### `data/openclaude/settings.json`（用户级设置）

```json
{
  "permissions": {
    "allow": ["Read", "Edit", "Write", "Glob", "Grep"],
    "deny": [],
    "ask": []
  }
}
```

全局作用于所有项目的基础权限设置。

---

## 六、便携性隔离原理

### 环境变量重定向体系

| 环境变量 | 默认路径（宿主机） | U 盘重定向 |
|---------|------------------|-----------|
| `CLAUDE_CONFIG_DIR` | `%USERPROFILE%\.openclaude\` | `data\openclaude\` |
| `LOCALAPPDATA` | `%USERPROFILE%\AppData\Local\` | `data\app_data\` |
| `XDG_CONFIG_HOME` | `~/.config/` | `data/config/` |
| `XDG_DATA_HOME` | `~/.local/share/` | `data/app_data/` |
| `XDG_CACHE_HOME` | `~/.cache/` | `data/cache/` |
| `npm_config_cache` | `~/.npm/` | `data/npm-cache/` |

### 数据流（从 U 盘启动时）

```
START.bat
  ├── 设置 CLAUDE_CONFIG_DIR → data/openclaude/
  ├── 设置 LOCALAPPDATA → data/app_data/
  ├── 设置 npm_config_cache → data/npm-cache/
  ├── 加载 ai_settings.env → 导出为环境变量
  └── 启动 OpenClaude（CWD = engine/）
      ├── 读取 data/openclaude/.claude.json → 应用 env 块
      ├── 读取 engine/.openclaude/settings.json → 项目权限
      ├── 读取 engine/.openclaude/settings.local.json → 本地覆盖
      ├── 读取 data/openclaude/settings.json → 用户级设置
      │
      ├── 安装插件 → data/openclaude/plugins/
      ├── 安装 skills → data/openclaude/skills/
      ├── 安装命令 → data/openclaude/commands/
      ├── 安装 agent → data/openclaude/agents/
      ├── MCP 配置 → data/openclaude/.claude.json
      ├── 记忆持久化 → data/openclaude/memory/
      └── 引擎缓存 → data/app_data/claude-cli/Cache/
```

### 宿主机残留

拔掉 U 盘后，宿主机上只有以下残留（都是无害的临时文件）：

| 残留位置 | 内容 | 清理方式 |
|---------|------|---------|
| `%LOCALAPPDATA%\claude-cli\Cache\` | 引擎缓存日志 | 手动删除，影响：无 |
| `%APPDATA%\npm-cache\` | npm 包缓存 | 不影响任何功能 |
| `%USERPROFILE%\.gitconfig` | Git 配置（仅当运行 git 时） | 这是你自己的 git 配置，本来就存在 |

**总结：所有配置、数据、插件、记忆都在 U 盘上。拔掉 U 盘，宿主机跟什么都没发生过一样。**

---

## 七、常见问题

### Q1: 我换了一台电脑插 U 盘，需要重新配置吗？

**不需要。** 所有配置都在 `data/` 目录里，插到任何电脑上双击 `START.bat` 就能用。包括已安装的插件、skills、记忆全部保留。

### Q2: 我想在 U 盘上用不同的 AI 提供商，怎么改？

两种方式：
- **交互式**：运行 `tools\Change_Provider.bat`（Windows）或 `tools\change_provider.sh`（Linux），菜单选择
- **手动编辑**：直接修改 `data/ai_settings.env`，或修改 `data/openclaude/.claude.json` 的 `env` 块

### Q3: 让我本机和 U 盘上装的是不同提供商，会冲突吗？

**不会。** 本机和 U 盘各自有各自的 `CLAUDE_CONFIG_DIR`，完全不互通。本机读 `~/.openclaude/`，U 盘读 `data/openclaude/`。

### Q4: 更新引擎会影响已安装的插件吗？

更新引擎（通过 `START.bat` 自动或手动 `npm update`）只更新 `engine/node_modules/@gitlawb/openclaude/`，不会动 `data/openclaude/plugins/`。**插件和 Skills 不受影响。**

### Q5: 可以把 U 盘上的配置复制到本机吗？

可以。把 `data/openclaude/.claude.json` 复制到本机的 `%USERPROFILE%\.openclaude\.claude.json`，再把 `data/openclaude/plugins/` 复制过去就行。反之亦可从本机复制到 U 盘。

### Q6: 如何确认当前在哪个环境？

```powershell
# 查看 CLAUDE_CONFIG_DIR 指向哪
echo $env:CLAUDE_CONFIG_DIR

# 如果输出包含你的 U 盘路径 → 在 U 盘环境
# 如果输出是 C:\Users\...\.openclaude → 在本机环境
# 如果没有输出 → 在本机环境（用的默认路径）
```

### Q7: PowerShell 提示 "无法加载文件...因为在此系统上禁止执行脚本"？

这是 PowerShell 执行策略限制。两种解决方法：

```powershell
# 方法 A：临时解除限制（仅当前会话有效）
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\tools\enter-portable.ps1

# 方法 B：用 CMD 版代替
tools\enter-portable.bat
```

### Q8: npm 全局安装（`npm install -g`）会装到哪里？

默认装到宿主机的 npm 全局目录。启动脚本设置了 `npm_config_cache` 只是把**缓存**重定向到 U 盘。如果某个插件需要 `npm install -g`，用 enter-portable 脚本设置完整环境再执行：

```powershell
.\tools\enter-portable.ps1 npm install -g some-tool
```

### Q9: SSH 密钥、AWS 凭证等个人认证会被 U 盘读取吗？

- **SSH**：OpenClaude 使用宿主机的 `~/.ssh/` 进行 git 操作（如 clone 私有仓库）——这是**有意的**，你想用自己的 SSH 密钥来签名 commit
- **AWS**：只读 `~/.aws/`，不会写入——你用 U 盘跑代码时可以访问自己的云资源
- **Git config**：读宿主机的 `~/.gitconfig`（你设的名字和邮箱），写 commit 时用

这些都是安全且预期的行为。

### Q10: 如何在 U 盘上配置 MCP 服务器？

在 U 盘的 OpenClaude 中运行：

```
/config mcp add <服务器名> <命令> [参数...]
```

或直接在 `data/openclaude/.claude.json` 的 `projects` 下添加 mcpServers 配置。MCP 配置存储在 U 盘上，换电脑不会丢失。
