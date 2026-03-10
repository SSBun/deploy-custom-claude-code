#!/usr/bin/env bash
# Generic deployment script for Claude Code with custom models
# Supports any Claude-compatible API (Doubao, GLM, MiniMax, etc.)
#
# Usage:
#   ./deploy-claude-custom.sh
#   ./deploy-claude-custom.sh --tool-name claude-doubao --api-key KEY --base-url URL --model MODEL
#   ./deploy-claude-custom.sh --interactive

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default configuration
CLAUDE_MODEL_DIR="$HOME/.claude-model"
BIN_DIR="$CLAUDE_MODEL_DIR/bin"
CONFIG_DIR_BASE="$CLAUDE_MODEL_DIR"

# Variables to be set
TOOL_NAME=""
API_KEY=""
BASE_URL=""
MODEL_NAME=""
CONFIG_DIR=""
TIMEOUT_MS="${API_TIMEOUT_MS:-3000000}"

# Save original environment variable values
ORIGINAL_ENV_API_KEY="${DOUBAO_API_KEY:-${ANTHROPIC_API_KEY:-}}"

# Parse command-line arguments
INTERACTIVE_MODE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --tool-name|-t)
            TOOL_NAME="$2"
            shift 2
            ;;
        --api-key|-k)
            API_KEY="$2"
            shift 2
            ;;
        --base-url|-u)
            BASE_URL="$2"
            shift 2
            ;;
        --model|-m)
            MODEL_NAME="$2"
            shift 2
            ;;
        --timeout|-T)
            TIMEOUT_MS="$2"
            shift 2
            ;;
        --interactive|-i)
            INTERACTIVE_MODE=true
            shift
            ;;
        --help|-h)
            cat << EOF
Usage: $0 [OPTIONS]

Generic deployment script for Claude Code with custom models.

Options:
  --tool-name, -t NAME     Name of the tool command (must start with 'claude-')
                           Examples: claude-doubao, claude-glm, or just doubao/glm
  --api-key, -k KEY       API Key for the model
  --base-url, -u URL      Base URL for the API endpoint
  --model, -m NAME        Model name/identifier
  --timeout, -T MS        API timeout in milliseconds (default: 3000000)
  --interactive, -i       Force interactive mode
  --help, -h              Show this help message

Examples:
  # Interactive mode (will prompt for all values)
  $0

  # Non-interactive mode with all parameters
  $0 --tool-name claude-doubao \\
     --api-key YOUR_API_KEY \\
     --base-url https://ark.cn-beijing.volces.com/api/coding \\
     --model doubao-seed-code-preview-latest

  # Tool name will be auto-prefixed with 'claude-' if missing
  $0 --tool-name doubao \\
     --api-key YOUR_API_KEY \\
     --base-url https://ark.cn-beijing.volces.com/api/coding \\
     --model doubao-seed-code-preview-latest

  # Using environment variables
  TOOL_NAME=claude-glm API_KEY=KEY BASE_URL=URL MODEL=MODEL $0

Common Model Configurations:
  Doubao-Seed-Code:
    --base-url https://ark.cn-beijing.volces.com/api/coding
    --model doubao-seed-code-preview-latest

  GLM-4.6:
    --base-url https://open.bigmodel.cn/api/paas/v4
    --model glm-4-6

  MiniMax M2:
    --base-url https://api.minimax.chat/v1
    --model abab6.5s-chat

Get API Keys:
  Doubao: https://console.volcengine.com/ark/region:ark+cn-beijing/apikey
  GLM: https://open.bigmodel.cn/usercenter/apikeys
  MiniMax: https://platform.minimax.chat/
EOF
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# If no command-line args provided, use environment variables if available
if [ -z "$TOOL_NAME" ] && [ -n "${TOOL_NAME_ENV:-}" ]; then
    TOOL_NAME="$TOOL_NAME_ENV"
fi
if [ -z "$API_KEY" ] && [ -n "$ORIGINAL_ENV_API_KEY" ]; then
    API_KEY="$ORIGINAL_ENV_API_KEY"
fi
if [ -z "$BASE_URL" ] && [ -n "${BASE_URL_ENV:-}" ]; then
    BASE_URL="$BASE_URL_ENV"
fi
if [ -z "$MODEL_NAME" ] && [ -n "${MODEL_NAME_ENV:-}" ]; then
    MODEL_NAME="$MODEL_NAME_ENV"
fi

echo -e "${GREEN}=== Claude Custom Model Deployment Script ===${NC}\n"
echo -e "${CYAN}This script will help you deploy a custom Claude-compatible model${NC}\n"

