# 部署自定义 Claude Code

一个通用的部署脚本，用于设置 Claude Code 与自定义 Claude 兼容模型（豆包、智谱、MiniMax 等）。

**[English](README.md)**

## 功能特性

- 🚀 **轻松部署**：在几分钟内部署自定义 Claude 兼容模型
- 🔧 **通用灵活**：适用于任何 Claude 兼容的 API
- 🎯 **多模型支持**：同时部署多个模型（如 `claude-doubao`、`claude-glm`、`claude-kimi`）
- 🔄 **多模型部署**：每个部署可包含多个模型，支持运行时选择
- 🐚 **智能 Shell 检测**：自动检测并配置您的 shell（zsh、bash、fish）
- ✅ **验证**：确保工具名称遵循 `claude-xxx` 命名约定
- 📝 **交互式与非交互式**：支持交互式提示和命令行参数
- 🧪 **测试**：使用 `test` 命令验证部署是否正常工作
- 💾 **备份/恢复**：导出和导入部署配置
- 🔍 **诊断**：使用 `doctor` 命令排查问题
- 🔄 **自动更新**：一键从 GitHub 更新 claude-custom

## 快速开始

### 方式 1：使用 claude-custom（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/SSBun/deploy-custom-claude-code/main/install.sh | sudo bash
```

然后添加部署：
```bash
claude-custom add doubao
claude-custom add glm
claude-custom list
```

### 方式 2：直接部署脚本（传统方式）

见下文的传统单部署脚本。

## 使用 claude-custom

`claude-custom` 工具让您可以轻松管理多个自定义 Claude 部署。

**注意**：工具名称会自动添加 `claude-` 前缀。例如，`doubao` 会变成 `claude-doubao`。

### 命令

```bash
# 添加新部署
claude-custom add <name> [options]

# 列出所有部署
claude-custom list

# 管理部署的模型
claude-custom models <name>                    # 列出所有模型
claude-custom models <name> --default MODEL    # 设置默认模型
claude-custom models <name> --add MODEL        # 添加模型
claude-custom models <name> --remove MODEL     # 删除模型

# 更新部署
claude-custom update <name> [options]

# 删除部署
claude-custom remove <name>

# 测试部署功能
claude-custom test <name>
claude-custom test --all

# 升级 Claude Code
claude-custom upgrade

# 配置管理
claude-custom config           # 显示配置位置
claude-custom config show      # 显示配置内容
claude-custom config edit      # 编辑配置文件
claude-custom config validate  # 验证配置语法

# 导出/导入部署
claude-custom export [file]                    # 导出到文件或标准输出
claude-custom import [file]                    # 从文件或标准输入导入
claude-custom import backup.json --merge       # 与现有配置合并

# 诊断问题
claude-custom doctor

# 卸载
claude-custom uninstall          # 仅删除配置
claude-custom uninstall --all    # 删除所有内容

# 更新 claude-custom 本身
claude-custom self-update
```

### 多模型支持

每个部署现在可以支持多个模型，并在运行时选择模型。

```bash
# 添加包含多个模型的部署
claude-custom add glm --models "glm-4,glm-4-plus,glm-4-6" --default-model glm-4

# 或使用多个 --model 标志
claude-custom add glm --model glm-4 --model glm-4-plus --model glm-4-6 --default-model glm-4

# 列出部署的所有模型
claude-custom models glm

# 向现有部署添加新模型
claude-custom models glm --add glm-4-32k

# 删除模型
claude-custom models glm --remove glm-4-32k

# 设置不同的默认模型
claude-custom models glm --default glm-4-6

# 在运行时使用特定模型
claude-glm --use-model glm-4-6

# 或使用环境变量
CLAUDE_MODEL=glm-4-6 claude-glm
```

### 示例

```bash
# 交互式添加
claude-custom add doubao

# 非交互式添加单个模型
claude-custom add glm --api-key YOUR_KEY --base-url https://open.bigmodel.cn/api/paas/v4 --model glm-4-6

# 非交互式添加多个模型
claude-custom add glm --api-key YOUR_KEY --base-url https://open.bigmodel.cn/api/paas/v4 --models "glm-4,glm-4-plus,glm-4-6"

# 列出所有部署及模型数量
claude-custom list

# 显示部署的模型
claude-custom models glm

# 测试特定部署
claude-custom test doubao

# 测试所有部署
claude-custom test --all

# 更新 API 密钥
claude-custom update glm --api-key NEW_KEY

