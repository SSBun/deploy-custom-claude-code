# Deploy Custom Claude Code

A generic deployment script for setting up Claude Code with custom Claude-compatible models (Doubao, GLM, MiniMax, etc.).

## Quick Start

### Option 1: Using claude-custom (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/SSBun/deploy-custom-claude-code/main/install.sh | sudo bash
```

Then add deployments:
```bash
claude-custom add doubao
claude-custom add glm
claude-custom list
```

### Option 2: Direct Deployment Script (Legacy)

See below for the traditional single-deployment script.

## Using claude-custom

The `claude-custom` tool allows you to manage multiple custom Claude deployments easily.

**Note**: Tool names are automatically prefixed with `claude-`. For example, `doubao` becomes `claude-doubao`.

### Commands

```bash
# Add a new deployment
claude-custom add <name> [--api-key KEY] [--base-url URL] [--model MODEL]

# List all deployments
claude-custom list

# Update a deployment
claude-custom update <name> [--api-key KEY] [--base-url URL] [--model MODEL]

# Remove a deployment
claude-custom remove <name>

# Test deployment functionality
claude-custom test <name>
claude-custom test --all

# Upgrade Claude Code
claude-custom upgrade

# Configuration management
claude-custom config           # Show config location
claude-custom config show      # Show config contents
claude-custom config edit      # Edit config file
claude-custom config validate  # Validate config syntax

# Export/Import deployments
claude-custom export [file]                    # Export to file or stdout
claude-custom import [file]                    # Import from file or stdin
claude-custom import backup.json --merge       # Merge with existing config

# Diagnose issues
claude-custom doctor

# Uninstall
claude-custom uninstall          # Remove config only
claude-custom uninstall --all    # Remove everything

# Update claude-custom itself
claude-custom self-update
```

### Examples

```bash
# Interactive add
claude-custom add doubao

# Non-interactive add
claude-custom add glm --api-key YOUR_KEY --base-url https://open.bigmodel.cn/api/paas/v4 --model glm-4-6

# List all deployments with versions
claude-custom list

# Test a specific deployment
claude-custom test doubao

# Test all deployments
claude-custom test --all

# Update API key
claude-custom update doubao --api-key NEW_KEY

# Export configuration
claude-custom export > backup.json

# Import configuration
claude-custom import backup.json

# Merge with existing config
claude-custom import backup.json --merge

# Diagnose issues
claude-custom doctor

# Remove deployment
claude-custom remove glm
```

## Features

- 🚀 **Easy Deployment**: Deploy custom Claude-compatible models in minutes
- 🔧 **Generic & Flexible**: Works with any Claude-compatible API
- 🎯 **Multiple Models**: Deploy multiple models simultaneously (e.g., `claude-doubao`, `claude-glm`, `claude-kimi`)
- 🐚 **Smart Shell Detection**: Automatically detects and configures your shell (zsh, bash, fish)
- ✅ **Validation**: Ensures tool names follow `claude-xxx` naming convention
- 📝 **Interactive & Non-Interactive**: Supports both interactive prompts and command-line arguments
- 🧪 **Testing**: Verify deployments work with the `test` command
- 💾 **Backup/Restore**: Export and import deployment configurations
- 🔍 **Diagnostics**: Troubleshoot issues with the `doctor` command
- 🔄 **Self-Update**: Update claude-custom from GitHub with one command

## Alternative: Direct Deployment Script

### One-Line Installation

```bash
curl -fsSL https://raw.githubusercontent.com/SSBun/deploy-custom-claude-code/main/deploy-claude-custom.sh -o deploy.sh && bash deploy.sh
```

### Interactive Mode (Recommended for first-time use)

```bash
./deploy-claude-custom.sh
```

The script will prompt you for:
- Tool name (e.g., `doubao`, `glm-4` - will become `claude-doubao`, `claude-glm-4`)
- API Key
- Base URL
- Model name
- Timeout (optional)

### Non-Interactive Mode

```bash
./deploy-claude-custom.sh \
  --tool-name claude-doubao \
  --api-key YOUR_API_KEY \
  --base-url https://ark.cn-beijing.volces.com/api/coding \
  --model doubao-seed-code-preview-latest
```

### Using Short Flags

```bash
./deploy-claude-custom.sh -t claude-glm -k KEY -u URL -m glm-4-6
```

## Common Model Configurations

### Doubao-Seed-Code

```bash
./deploy-claude-custom.sh \
  --tool-name doubao \
  --api-key YOUR_API_KEY \
  --base-url https://ark.cn-beijing.volces.com/api/coding \
  --model doubao-seed-code-preview-latest
```

**Get API Key**: https://console.volcengine.com/ark/region:ark+cn-beijing/apikey

### GLM-4.6

```bash
./deploy-claude-custom.sh \
  --tool-name glm \
  --api-key YOUR_API_KEY \
  --base-url https://open.bigmodel.cn/api/paas/v4 \
  --model glm-4-6