# Function to normalize tool name to ensure it starts with "claude-"
normalize_tool_name() {
    local name="$1"
    # Remove any leading/trailing whitespace
    name=$(echo "$name" | xargs)
    
    # If it doesn't start with "claude-", prepend it
    if [[ ! "$name" =~ ^claude- ]]; then
        name="claude-$name"
    fi
    
    # Remove "claude-claude-" if somehow duplicated
    name=$(echo "$name" | sed 's/^claude-claude-/claude-/')
    
    echo "$name"
}

# Normalize tool name if provided
if [ -n "$TOOL_NAME" ]; then
    TOOL_NAME=$(normalize_tool_name "$TOOL_NAME")
fi

# Interactive mode: collect missing information
if [ "$INTERACTIVE_MODE" = true ] || [ -z "$TOOL_NAME" ] || [ -z "$API_KEY" ] || [ -z "$BASE_URL" ] || [ -z "$MODEL_NAME" ]; then
    echo -e "${YELLOW}Please provide the following information:${NC}\n"
    
    # Tool name
    if [ -z "$TOOL_NAME" ]; then
        echo -e "${BLUE}Tool Name${NC}"
        echo "  This will be the command name (must start with 'claude-')"
        echo "  Examples: doubao, glm-4, minimax (will become claude-doubao, claude-glm-4, claude-minimax)"
        echo "  Or: claude-doubao, claude-glm-4, claude-minimax"
        read -p "Tool name: " TOOL_NAME
        if [ -z "$TOOL_NAME" ]; then
            echo -e "${RED}Error: Tool name is required${NC}"
            exit 1
        fi
        # Normalize tool name (ensure it starts with claude-)
        TOOL_NAME=$(normalize_tool_name "$TOOL_NAME")
        # Validate tool name (alphanumeric and hyphens only, must start with claude-)
        if [[ ! "$TOOL_NAME" =~ ^claude-[a-zA-Z0-9-]+$ ]]; then
            echo -e "${RED}Error: Tool name must start with 'claude-' and contain only letters, numbers, and hyphens${NC}"
            exit 1
        fi
        echo -e "${GREEN}✓ Tool name normalized to: $TOOL_NAME${NC}"
    else
        # Normalize tool name even if provided via command line
        TOOL_NAME=$(normalize_tool_name "$TOOL_NAME")
        # Validate tool name
        if [[ ! "$TOOL_NAME" =~ ^claude-[a-zA-Z0-9-]+$ ]]; then
            echo -e "${RED}Error: Tool name must start with 'claude-' and contain only letters, numbers, and hyphens${NC}"
            exit 1
        fi
        echo -e "${GREEN}✓ Tool name: $TOOL_NAME${NC}"
    fi
    
    # API Key
    if [ -z "$API_KEY" ]; then
        echo ""
        echo -e "${BLUE}API Key${NC}"
        echo "  Your API key for accessing the model"
        read -p "API Key: " API_KEY
        if [ -z "$API_KEY" ]; then
            echo -e "${RED}Error: API Key is required${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}✓ API Key: ${API_KEY:0:10}...${NC}"
    fi
    
    # Base URL
    if [ -z "$BASE_URL" ]; then
        echo ""
        echo -e "${BLUE}Base URL${NC}"
        echo "  The API endpoint base URL"
        echo "  Examples:"
        echo "    - Doubao: https://ark.cn-beijing.volces.com/api/coding"
        echo "    - GLM: https://open.bigmodel.cn/api/paas/v4"
        echo "    - MiniMax: https://api.minimax.chat/v1"
        read -p "Base URL: " BASE_URL
        if [ -z "$BASE_URL" ]; then
            echo -e "${RED}Error: Base URL is required${NC}"
            exit 1
        fi
        # Validate URL format
        if [[ ! "$BASE_URL" =~ ^https?:// ]]; then
            echo -e "${RED}Error: Base URL must start with http:// or https://${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}✓ Base URL: $BASE_URL${NC}"
    fi
    
    # Model Name
    if [ -z "$MODEL_NAME" ]; then
        echo ""
        echo -e "${BLUE}Model Name${NC}"
        echo "  The model identifier/name"
        echo "  Examples:"
        echo "    - Doubao: doubao-seed-code-preview-latest"
        echo "    - GLM: glm-4-6"
        echo "    - MiniMax: abab6.5s-chat"
        read -p "Model name: " MODEL_NAME
        if [ -z "$MODEL_NAME" ]; then
            echo -e "${RED}Error: Model name is required${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}✓ Model name: $MODEL_NAME${NC}"
    fi
    
    # Timeout (optional)
    if [ -z "$TIMEOUT_MS" ] || [ "$TIMEOUT_MS" = "3000000" ]; then
        echo ""
        echo -e "${BLUE}API Timeout (optional)${NC}"
        echo "  Timeout in milliseconds (default: 3000000 = 50 minutes)"
        read -p "Timeout (ms) [3000000]: " TIMEOUT_INPUT
        if [ -n "$TIMEOUT_INPUT" ]; then
            TIMEOUT_MS="$TIMEOUT_INPUT"
        fi
    fi
fi

# Final validation: ensure tool name starts with claude-
if [ -n "$TOOL_NAME" ]; then
    TOOL_NAME=$(normalize_tool_name "$TOOL_NAME")
    if [[ ! "$TOOL_NAME" =~ ^claude-[a-zA-Z0-9-]+$ ]]; then
        echo -e "${RED}Error: Tool name must start with 'claude-' and contain only letters, numbers, and hyphens${NC}"
        echo "  Provided: $TOOL_NAME"
        exit 1
    fi
fi

# Validate all required fields
if [ -z "$TOOL_NAME" ] || [ -z "$API_KEY" ] || [ -z "$BASE_URL" ] || [ -z "$MODEL_NAME" ]; then
    echo -e "${RED}Error: Missing required parameters${NC}"
    echo "Required: --tool-name, --api-key, --base-url, --model"
    exit 1
fi

# Set config directory based on tool name
CONFIG_DIR="$CONFIG_DIR_BASE/.$TOOL_NAME"

echo -e "\n${GREEN}=== Configuration Summary ===${NC}"
echo "  Tool name:    $TOOL_NAME"
echo "  Base URL:     $BASE_URL"
echo "  Model:        $MODEL_NAME"
echo "  Timeout:      $TIMEOUT_MS ms"
echo "  Config dir:   $CONFIG_DIR"
echo ""

read -p "Continue with deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Step 1: Create project directory
echo -e "\n${YELLOW}Step 1: Creating project directory...${NC}"
if [ -d "$CLAUDE_MODEL_DIR" ]; then
    echo -e "${GREEN}✓ Directory already exists: $CLAUDE_MODEL_DIR${NC}"
else
    mkdir -p "$CLAUDE_MODEL_DIR"
    echo -e "${GREEN}✓ Created directory: $CLAUDE_MODEL_DIR${NC}"
fi

# Step 2: Install Claude Code
echo -e "\n${YELLOW}Step 2: Installing Claude Code...${NC}"
cd "$CLAUDE_MODEL_DIR"

if [ ! -f "package.json" ]; then
    echo "Initializing npm project..."
    npm init -y > /dev/null 2>&1
    echo -e "${GREEN}✓ Initialized npm project${NC}"
fi

if [ ! -d "node_modules/@anthropic-ai/claude-code" ]; then
    echo "Installing @anthropic-ai/claude-code..."
    npm install @anthropic-ai/claude-code
    echo -e "${GREEN}✓ Installed Claude Code${NC}"
else
    echo -e "${GREEN}✓ Claude Code already installed${NC}"
fi

# Step 3: Create config directory
echo -e "\n${YELLOW}Step 3: Creating config directory...${NC}"
mkdir -p "$CONFIG_DIR"
echo -e "${GREEN}✓ Created config directory: $CONFIG_DIR${NC}"

# Step 3b: Link skills folder
echo -e "\n${YELLOW}Step 3b: Linking skills folder...${NC}"
if [ -d "$HOME/.claude/skills" ]; then
    ln -sf "$HOME/.claude/skills" "$CONFIG_DIR/skills"
    echo -e "${GREEN}✓ Linked skills from ~/.claude/skills${NC}"
else
    echo -e "${YELLOW}⚠ No skills folder found at ~/.claude/skills, skipping${NC}"
fi

# Step 4: Create bin directory
echo -e "\n${YELLOW}Step 4: Creating bin directory...${NC}"
mkdir -p "$BIN_DIR"
echo -e "${GREEN}✓ Created bin directory: $BIN_DIR${NC}"

# Step 5: Create wrapper script
echo -e "\n${YELLOW}Step 5: Creating wrapper script...${NC}"
SCRIPT_PATH="$BIN_DIR/$TOOL_NAME"

cat > "$SCRIPT_PATH" << SCRIPT_EOF
#!/usr/bin/env bash
# Wrapper for Claude Code CLI using custom model API
# Generated by deploy-claude-custom.sh
# Tool: $TOOL_NAME
# Model: $MODEL_NAME

CLAUDE_BIN="\$HOME/.claude-model/node_modules/.bin/claude"

# Check if Claude Code is installed
if [ ! -f "\$CLAUDE_BIN" ]; then
    echo "Error: Claude Code not found at \$CLAUDE_BIN"
    echo "Please run the deployment script again."
    exit 1
fi

# Inject API credentials
export ANTHROPIC_AUTH_TOKEN="API_KEY_PLACEHOLDER"
export ANTHROPIC_BASE_URL="BASE_URL_PLACEHOLDER"
export ANTHROPIC_MODEL="MODEL_NAME_PLACEHOLDER"
export API_TIMEOUT_MS=TIMEOUT_PLACEHOLDER

# Keep a separate config dir for this tool
export CLAUDE_CONFIG_DIR="\$HOME/.claude-model/.$TOOL_NAME"

exec "\$CLAUDE_BIN" "\$@"
SCRIPT_EOF

# Replace placeholders with actual values
sed -i.bak "s|API_KEY_PLACEHOLDER|$API_KEY|g" "$SCRIPT_PATH"
sed -i.bak "s|BASE_URL_PLACEHOLDER|$BASE_URL|g" "$SCRIPT_PATH"
sed -i.bak "s|MODEL_NAME_PLACEHOLDER|$MODEL_NAME|g" "$SCRIPT_PATH"
sed -i.bak "s|TIMEOUT_PLACEHOLDER|$TIMEOUT_MS|g" "$SCRIPT_PATH"
rm -f "$SCRIPT_PATH.bak"

# Make script executable
chmod +x "$SCRIPT_PATH"
echo -e "${GREEN}✓ Created wrapper script: $SCRIPT_PATH${NC}"

# Step 6: PATH configuration
echo -e "\n${YELLOW}Step 6: PATH Configuration${NC}"

# Detect current shell using multiple methods
DETECTED_SHELL=""
SHELL_RC=""

# Method 1: Check $SHELL environment variable
if [ -n "$SHELL" ]; then
    DETECTED_SHELL=$(basename "$SHELL")
fi

# Method 2: Check actual running shell process
if [ -z "$DETECTED_SHELL" ]; then
    # Try to get shell from process info
    if command -v ps >/dev/null 2>&1; then
        CURRENT_SHELL=$(ps -p $$ -o comm= 2>/dev/null | xargs basename 2>/dev/null || echo "")
        if [ -n "$CURRENT_SHELL" ]; then
            DETECTED_SHELL="$CURRENT_SHELL"
        fi
    fi
fi

# Method 3: Check shell version variables as fallback
if [ -z "$DETECTED_SHELL" ]; then
    if [ -n "$ZSH_VERSION" ]; then
        DETECTED_SHELL="zsh"
    elif [ -n "$BASH_VERSION" ]; then
        DETECTED_SHELL="bash"
    fi
fi

# Method 4: Check $0 as last resort
if [ -z "$DETECTED_SHELL" ]; then
    SCRIPT_SHELL=$(basename "${0:-$SHELL}" 2>/dev/null)
    case "$SCRIPT_SHELL" in
        zsh|bash|sh)
            DETECTED_SHELL="$SCRIPT_SHELL"
            ;;
    esac
fi

# Determine shell config file based on detected shell
case "$DETECTED_SHELL" in
    zsh)
        SHELL_RC="$HOME/.zshrc"
        echo -e "${GREEN}✓ Detected shell: zsh${NC}"
        ;;
    bash)
        # On macOS, bash typically uses .bash_profile
        # On Linux, bash typically uses .bashrc
        if [[ "$OSTYPE" == "darwin"* ]]; then
            SHELL_RC="$HOME/.bash_profile"
            # Fallback to .bashrc if .bash_profile doesn't exist
            if [ ! -f "$SHELL_RC" ]; then
                SHELL_RC="$HOME/.bashrc"
            fi
        else
            SHELL_RC="$HOME/.bashrc"
            # Fallback to .bash_profile if .bashrc doesn't exist
            if [ ! -f "$SHELL_RC" ]; then
                SHELL_RC="$HOME/.bash_profile"
            fi
        fi
        echo -e "${GREEN}✓ Detected shell: bash${NC}"
        ;;
    sh|dash)
        # sh/dash typically use .profile
        SHELL_RC="$HOME/.profile"
        echo -e "${GREEN}✓ Detected shell: $DETECTED_SHELL${NC}"
        ;;
    fish)
        # Fish shell uses config.fish
        SHELL_RC="$HOME/.config/fish/config.fish"
        echo -e "${GREEN}✓ Detected shell: fish${NC}"
        ;;
    *)
        echo -e "${YELLOW}⚠ Could not reliably detect shell (detected: ${DETECTED_SHELL:-unknown})${NC}"
        echo -e "${YELLOW}  Will try common configuration files...${NC}"
        # Try common config files in order of preference
        for rc_file in "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.bashrc" "$HOME/.profile"; do
            if [ -f "$rc_file" ]; then
                SHELL_RC="$rc_file"
                echo -e "${GREEN}✓ Found existing config file: $SHELL_RC${NC}"
                break
            fi
        done
        ;;
