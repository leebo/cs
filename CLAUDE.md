# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

cs 是一个纯 Bash 的 Claude Code Provider 切换工具，零外部依赖（JSON 解析需要 jq 或 python3）。用户安装后，脚本部署到 `~/.cs/`，通过 shell hook 实现进入项目目录时自动加载 provider 配置。

## 开发与测试

没有构建步骤，直接修改源文件后通过 install.sh 部署到本地测试：

```bash
# 部署到本地 ~/.cs/
bash install.sh

# 重新加载（当前 session 立即生效）
source ~/.zshrc   # 或 ~/.bashrc

# 语法检查
bash -n bin/cs
bash -n lib/cs-core.sh
bash -n lib/cs-wizard.sh
bash -n install.sh

# 验证 providers.json 合法
python3 -c "import json; print(len(json.load(open('providers.json'))['providers']), 'providers')"
```

手动测试关键路径：

```bash
cs -l            # 列出 providers
cs -a            # 交互式向导
cs -u            # 自更新
cs ds            # 切换到 DeepSeek
cs -e ds         # 编辑配置
```

## 代码架构

### 文件职责

| 文件 | 运行上下文 | 职责 |
|------|-----------|------|
| `bin/cs` | 子进程（直接执行） | 命令行入口，source wizard 后处理所有 `-l/-c/-e/-a/-d/-u/-h` 子命令 |
| `lib/cs-core.sh` | source 进用户 shell | 注册 Zsh/Bash hook，提供 `cs()` 函数，管理环境变量保存/恢复 |
| `lib/cs-wizard.sh` | source 进两者 | JSON 解析、providers catalog 缓存、交互向导、自更新逻辑 |
| `lib/cs-core.fish` | source 进 Fish | Fish shell 专用实现，用 `--on-variable PWD` hook |
| `providers.json` | 远程读取 | 提供商目录（托管在 GitHub），本地缓存 24h |
| `install.sh` | 手动执行 | 复制文件到 `~/.cs/`，写入 shell RC 文件 |

### 关键设计

**双入口问题**：`bin/cs`（子进程）和 `lib/cs-core.sh` 中的 `cs()`（source 函数）是两套平行实现。修改命令逻辑时必须同步更新两处。两者都在顶部 source `cs-wizard.sh` 获取向导和更新函数。

**环境变量管理**：`cs-core.sh` 中的 `_cs_save_env` / `_cs_restore_env` / `_cs_clear_env` 管理 11 个变量（8 个 Anthropic + 3 个 OpenAI）。修改支持的环境变量时，这三个函数必须同步，同时还要更新 `bin/cs` 的 `switch_provider()` 里的 `unset` 列表。

**providers catalog 流程**：`_cs_get_catalog_file()` 按优先级：本地缓存新鲜（<24h）→ 远程下载 → 过期缓存（显示 `[offline]`）→ 报错。`cs -u` 强制跳过 TTL 刷新。

**JSON 解析双引擎**：`_cs_detect_json_engine()` 优先用 `jq`，回退到 `python3`。所有 `_cs_json_*` 函数都提供两套实现。

**目录自动切换**：`cs_load_from_file()` 是核心 hook 函数。它向上递归查找 `.cs` 文件，用 `CS_LAST_DIR` / `CS_LAST_PROVIDER` 跟踪状态，离开项目树时调用 `_cs_restore_env`。

### providers.json 结构

每个 provider 的关键字段：
- `default_alias`：推荐简称（如 `ds` / `km`），向导默认值
- `set_vars`：生成 `.env` 时 export 的变量，支持 `{{api_key}}` `{{model}}` `{{base_url}}` 占位符
- `unset_vars`：切换时需清除的冲突变量
- `input_base_url: true`：custom 类型，需用户手动输入 base_url

## 添加新提供商

只需编辑 `providers.json`，push 到 GitHub 后用户运行 `cs -u` 即可获取。无需修改任何脚本。
