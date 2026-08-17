# cs - Claude Code Provider Switcher

简化 Claude Code 多 Provider 切换的工具。零依赖，支持目录级自动切换。

## 安装

一条命令安装（自动识别 Zsh / Bash / Fish，写入对应的 shell 配置文件）：

```bash
curl -fsSL https://raw.githubusercontent.com/leebo/cs/main/install.sh | bash
```

装完按提示 `source` 一下让当前终端立即生效（或直接重开终端）：

```bash
source ~/.zshrc   # Bash 用户是 ~/.bashrc，Fish 用户是 ~/.config/fish/config.fish
```

安装脚本做了什么：
- 把 `bin/`、`lib/`、`providers.json` 部署到 `~/.cs/`
- 按你当前登录 shell（`$SHELL`）自动把 `source ~/.cs/lib/cs-core(.fish)` 写进对应 rc 文件；已经写过就跳过，重复运行安装脚本不会重复追加
- 把仓库自带的 `providers.json` 拷贝一份到 `~/.cs/providers_catalog.json` 作为本地缓存（24 小时内 `cs -a` 不会重新联网拉取，`cs -u` 会强制刷新）
- provider 密钥文件（`~/.cs/providers/*.env`）默认 `chmod 600`，只有当前系统用户能读

## 快速开始

```bash
# 列出所有 provider
cs -l

# 切换到指定 provider
cs zhipu

# 查看当前 provider
cs -c

# 编辑 provider 配置
cs -e zhipu

# 交互式添加 provider（选择厂商、模型、输入 Key）
cs -a

# 删除 provider
cs -d my-custom

# 还原官方 Claude Code 默认配置（清掉当前 shell 的 provider 变量）
cs -r
```

## 目录级自动切换

在项目根目录创建 `.cs` 文件：

```bash
echo "zhipu" > .cs
```

进入目录时自动加载对应 provider：

```bash
cd my-project
# 输出: 🤖 Provider: zhipu
```

## Provider 配置

配置文件位于 `~/.cs/providers/*.env`，格式示例：

```bash
# zhipu.env
export ANTHROPIC_BASE_URL=https://api.minimaxi.com/anthropic
export ANTHROPIC_AUTH_TOKEN=your_token
export ANTHROPIC_MODEL=MiniMax-M2.7

# 清除冲突变量
unset OPENAI_API_KEY
unset OPENAI_BASE_URL
unset OPENAI_MODEL
```

## 命令参考

| 命令 | 说明 |
|------|------|
| `cs <provider>` | 切换到指定 provider |
| `cs -l` | 列出所有 provider |
| `cs -c` | 显示当前 provider |
| `cs -e <name>` | 编辑 provider 配置 |
| `cs -a` | 交互式添加 provider |
| `cs -d <name>` | 删除 provider |
| `cs -r` | 还原官方 Claude Code 默认配置 |
| `cs -u` | 更新 cs 到最新版本 |
| `cs -h` | 显示帮助 |

## Windows 支持

### 推荐：WSL（完全兼容）

在 WSL 终端中与 Linux 使用方式完全相同：

```bash
curl -fsSL https://raw.githubusercontent.com/leebo/cs/main/install.sh | bash
source ~/.bashrc
```

### 原生 Windows：Git Bash

Claude Code 在 Windows 上内部使用 Git Bash，cs 工具与其完全兼容。

**前提**：安装 [Git for Windows](https://git-scm.com/download/win)（含 Git Bash）

在 Git Bash 中运行：

```bash
curl -fsSL https://raw.githubusercontent.com/leebo/cs/main/install.sh | bash
source ~/.bash_profile
```

安装脚本会自动检测 Git Bash 环境并写入 `~/.bash_profile`（而非 `~/.bashrc`）。

> **注意**：Windows 上 `chmod 600` 不生效，provider 配置文件权限由 NTFS ACL 管理，安全性取决于系统账户权限设置。

## 工作原理

1. 安装时将 `source ~/.cs/lib/cs-core.sh` 添加到 shell 配置
2. `cs-core.sh` 注册目录切换 hook，自动检测 `.cs` 文件
3. `cs` 命令直接修改当前 shell 的环境变量，无需 direnv