# 向现有部署添加模型
claude-custom update glm --add-model glm-4-flash

# 删除模型
claude-custom update glm --remove-model glm-4-flash

# 更改默认模型
claude-custom update glm --default-model glm-4-6

# 导出配置
claude-custom export > backup.json

# 导入配置
claude-custom import backup.json

# 与现有配置合并
claude-custom import backup.json --merge

# 诊断问题
claude-custom doctor

# 删除部署
claude-custom remove glm
```

## 传统方式：直接部署脚本

### 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/SSBun/deploy-custom-claude-code/main/deploy-claude-custom.sh -o deploy.sh && bash deploy.sh
```

### 交互模式（首次使用推荐）

```bash
./deploy-claude-custom.sh
```

脚本会提示您输入：
- 工具名称（如 `doubao`、`glm-4` - 将变成 `claude-doubao`、`claude-glm-4`）
- API 密钥
- 基础 URL
- 模型名称
- 超时时间（可选）

### 非交互模式

```bash
./deploy-claude-custom.sh \
  --tool-name claude-doubao \
  --api-key YOUR_API_KEY \
  --base-url https://ark.cn-beijing.volces.com/api/coding \
  --model doubao-seed-code-preview-latest
```

### 使用短标志

```bash
./deploy-claude-custom.sh -t claude-glm -k KEY -u URL -m glm-4-6
```

## 常见模型配置

### 豆包 Seed Code

```bash
./deploy-claude-custom.sh \
  --tool-name doubao \
  --api-key YOUR_API_KEY \
  --base-url https://ark.cn-beijing.volces.com/api/coding \
  --model doubao-seed-code-preview-latest
```

**获取 API 密钥**：https://console.volcengine.com/ark/region:ark+cn-beijing/apikey

### 智谱 GLM-4.6

```bash
./deploy-claude-custom.sh \
  --tool-name glm \
  --api-key YOUR_API_KEY \
  --base-url https://open.bigmodel.cn/api/paas/v4 \
  --model glm-4-6
```

**获取 API 密钥**：https://open.bigmodel.cn/usercenter/apikeys

### MiniMax M2

```bash
./deploy-claude-custom.sh \
  --tool-name minimax \
  --api-key YOUR_API_KEY \
  --base-url https://api.minimax.chat/v1 \
  --model abab6.5s-chat
```

**获取 API 密钥**：https://platform.minimax.chat/

## 使用方法

部署完成后，重启终端或运行：

```bash
source ~/.zshrc  # 或 ~/.bashrc、~/.bash_profile 等
```

然后使用您的自定义工具：

```bash
claude-glm --version
claude-glm  # 使用默认模型启动 Claude Code

# 使用特定模型（如果部署有多个模型）
claude-glm --use-model glm-4-6

# 或使用环境变量
CLAUDE_MODEL=glm-4-6 claude-glm
```

## 部署多个模型

您可以部署多个模型，每个都有自己的命令：

```bash
# 部署豆包
./deploy-claude-custom.sh -t doubao -k KEY1 -u URL1 -m MODEL1

# 部署智谱
./deploy-claude-custom.sh -t glm -k KEY2 -u URL2 -m MODEL2

# 部署 MiniMax
./deploy-claude-custom.sh -t minimax -k KEY3 -u URL3 -m MODEL3
```

每个工具都有自己独立的：
- 命令名称：`claude-doubao`、`claude-glm`、`claude-minimax`
- 配置目录：`~/.claude-doubao`、`~/.claude-glm`、`~/.claude-minimax`
- 独立配置

## 命令行选项

### claude-custom add

```
选项:
  --api-key, -k KEY       模型提供商的 API 密钥
  --base-url, -u URL      API 端点的基础 URL
  --model, -m MODEL       要使用的模型名称（可多次指定）
  --models LIST           逗号分隔的模型列表
  --default-model NAME    要使用的默认模型（默认为第一个模型）
```

### claude-custom update

```
选项:
  --api-key, -k KEY       新的 API 密钥
  --base-url, -u URL      新的基础 URL
  --model, -m MODEL       新的模型名称（替换所有模型）
  --add-model MODEL       向现有模型添加一个模型
  --remove-model MODEL    从列表中删除一个模型
  --default-model NAME    设置默认模型
```

### claude-custom models

```
操作:
  (none)                  列出部署的所有模型
  --default NAME          设置默认模型
  --add NAME              添加新模型
  --remove NAME           删除模型
```

