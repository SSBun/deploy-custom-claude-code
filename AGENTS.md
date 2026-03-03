# AGENTS.md

## Project Overview

This is a deployment script for setting up [Claude Code](https://code.claude.com/docs) with custom Claude-compatible models (Doubao, GLM, MiniMax, etc.). The script creates isolated deployments that allow users to run multiple custom models side-by-side with the standard `claude` command.

## Key Concepts

- **Claude Code**: The official CLI tool by Anthropic for AI-assisted software development
- **Custom Model APIs**: Third-party APIs that provide Claude-compatible endpoints (Doubao, GLM, MiniMax, etc.)
- **Wrapper Script Pattern**: The script generates bash wrapper scripts that inject custom API credentials via environment variables
- **Isolated Configuration**: Each tool gets its own config directory (e.g., `~/.claude-doubao`)

## Project Structure

```
claude-custom/
├── deploy-claude-custom.sh    # Main deployment script
├── README.md                    # User documentation
└── AGENTS.md                    # This file - agent documentation
```

### New Architecture (claude-custom)

The recommended way to manage deployments is via the `claude-custom` CLI tool:

```
/usr/local/bin/claude-custom    # Main manager CLI
~/.claude-custom/config.json    # Deployment registry
~/claude-model/bin/claude-*     # Generated wrapper scripts
```

The `claude-custom` command is installed once, then used to add/remove/list/update deployments.

### Generated Structure (after deployment)

```
~/claude-model/
├── bin/
│   ├── claude-doubao           # Generated wrapper scripts
│   └── claude-glm
├── .claude-doubao/             # Per-tool config directories
├── .claude-glm/
├── node_modules/
│   └── @anthropic-ai/claude-code/
└── package.json
```

## Technical Architecture

### Script Flow

1. **Parse Arguments**: Command-line flags and environment variables
2. **Normalize Tool Name**: Ensures `claude-` prefix (e.g., `doubao` → `claude-doubao`)
3. **Interactive/Non-Interactive**: Prompts for missing values or uses provided args
4. **Validation**: Validates tool name format, URL format, required fields
5. **Create Directories**: `~/claude-model/bin`, `~/claude-model/.<tool-name>`
6. **Install Claude Code**: `npm install @anthropic-ai/claude-code`
7. **Generate Wrapper**: Creates executable bash script with injected credentials
8. **Configure PATH**: Adds `~/claude-model/bin` to user's shell config
9. **Test Installation**: Verifies script is executable

### Wrapper Script Template

Generated wrappers inject these environment variables:

```bash
export ANTHROPIC_AUTH_TOKEN="<API_KEY>"
export ANTHROPIC_BASE_URL="<BASE_URL>"
export ANTHROPIC_MODEL="<MODEL_NAME>"
export API_TIMEOUT_MS="<TIMEOUT>"
export CLAUDE_CONFIG_DIR="$HOME/claude-model/.<TOOL_NAME>"
```

Then exec into: `$HOME/claude-model/node_modules/.bin/claude`

## Agent Guidelines

### When Working on This Project

1. **Keep It Simple**: This is a single-purpose deployment script. Avoid over-engineering.
2. **Bash Compatibility**: Target POSIX bash compatibility. Avoid bashisms when possible.
3. **User Experience**: Prioritize clear error messages and helpful guidance.
4. **Shell Detection**: The script supports zsh, bash, fish, sh/dash. Test changes against all.
5. **Security**: API keys are stored in generated wrapper scripts. Warn users about file permissions.

### Common Tasks

#### Adding Support for a New Model

1. Add model configuration to help text (lines ~99-115)
2. Add example to README.md

#### Modifying Shell Detection

The shell detection logic (lines ~385-480) uses multiple methods:
- `$SHELL` environment variable
- `ps -p $$` process inspection
- `$ZSH_VERSION`/`$BASH_VERSION` variables
- `$0` fallback

Test changes across: macOS (zsh default), Linux (bash default), fish shell.

#### Testing Deployment

```bash
# Test with real values (will prompt interactively)
./deploy-claude-custom.sh --tool-name test-model --api-key test --base-url https://api.test.com/v1 --model test-model

# Test environment variable mode
TOOL_NAME=claude-test API_KEY=test BASE_URL=https://api.test.com/v1 MODEL=test ./deploy-claude-custom.sh
```

## Important Files

| File | Purpose |
|------|---------|
| `claude-custom` | Main CLI manager (new) |
| `install.sh` | One-line installer for claude-custom (new) |
| `deploy-claude-custom.sh` | Legacy single-deployment script |
| `README.md` | User-facing documentation |
| `AGENTS.md` | This file - agent guidance |

## Design Decisions

### Why `claude-` prefix requirement?

- Avoids conflicts with existing commands
- Makes it clear which commands are Claude-related
- Consistent with Claude Code naming conventions

### Why separate config directories?

- Allows multiple model deployments without conflict
- Each tool can have independent Claude Code settings
- Cleaner separation of concerns

### Why sed for placeholder replacement?

- Simple and reliable for single-line replacements
- No external dependencies beyond standard Unix tools
- Creates `.bak` file for safety (removed after)

## Known Limitations

1. **macOS/Linux Only**: Script assumes Unix-like environment
2. **npm Required**: Depends on Node.js package manager
3. **Credential Storage**: API keys stored in plaintext in generated scripts
4. **PATH Updates**: Requires shell restart or `source` command
5. **No Uninstall**: No automatic cleanup/uninstall mechanism

## Future Considerations

- Add uninstall/cleanup functionality
- Support for Windows (WSL or PowerShell)
- Encrypted credential storage
- Configuration file support for batch deployments
- Validation of API credentials before deployment
- Update mechanism for existing deployments
