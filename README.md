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

# 添加新 provider
cs -a my-custom

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
| `cs -a <name>` | 添加新 provider |
| `cs -d <name>` | 删除 provider |
| `cs -h` | 显示帮助 |

## 工作原理

1. 安装时将 `source ~/.cs/lib/cs-core.sh` 添加到 shell 配置
2. `cs-core.sh` 注册目录切换 hook，自动检测 `.cs` 文件
3. `cs` 命令直接修改当前 shell 的环境变量，无需 direnv