esac

# If still no config file found, default to .zshrc (most common on macOS) or .bashrc
if [ -z "$SHELL_RC" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        SHELL_RC="$HOME/.zshrc"
    else
        SHELL_RC="$HOME/.bashrc"
    fi
    echo -e "${YELLOW}⚠ No existing config file found, will create: $SHELL_RC${NC}"
fi

# Add PATH configuration (different syntax for fish shell)
if [ "$DETECTED_SHELL" = "fish" ]; then
    PATH_LINE="set -gx PATH \$HOME/.claude-model/bin \$PATH"
else
    PATH_LINE="export PATH=\"\$HOME/.claude-model/bin:\$PATH\""
fi

if grep -q ".claude-model/bin" "$SHELL_RC" 2>/dev/null; then
    echo -e "${GREEN}✓ PATH already configured in $SHELL_RC${NC}"
else
    # Create directory for fish config if needed
    if [ "$DETECTED_SHELL" = "fish" ]; then
        mkdir -p "$(dirname "$SHELL_RC")"
    fi
    
    # Create file if it doesn't exist
    if [ ! -f "$SHELL_RC" ]; then
        touch "$SHELL_RC"
        echo -e "${GREEN}✓ Created config file: $SHELL_RC${NC}"
    fi
    
    echo "" >> "$SHELL_RC"
    echo "# Claude Custom Models - Added by deploy-claude-custom.sh" >> "$SHELL_RC"
    echo "$PATH_LINE" >> "$SHELL_RC"
    echo -e "${GREEN}✓ Added PATH configuration to $SHELL_RC${NC}"
    echo -e "${YELLOW}Please run: source $SHELL_RC${NC}"
    echo -e "${YELLOW}Or restart your terminal${NC}"
fi

# Step 7: Test installation
echo -e "\n${YELLOW}Step 7: Testing installation...${NC}"
if [ -f "$SCRIPT_PATH" ] && [ -x "$SCRIPT_PATH" ]; then
    echo -e "${GREEN}✓ Script is executable${NC}"
    
    # Try to get version (may fail if PATH not updated yet)
    if command -v "$TOOL_NAME" >/dev/null 2>&1; then
        echo "Testing command..."
        "$TOOL_NAME" --version 2>&1 | head -1 || echo -e "${YELLOW}Note: Command may not be in PATH yet. Please restart terminal.${NC}"
    else
        echo -e "${YELLOW}Note: Command not found in PATH.${NC}"
        echo -e "${YELLOW}You can test it directly with: $SCRIPT_PATH --version${NC}"
    fi
else
    echo -e "${RED}✗ Script is not executable${NC}"
    exit 1
fi

# Summary
echo -e "\n${GREEN}=== Deployment Complete! ===${NC}\n"
echo "Summary:"
echo "  • Tool name:      $TOOL_NAME"
echo "  • Project dir:    $CLAUDE_MODEL_DIR"
echo "  • Wrapper script: $SCRIPT_PATH"
echo "  • Config dir:     $CONFIG_DIR"
echo "  • Base URL:       $BASE_URL"
echo "  • Model:          $MODEL_NAME"
if [ -n "$DETECTED_SHELL" ]; then
    echo "  • Shell:          $DETECTED_SHELL"
fi
echo "  • Config file:    $SHELL_RC"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal or run: source $SHELL_RC"
echo "  2. Test with: $TOOL_NAME --version"
echo "  3. Use with: $TOOL_NAME"
echo ""
echo "Note: Original 'claude' command will continue to work with Claude Sonnet 4.5"
echo "      Use '$TOOL_NAME' to use your custom model"
echo ""
echo -e "${GREEN}Enjoy using Claude Code with $MODEL_NAME!${NC}"