### 传统脚本选项

```
选项:
  --tool-name, -t NAME     工具命令的名称（必须以 'claude-' 开头）
                           示例：claude-doubao、claude-glm，或直接用 doubao/glm
  --api-key, -k KEY       模型的 API 密钥
  --base-url, -u URL      API 端点的基础 URL
  --model, -m NAME        模型名称/标识符
  --timeout, -T MS        API 超时时间（毫秒，默认：3000000）
  --interactive, -i       强制交互模式
  --help, -h              显示此帮助信息
```

## 环境变量

您也可以使用环境变量：

```bash
TOOL_NAME=claude-glm \
API_KEY=YOUR_KEY \
BASE_URL=https://api.example.com/v1 \
MODEL=glm-4-6 \
./deploy-claude-custom.sh
```

## 工作原理

1. **创建项目结构**：设置 `~/claude-model/` 目录
2. **安装 Claude Code**：通过 npm 安装 `@anthropic-ai/claude-code`
3. **创建包装脚本**：使用您的 API 设置生成自定义包装脚本
4. **多模型支持**：包装脚本支持 `--use-model` 标志进行运行时模型选择
5. **配置 PATH**：自动将 `~/.claude-custom/bin` 添加到您的 PATH
6. **Shell 检测**：检测您的 shell（zsh、bash、fish）并配置相应的配置文件

## 目录结构

部署完成后：

```
~/.claude-custom/
├── bin/
│   ├── claude-doubao      # 您的自定义工具
│   ├── claude-glm         # 另一个自定义工具
│   └── ...
├── claude                 # 默认别名脚本
└── config.json            # 部署配置

~/claude-model/
├── .claude-doubao/        # claude-doubao 的配置
├── .claude-glm/           # claude-glm 的配置
├── node_modules/
│   └── @anthropic-ai/
│       └── claude-code/
└── package.json
```

## 系统要求

- Node.js 和 npm（用于安装 Claude Code）
- Bash shell
- jq（JSON 处理器，用于管理配置）
- Git（用于克隆此仓库）

## 注意事项

- 原始的 `claude` 命令继续使用 Claude Sonnet 4.5
- 每个部署现在可以有多个模型，通过 `--use-model` 标志或 `CLAUDE_MODEL` 环境变量进行运行时选择
- 每个自定义工具都有自己独立的配置
- 脚本支持 macOS 和 Linux
- 配置存储在 `~/.claude-custom/config.json`
- 包装脚本存储在 `~/.claude-custom/bin/`
- 传统的单模型部署会在首次使用时自动迁移到多模型格式

## 故障排除

### 运行诊断

使用 `doctor` 命令诊断常见问题：

```bash
claude-custom doctor
```

这将检查：
- jq、Node.js 和 npm 的安装
- Claude Code 的安装
- 配置文件的有效性
- PATH 配置
- 部署包装脚本
- 网络连接

### 找不到 claude-custom 命令

```bash
# 重新加载 shell 配置
source ~/.zshrc  # 或 ~/.bashrc、~/.bash_profile

# 或重启终端
```

### 测试部署功能

```bash
# 测试特定部署
claude-custom test doubao

# 测试所有部署
claude-custom test --all
```

### 配置位置

查看或编辑配置：

```bash
# 显示配置位置
claude-custom config

# 显示配置内容
claude-custom config show

# 编辑配置文件
claude-custom config edit

# 验证配置语法
claude-custom config validate
```

### 传统脚本故障排除

```bash
# 重新加载 shell 配置
source ~/.zshrc  # 或 ~/.bashrc、~/.bash_profile

# 或重启终端
```

### PATH 未配置

检查 PATH 是否已添加到 shell 配置：

```bash
grep "claude-custom/bin" ~/.zshrc  # 或 ~/.bashrc
```

如果未找到，手动添加：

```bash
echo 'export PATH="$HOME/.claude-custom/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### 脚本权限被拒绝

```bash
chmod +x deploy-claude-custom.sh
```

## 许可证

此脚本按原样提供，用于 Claude Code 和兼容模型。

## 贡献

欢迎贡献！请随时提交问题或拉取请求。

## 参考资料

- [Claude Code 文档](https://code.claude.com/docs)
- 基于：[阮一峰的网络日志 - 国产大模型接入 Claude Code 教程](https://www.ruanyifeng.com/blog/2025/11/doubao-seed-code.html)
