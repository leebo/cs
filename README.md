# cs - Claude Code Provider Switcher

简化 Claude Code 多 Provider 切换的工具。零依赖，支持目录级自动切换。

## 安装

```bash
curl -fsSL https://raw.githubusercontent.com/bobo/ai-env/main/cs/install.sh | bash
source ~/.zshrc  # 或 ~/.bashrc
```

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