```

**Get API Key**: https://open.bigmodel.cn/usercenter/apikeys

### MiniMax M2

```bash
./deploy-claude-custom.sh \
  --tool-name minimax \
  --api-key YOUR_API_KEY \
  --base-url https://api.minimax.chat/v1 \
  --model abab6.5s-chat
```

**Get API Key**: https://platform.minimax.chat/

## Usage

After deployment, restart your terminal or run:

```bash
source ~/.zshrc  # or ~/.bashrc, ~/.bash_profile, etc.
```

Then use your custom tool:

```bash
claude-doubao --version
claude-doubao  # Start Claude Code with Doubao model
```

## Deploying Multiple Models

You can deploy multiple models, each with its own command:

```bash
# Deploy Doubao
./deploy-claude-custom.sh -t doubao -k KEY1 -u URL1 -m MODEL1

# Deploy GLM
./deploy-claude-custom.sh -t glm -k KEY2 -u URL2 -m MODEL2

# Deploy MiniMax
./deploy-claude-custom.sh -t minimax -k KEY3 -u URL3 -m MODEL3
```

Each tool will have its own:
- Command name: `claude-doubao`, `claude-glm`, `claude-minimax`
- Config directory: `~/.claude-doubao`, `~/.claude-glm`, `~/.claude-minimax`
- Independent configuration

## Command-Line Options

```
Options:
  --tool-name, -t NAME     Name of the tool command (must start with 'claude-')
                           Examples: claude-doubao, claude-glm, or just doubao/glm
  --api-key, -k KEY       API Key for the model
  --base-url, -u URL      Base URL for the API endpoint
  --model, -m NAME        Model name/identifier
  --timeout, -T MS        API timeout in milliseconds (default: 3000000)
  --interactive, -i       Force interactive mode
  --help, -h              Show this help message
```

## Environment Variables

You can also use environment variables:

```bash
TOOL_NAME=claude-glm \
API_KEY=YOUR_KEY \
BASE_URL=https://api.example.com/v1 \
MODEL=glm-4-6 \
./deploy-claude-custom.sh
```

## How It Works

1. **Creates Project Structure**: Sets up `~/claude-model/` directory
2. **Installs Claude Code**: Installs `@anthropic-ai/claude-code` via npm
3. **Creates Wrapper Script**: Generates a custom wrapper script with your API settings
4. **Configures PATH**: Automatically adds `~/claude-model/bin` to your PATH
5. **Shell Detection**: Detects your shell (zsh, bash, fish) and configures the appropriate config file

## Directory Structure

After deployment:

```
~/claude-model/
├── bin/
│   ├── claude-doubao      # Your custom tool
│   ├── claude-glm         # Another custom tool
│   └── ...
├── .claude-doubao/        # Config for claude-doubao
├── .claude-glm/           # Config for claude-glm
├── node_modules/
│   └── @anthropic-ai/
│       └── claude-code/
└── package.json
```

## Requirements

- Node.js and npm (for installing Claude Code)
- Bash shell
- jq (JSON processor, for managing configurations)
- Git (for cloning this repository)

## Notes

- The original `claude` command continues to work with Claude Sonnet 4.5
- Each custom tool has its own isolated configuration
- The script supports macOS and Linux
- Configuration is stored in `~/.claude-custom/config.json`

## Troubleshooting

### Run diagnostics

Use the `doctor` command to diagnose common issues:

```bash
claude-custom doctor
```

This will check:
- jq, Node.js, and npm installations
- Claude Code installation
- Config file validity
- PATH configuration
- Deployment wrapper scripts
- Network connectivity

### claude-custom command not found

```bash
# Reload your shell configuration
source ~/.zshrc  # or ~/.bashrc, ~/.bash_profile

# Or restart your terminal
```

### Test deployment functionality

```bash
# Test a specific deployment
claude-custom test doubao

# Test all deployments
claude-custom test --all
```

### Configuration location

View or edit configuration:
```bash
# Show config location
claude-custom config

# Show config contents
claude-custom config show

# Edit config file
claude-custom config edit

# Validate config syntax
claude-custom config validate
```

### Legacy script troubleshooting

```bash
# Reload your shell configuration
source ~/.zshrc  # or ~/.bashrc, ~/.bash_profile

# Or restart your terminal
```

### PATH not configured

Check if PATH was added to your shell config:

```bash
grep "claude-model/bin" ~/.zshrc  # or ~/.bashrc
```

If not found, manually add:

```bash
echo 'export PATH="$HOME/claude-model/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Script permission denied

```bash
chmod +x deploy-claude-custom.sh
```

## License

This script is provided as-is for use with Claude Code and compatible models.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## References

- [Claude Code Documentation](https://code.claude.com/docs)
- Based on: [阮一峰的网络日志 - 国产大模型接入 Claude Code 教程](https://www.ruanyifeng.com/blog/2025/11/doubao-seed-code.html)
