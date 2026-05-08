---
name: portable-env-full
description: 便携式 OpenClaude 环境的完整配置记忆 — 插件安装、跨电脑生效、CLAUDE_PLUGIN_ROOT
type: project
---

## 便携式环境完整记忆（2026-05-08）

### Resume Protocol
只要用户提到「便携式环境」「U盘」「OpenClaude Portable」，立即读取本文件。

### ⚠️ Memory 文件使用说明
- `.claude-memory/` 目录已纳入 git 追踪
- **其他用户克隆仓库后**：将 `.claude-memory/` 下的所有文件复制到自己的 `data/openclaude/projects/<项目名>/memory/` 目录下，Claude Code 启动时会自动加载

### 核心路径
- 便携项目根目录：`./`（START.bat 所在目录）
- 配置目录：`./data/openclaude/`
- 插件目录：`./data/openclaude/plugins/`
- settings.json：`./data/openclaude/settings.json`
- installed_plugins.json：`./data/openclaude/plugins/installed_plugins.json`
- known_marketplaces.json：`./data/openclaude/plugins/known_marketplaces.json`

### 安装插件/Skills 到便携环境的关键环境变量

**必须设置这两个环境变量，否则插件会安装到宿主机：**

```cmd
set "CLAUDE_CONFIG_DIR=.\data\openclaude"
set "CLAUDE_PLUGIN_ROOT=.\data\openclaude\plugins"
```

**PowerShell：**
```powershell
$env:CLAUDE_CONFIG_DIR = ".\data\openclaude"
$env:CLAUDE_PLUGIN_ROOT = ".\data\openclaude\plugins"
```

**Bash/Linux：**
```bash
export CLAUDE_CONFIG_DIR="./data/openclaude"
export CLAUDE_PLUGIN_ROOT="./data/openclaude/plugins"
```

### 启动脚本已配置 CLAUDE_PLUGIN_ROOT
以下文件已在 `postinstall`/`START.bat`/`start.sh`/`enter-portable.*` 中设置 CLAUDE_PLUGIN_ROOT：
- `START.bat`
- `start.sh`
- `tools/enter-portable.ps1`
- `tools/enter-portable.bat`
- `tools/enter-portable.sh`

### 插件安装后必须手动添加的两件事

**1. 安装完成后，在 `settings.json` 的 `enabledPlugins` 中添加插件：**
```json
"插件名@marketplace名": true
```

**2. 在 `installed_plugins.json` 中添加插件记录：**
```json
"插件名@marketplace名": [
  {
    "scope": "user",
    "installPath": "插件目录相对路径",
    "version": "x.x.x",
    "installedAt": "2026-05-08T00:00:00.000Z",
    "lastUpdated": "2026-05-08T00:00:00.000Z",
    "gitCommitSha": ""
  }
]
```

### 让插件在跨电脑上生效
让插件在任意电脑的 U 盘上都能正常加载：

1. **hooks 中使用 `${CLAUDE_PLUGIN_ROOT}` 而非绝对路径**
2. **启动脚本必须设置 `CLAUDE_PLUGIN_ROOT`**（START.bat/start.sh/enter-portable.* 已添加）
3. **`settings.json` 中的 `language: "Chinese"` 等设置** 不依赖路径，任何电脑都有效

### claude-code-zh-cn 插件特殊说明
- 插件位置：`data/openclaude/plugins/cache/claude-code-zh-cn/claude-code-zh-cn/2.4.4/`
- hooks 使用 `${CLAUDE_PLUGIN_ROOT}` 引用
- 设置已写入 `settings.json`：`language: "Chinese"`、`spinnerVerbs`、`spinnerTipsOverride`
- 插件名格式：`claude-code-zh-cn@claude-code-zh-cn`

### How to apply
当用户提到「便携式环境」时，立即读取本文件，然后：
1. 先设置 CLAUDE_CONFIG_DIR 和 CLAUDE_PLUGIN_ROOT 环境变量
2. 执行插件安装命令
3. 手动添加到 enabledPlugins 和 installed_plugins.json
4. 确认 settings.json 中有对应配置
