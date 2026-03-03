# Claude Custom Manager Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a `claude-custom` CLI tool that allows users to add, remove, list, update, and migrate custom Claude Code deployments after a one-time installation.

**Architecture:** Pure bash script with jq for JSON manipulation. One-line installer downloads main script to `/usr/local/bin/`, config stored in `~/.claude-custom/config.json`, deployed wrappers go to `~/claude-model/bin/`.

**Tech Stack:** Bash, jq (JSON), curl (downloads), npm (Claude Code dependency)

---

## Task 1: Create the main claude-custom script skeleton

**Files:**
- Create: `claude-custom`

**Step 1: Create the script header and main structure**

```bash
#!/usr/bin/env bash
# Claude Custom Manager - Manage custom Claude Code deployments
# Usage: claude-custom <command> [options]

set -e  # Exit on error

# Version
VERSION="1.0.0"

# Configuration
CONFIG_DIR="$HOME/.claude-custom"
CONFIG_FILE="$CONFIG_DIR/config.json"
CLAUDE_MODEL_DIR="$HOME/claude-model"
BIN_DIR="$CLAUDE_MODEL_DIR/bin"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Main entry point
main() {
    local command="$1"
    shift || true

    case "$command" in
        add)
            cmd_add "$@"
            ;;
        remove)
            cmd_remove "$@"
            ;;
        list)
            cmd_list "$@"
            ;;
        update)
            cmd_update "$@"
            ;;
        migrate)
            cmd_migrate "$@"
            ;;
        --help|-h|"")
            show_help
            ;;
        --version|-v)
            show_version
            ;;
        *)
            echo -e "${RED}Unknown command: $command${NC}"
            echo "Run 'claude-custom --help' for usage"
            exit 2
            ;;
    esac
}

show_help() {
    cat << EOF
claude-custom - Manage custom Claude Code deployments

Usage: claude-custom <command> [options]

Commands:
  add      Add a new custom model deployment
  remove   Remove a deployment
  list     List all deployments
  update   Update a deployment
  migrate  Import existing deployments

Options:
  --help, -h     Show this help message
  --version, -v  Show version

Run 'claude-custom <command> --help' for more info on a command.
EOF
}

show_version() {
    echo "claude-custom $VERSION"
}

# Command stubs (to be implemented)
cmd_add() {
    echo "TODO: Implement add command"
}

cmd_remove() {
    echo "TODO: Implement remove command"
}

cmd_list() {
    echo "TODO: Implement list command"
}

cmd_update() {
    echo "TODO: Implement update command"
}

cmd_migrate() {
    echo "TODO: Implement migrate command"
}

# Run main
main "$@"
```

**Step 2: Make script executable and test basic functionality**

```bash
chmod +x claude-custom
./claude-custom --help
# Expected: Show help message
./claude-custom --version
# Expected: Show version "claude-custom 1.0.0"
./claude-custom invalid
# Expected: "Unknown command: invalid"
```

**Step 3: Commit**

```bash
git add claude-custom
git commit -m "feat: add claude-custom script skeleton with help and version"
```

---

## Task 2: Implement configuration management functions

**Files:**
- Modify: `claude-custom`

**Step 1: Add config initialization function**

Add after the color definitions:

```bash
# Initialize configuration directory and file
init_config() {
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
        echo -e "${GREEN}✓ Created config directory: $CONFIG_DIR${NC}"
    fi

    if [ ! -f "$CONFIG_FILE" ]; then
        echo '{"deployments":{}}' > "$CONFIG_FILE"
        echo -e "${GREEN}✓ Created config file: $CONFIG_FILE${NC}"
    fi
}
```

**Step 2: Add jq dependency check function**

```bash
# Ensure jq is installed
ensure_jq() {
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}jq is required but not installed.${NC}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "Install with: brew install jq"
        else
            echo "Install with: sudo apt-get install jq"
        fi
        read -p "Install now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                brew install jq
            else
                sudo apt-get install -y jq
            fi
            echo -e "${GREEN}✓ Installed jq${NC}"
        else
            echo -e "${RED}jq is required. Exiting.${NC}"
            exit 5
        fi
    fi
}
```

**Step 3: Add deployment existence check function**

```bash
# Check if a deployment exists
deployment_exists() {
    local name="$1"
    jq -e ".deployments.\"$name\"" "$CONFIG_FILE" &> /dev/null
}

# Get deployment config
get_deployment() {
    local name="$1"
    jq -r ".deployments.\"$name\"" "$CONFIG_FILE"
}
```

**Step 4: Test the functions**

```bash
# Test manually by sourcing and calling functions
# (These will be tested through integration in later tasks)
```

**Step 5: Commit**

```bash
git add claude-custom
git commit -m "feat: add config management and jq dependency functions"
```

---

## Task 3: Implement helper functions

**Files:**
- Modify: `claude-custom`

**Step 1: Add tool name normalization**

```bash
# Normalize tool name to ensure it starts with "claude-"
normalize_tool_name() {
    local name="$1"
    name=$(echo "$name" | xargs)
    if [[ ! "$name" =~ ^claude- ]]; then
        name="claude-$name"
    fi
    name=$(echo "$name" | sed 's/^claude-claude-/claude-/')
    echo "$name"
}

# Extract base name from tool name (remove claude- prefix)
get_tool_basename() {
    local name="$1"
    echo "$name" | sed 's/^claude-//'
}
```

**Step 2: Add URL validation**

```bash
# Validate URL format
validate_url() {
    local url="$1"
    if [[ ! "$url" =~ ^https?:// ]]; then
        echo -e "${RED}Error: URL must start with http:// or https://${NC}"
        return 1
    fi
    return 0
}
```

**Step 3: Add Claude Code installation check**

```bash
# Ensure Claude Code is installed
ensure_claude_code() {
    if [ ! -f "$CLAUDE_MODEL_DIR/node_modules/.bin/claude" ]; then
        echo -e "${YELLOW}Claude Code not found. Installing...${NC}"
        mkdir -p "$CLAUDE_MODEL_DIR"
        cd "$CLAUDE_MODEL_DIR"

        if [ ! -f "package.json" ]; then
            npm init -y > /dev/null 2>&1
        fi

        npm install @anthropic-ai/claude-code
        echo -e "${GREEN}✓ Installed Claude Code${NC}"
    fi
}
```

**Step 4: Add PATH configuration**

```bash
# Configure PATH for the user's shell
configure_path() {
    # Detect shell (reuse logic from deploy-claude-custom.sh)
    local detected_shell=""
    local shell_rc=""

    if [ -n "$SHELL" ]; then
        detected_shell=$(basename "$SHELL")
    fi

    if [ -z "$detected_shell" ] && command -v ps >/dev/null 2>&1; then
        detected_shell=$(ps -p $$ -o comm= 2>/dev/null | xargs basename 2>/dev/null || echo "")
    fi

    case "$detected_shell" in
        zsh)
            SHELL_RC="$HOME/.zshrc"
            ;;
        bash)
            if [[ "$OSTYPE" == "darwin"* ]]; then
                SHELL_RC="$HOME/.bash_profile"
                [ ! -f "$SHELL_RC" ] && SHELL_RC="$HOME/.bashrc"
            else
                SHELL_RC="$HOME/.bashrc"
                [ ! -f "$SHELL_RC" ] && SHELL_RC="$HOME/.bash_profile"
            fi
            ;;
        fish)
            SHELL_RC="$HOME/.config/fish/config.fish"
            ;;
        *)
            SHELL_RC="$HOME/.zshrc"
            ;;
    esac

    local path_line='export PATH="$HOME/claude-model/bin:$PATH"'

    if [ "$detected_shell" = "fish" ]; then
        path_line='set -gx PATH $HOME/claude-model/bin $PATH'
        mkdir -p "$(dirname "$SHELL_RC")"
    fi

    [ ! -f "$SHELL_RC" ] && touch "$SHELL_RC"

    if ! grep -q "claude-model/bin" "$SHELL_RC" 2>/dev/null; then
        echo "" >> "$SHELL_RC"
        echo "# Claude Custom Models" >> "$SHELL_RC"
        echo "$path_line" >> "$SHELL_RC"
        echo -e "${GREEN}✓ Added to PATH in $SHELL_RC${NC}"
        echo -e "${YELLOW}Run: source $SHELL_RC${NC}"
    fi
}
```

**Step 5: Commit**

```bash
git add claude-custom
git commit -m "feat: add helper functions for validation and PATH configuration"
```

---

## Task 4: Implement wrapper script generation

**Files:**
- Modify: `claude-custom`

**Step 1: Add wrapper script generation function**

```bash
# Write wrapper script for a deployment
write_wrapper_script() {
    local tool_name="$1"
    local api_key="$2"
    local base_url="$3"
    local model="$4"

    local script_path="$BIN_DIR/$tool_name"

    cat > "$script_path" << WRAPPER_EOF
#!/usr/bin/env bash
# Wrapper for Claude Code CLI using custom model API
# Generated by claude-custom
# Tool: $tool_name
# Model: $model

CLAUDE_BIN="\$HOME/claude-model/node_modules/.bin/claude"

# Check if Claude Code is installed
if [ ! -f "\$CLAUDE_BIN" ]; then
    echo "Error: Claude Code not found"
    echo "Please run: claude-custom add $tool_name"
    exit 1
fi

# Inject API credentials
export ANTHROPIC_AUTH_TOKEN="$api_key"
export ANTHROPIC_BASE_URL="$base_url"
export ANTHROPIC_MODEL="$model"

# Keep a separate config dir for this tool
export CLAUDE_CONFIG_DIR="\$HOME/claude-model/.$tool_name"

exec "\$CLAUDE_BIN" "\$@"
WRAPPER_EOF

    chmod +x "$script_path"
}
```

**Step 2: Test wrapper generation manually**

```bash
# Create test wrapper
mkdir -p ~/claude-model/bin
# The function will be tested when we implement the add command
```

**Step 3: Commit**

```bash
git add claude-custom
git commit -m "feat: add wrapper script generation function"
```

---

## Task 5: Implement `add` command

**Files:**
- Modify: `claude-custom`

**Step 1: Replace cmd_add stub with implementation**

```bash
cmd_add() {
    local tool_name=""
    local api_key=""
    local base_url=""
    local model=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --api-key|-k)
                api_key="$2"
                shift 2
                ;;
            --base-url|-u)
                base_url="$2"
                shift 2
                ;;
            --model|-m)
                model="$2"
                shift 2
                ;;
            *)
                if [ -z "$tool_name" ]; then
                    tool_name="$1"
                else
                    echo -e "${RED}Unknown option: $1${NC}"
                    exit 2
                fi
                shift
                ;;
        esac
    done

    # Initialize
    init_config
    ensure_jq
    ensure_claude_code

    # Get tool name
    if [ -z "$tool_name" ]; then
        read -p "Tool name: " tool_name
        if [ -z "$tool_name" ]; then
            echo -e "${RED}Error: Tool name is required${NC}"
            exit 2
        fi
    fi

    # Normalize tool name
    tool_name=$(normalize_tool_name "$tool_name")

    # Validate tool name
    if [[ ! "$tool_name" =~ ^claude-[a-zA-Z0-9-]+$ ]]; then
        echo -e "${RED}Error: Tool name must start with 'claude-' and contain only letters, numbers, and hyphens${NC}"
        exit 2
    fi

    # Check if deployment exists
    if deployment_exists "$tool_name"; then
        echo -e "${YELLOW}Deployment '$tool_name' already exists${NC}"
        read -p "Update instead? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cmd_update "$tool_name" --api-key "${api_key:-}" --base-url "${base_url:-}" --model "${model:-}"
            return
        else
            exit 1
        fi
    fi

    # Get API key
    if [ -z "$api_key" ]; then
        read -p "API Key: " api_key
        if [ -z "$api_key" ]; then
            echo -e "${RED}Error: API Key is required${NC}"
            exit 2
        fi
    fi

    # Get base URL
    if [ -z "$base_url" ]; then
        read -p "Base URL: " base_url
        if [ -z "$base_url" ]; then
            echo -e "${RED}Error: Base URL is required${NC}"
            exit 2
        fi
    fi

    # Validate URL
    if ! validate_url "$base_url"; then
        exit 2
    fi

    # Get model name
    if [ -z "$model" ]; then
        read -p "Model name: " model
        if [ -z "$model" ]; then
            echo -e "${RED}Error: Model name is required${NC}"
            exit 2
        fi
    fi

    # Create bin directory
    mkdir -p "$BIN_DIR"

    # Write wrapper script
    write_wrapper_script "$tool_name" "$api_key" "$base_url" "$model"

    # Save to config
    local basename=$(get_tool_basename "$tool_name")
    jq --arg name "$basename" \
       --arg api_key "$api_key" \
       --arg base_url "$base_url" \
       --arg model "$model" \
       '.deployments[$name] = {api_key: $api_key, base_url: $base_url, model: $model}' \
       "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && \
    mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

    # Configure PATH
    configure_path

    # Create tool config directory
    mkdir -p "$CLAUDE_MODEL_DIR/.$tool_name"

    echo -e "${GREEN}✓ Added $tool_name${NC}"
    echo "  Run: source ~/.zshrc  # or your shell config"
    echo "  Use: $tool_name"
}
```

**Step 2: Test the add command**

```bash
# Test with a mock deployment
./claude-custom add test-model --api-key test-key --base-url https://api.test.com/v1 --model test-model
# Expected: Success message

# Check config was created
cat ~/.claude-custom/config.json
# Expected: JSON with test-model deployment

# Check wrapper was created
ls -la ~/claude-model/bin/claude-test-model
# Expected: Executable wrapper script
```

**Step 3: Commit**

```bash
git add claude-custom
git commit -m "feat: implement add command with interactive prompts and validation"
```

---

## Task 6: Implement `list` command

**Files:**
- Modify: `claude-custom`

**Step 1: Replace cmd_list stub with implementation**

```bash
cmd_list() {
    init_config
    ensure_jq

    local count=$(jq '.deployments | length' "$CONFIG_FILE")

    if [ "$count" -eq 0 ]; then
        echo -e "${YELLOW}No deployments found${NC}"
        echo ""
        echo "Add a deployment with:"
        echo "  claude-custom add <name>"
        return
    fi

    echo "Deployed Models:"
    echo ""
    printf "  %-20s %-40s %s\n" "NAME" "BASE URL" "MODEL"
    echo "  ──────────────────── ──────────────────────────────────────── ─────────────────"

    jq -r '.deployments | to_entries[] | @text "  \(.key |.[0:20]) \(.value.base_url |.[0:40]) \(.value.model |.[0:30])"' "$CONFIG_FILE" | while read -r line; do
        echo "$line"
    done

    echo ""
    echo "Total: $count deployment(s)"
}
```

**Step 2: Test the list command**

```bash
# After adding test deployments
./claude-custom list
# Expected: Table showing deployments

# Test with empty config
jq '.deployments = {}' ~/.claude-custom/config.json > /tmp/empty.json && mv /tmp/empty.json ~/.claude-custom/config.json
./claude-custom list
# Expected: "No deployments found"
```

**Step 3: Commit**

```bash
git add claude-custom
git commit -m "feat: implement list command with table output"
```

---

## Task 7: Implement `remove` command

**Files:**
- Modify: `claude-custom`

**Step 1: Replace cmd_remove stub with implementation**

```bash
cmd_remove() {
    local tool_name="$1"

    if [ -z "$tool_name" ]; then
        echo -e "${RED}Error: Tool name is required${NC}"
        echo "Usage: claude-custom remove <name>"
        exit 2
    fi

    init_config
    ensure_jq

    # Normalize tool name
    tool_name=$(normalize_tool_name "$tool_name")
    local basename=$(get_tool_basename "$tool_name")

    # Check if deployment exists
    if ! deployment_exists "$basename"; then
        echo -e "${RED}Error: Deployment '$tool_name' not found${NC}"
        echo ""
        echo "Run 'claude-custom list' to see available deployments"
        exit 1
    fi

    # Confirm removal
    read -p "Remove $tool_name? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi

    # Remove wrapper script
    local wrapper_path="$BIN_DIR/$tool_name"
    if [ -f "$wrapper_path" ]; then
        rm -f "$wrapper_path"
        echo -e "${GREEN}✓ Removed wrapper script${NC}"
    fi

    # Remove config directory
    local config_path="$CLAUDE_MODEL_DIR/.$tool_name"
    if [ -d "$config_path" ]; then
        rm -rf "$config_path"
        echo -e "${GREEN}✓ Removed config directory${NC}"
    fi

    # Remove from config
    jq --arg name "$basename" 'del(.deployments[$name])' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && \
    mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

    echo -e "${GREEN}✓ Removed $tool_name${NC}"
}
```

**Step 2: Test the remove command**

```bash
# Add a test deployment first
./claude-custom add test-remove --api-key test --base-url https://test.com/v1 --model test

# Then remove it
./claude-custom remove test-remove
# Expected: Confirmation prompt, then success message

# Verify it's gone
./claude-custom list
# Expected: test-remove not in list
```

**Step 3: Commit**

```bash
git add claude-custom
git commit -m "feat: implement remove command with confirmation"
```

---

## Task 8: Implement `update` command

**Files:**
- Modify: `claude-custom`

**Step 1: Replace cmd_update stub with implementation**

```bash
cmd_update() {
    local tool_name=""
    local new_api_key=""
    local new_base_url=""
    local new_model=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --api-key|-k)
                new_api_key="$2"
                shift 2
                ;;
            --base-url|-u)
                new_base_url="$2"
                shift 2
                ;;
            --model|-m)
                new_model="$2"
                shift 2
                ;;
            *)
                if [ -z "$tool_name" ]; then
                    tool_name="$1"
                else
                    echo -e "${RED}Unknown option: $1${NC}"
                    exit 2
                fi
                shift
                ;;
        esac
    done

    if [ -z "$tool_name" ]; then
        echo -e "${RED}Error: Tool name is required${NC}"
        echo "Usage: claude-custom update <name> [options]"
        exit 2
    fi

    init_config
    ensure_jq

    # Normalize tool name
    tool_name=$(normalize_tool_name "$tool_name")
    local basename=$(get_tool_basename "$tool_name")

    # Check if deployment exists
    if ! deployment_exists "$basename"; then
        echo -e "${RED}Error: Deployment '$tool_name' not found${NC}"
        echo ""
        echo "Run 'claude-custom list' to see available deployments"
        echo "Or use 'claude-custom add' to create a new deployment"
        exit 1
    fi

    # Get current config
    local current_api_key=$(jq -r ".deployments.\"$basename\".api_key" "$CONFIG_FILE")
    local current_base_url=$(jq -r ".deployments.\"$basename\".base_url" "$CONFIG_FILE")
    local current_model=$(jq -r ".deployments.\"$basename\".model" "$CONFIG_FILE")

    # Prompt for values to update
    if [ -z "$new_api_key" ]; then
        read -p "API Key [$current_api_key]: " new_api_key
        new_api_key="${new_api_key:-$current_api_key}"
    fi

    if [ -z "$new_base_url" ]; then
        read -p "Base URL [$current_base_url]: " new_base_url
        new_base_url="${new_base_url:-$current_base_url}"
    fi

    if [ -z "$new_model" ]; then
        read -p "Model [$current_model]: " new_model
        new_model="${new_model:-$current_model}"
    fi

    # Validate URL if changed
    if [ "$new_base_url" != "$current_base_url" ]; then
        if ! validate_url "$new_base_url"; then
            exit 2
        fi
    fi

    # Update config
    jq --arg name "$basename" \
       --arg api_key "$new_api_key" \
       --arg base_url "$new_base_url" \
       --arg model "$new_model" \
       '.deployments[$name] = {api_key: $api_key, base_url: $base_url, model: $model}' \
       "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && \
    mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

    # Rewrite wrapper script
    write_wrapper_script "$tool_name" "$new_api_key" "$new_base_url" "$new_model"

    echo -e "${GREEN}✓ Updated $tool_name${NC}"
}
```

**Step 2: Test the update command**

```bash
# Add a deployment first
./claude-custom add test-update --api-key old-key --base-url https://old.com/v1 --model old-model

# Update it
./claude-custom update test-update --api-key new-key
# Expected: Updated with new API key

# Or update interactively
./claude-custom update test-update
# Expected: Prompts for each field
```

**Step 3: Commit**

```bash
git add claude-custom
git commit -m "feat: implement update command with interactive prompts"
```

---

## Task 9: Implement `migrate` command

**Files:**
- Modify: `claude-custom`

**Step 1: Replace cmd_migrate stub with implementation**

```bash
cmd_migrate() {
    init_config
    ensure_jq

    # Find existing wrappers
    local wrappers=()
    if [ -d "$BIN_DIR" ]; then
        while IFS= read -r -d '' wrapper; do
            wrappers+=("$wrapper")
        done < <(find "$BIN_DIR" -name "claude-*" -type f -print0 2>/dev/null)
    fi

    if [ ${#wrappers[@]} -eq 0 ]; then
        echo -e "${YELLOW}No existing deployments found to migrate${NC}"
        echo ""
        echo "Add a deployment with:"
        echo "  claude-custom add <name>"
        return
    fi

    echo "Scanning for existing deployments..."
    echo ""

    local to_import=()

    for wrapper in "${wrappers[@]}"; do
        local name=$(basename "$wrapper" | sed 's/^claude-//')

        # Skip if already in config
        if deployment_exists "$name"; then
            continue
        fi

        # Extract values from wrapper
        local api_key=$(grep "export ANTHROPIC_AUTH_TOKEN=" "$wrapper" | cut -d'"' -f2)
        local base_url=$(grep "export ANTHROPIC_BASE_URL=" "$wrapper" | cut -d'"' -f2)
        local model=$(grep "export ANTHROPIC_MODEL=" "$wrapper" | cut -d'"' -f2)

        # Validate we got the values
        if [ -n "$api_key" ] && [ -n "$base_url" ] && [ -n "$model" ]; then
            echo "  - claude-$name"
            to_import+=("$name|$api_key|$base_url|$model")
        fi
    done

    if [ ${#to_import[@]} -eq 0 ]; then
        echo "No new deployments to migrate."
        return
    fi

    echo ""
    read -p "Import these deployments? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        return
    fi

    # Import each deployment
    for entry in "${to_import[@]}"; do
        IFS='|' read -r name api_key base_url model <<< "$entry"

        jq --arg name "$name" \
           --arg api_key "$api_key" \
           --arg base_url "$base_url" \
           --arg model "$model" \
           '.deployments[$name] = {api_key: $api_key, base_url: $base_url, model: $model}' \
           "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && \
        mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

        echo -e "${GREEN}✓ Imported claude-$name${NC}"
    done

    echo ""
    echo "All deployments migrated!"
    echo "Run 'claude-custom list' to see your deployments."
}
```

**Step 2: Test the migrate command**

```bash
# First create an old-style wrapper manually to test
mkdir -p ~/claude-model/bin
cat > ~/claude-model/bin/claude-old-test << 'EOF'
#!/usr/bin/env bash
export ANTHROPIC_AUTH_TOKEN="test-key"
export ANTHROPIC_BASE_URL="https://test.com/v1"
export ANTHROPIC_MODEL="test-model"
exec ~/claude-model/node_modules/.bin/claude "$@"
EOF
chmod +x ~/claude-model/bin/claude-old-test

# Run migrate
./claude-custom migrate
# Expected: Finds and imports old-test

# Verify
./claude-custom list
# Expected: old-test in the list
```

**Step 3: Commit**

```bash
git add claude-custom
git commit -m "feat: implement migrate command to import existing deployments"
```

---

## Task 10: Create install.sh script

**Files:**
- Create: `install.sh`

**Step 1: Write the installer**

```bash
#!/usr/bin/env bash
# Claude Custom Manager Installer
# Usage: curl -fsSL https://.../install.sh | sudo bash

set -e

REPO="${REPO:-SSBun/deploy-custom-claude-code}"
BRANCH="${BRANCH:-main}"
SCRIPT_URL="https://raw.githubusercontent.com/$REPO/$BRANCH/claude-custom"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="$HOME/.claude-custom"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Claude Custom Manager Installer ==="
echo ""

# Check for sudo
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Error: Please run with sudo${NC}"
  echo "  sudo curl -fsSL https://raw.githubusercontent.com/$REPO/$BRANCH/install.sh | bash"
  exit 4
fi

# Download claude-custom
echo -e "${YELLOW}Downloading claude-custom...${NC}"
if ! curl -fsSL "$SCRIPT_URL" -o "$INSTALL_DIR/claude-custom"; then
    echo -e "${RED}Error: Failed to download claude-custom${NC}"
    exit 1
fi
chmod +x "$INSTALL_DIR/claude-custom"
echo -e "${GREEN}✓ Installed to $INSTALL_DIR/claude-custom${NC}"

# Create config directory
if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR"
    echo -e "${GREEN}✓ Created config directory: $CONFIG_DIR${NC}"
fi

# Check for jq
if ! command -v jq &> /dev/null; then
    echo ""
    echo -e "${YELLOW}jq is required but not installed.${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Install with: brew install jq"
    else
        echo "Install with: sudo apt-get install jq"
    fi
    echo -e "${YELLOW}Please install jq, then run: claude-custom --help${NC}"
else
    echo -e "${GREEN}✓ jq is installed${NC}"
fi

echo ""
echo -e "${GREEN}=== Installation Complete! ===${NC}"
echo ""
echo "Run: claude-custom --help"
echo "Add a deployment: claude-custom add <name>"
```

**Step 2: Make executable and test**

```bash
chmod +x install.sh

# Test with sudo (will download from GitHub)
# For local testing, we can simulate:
sudo bash -c 'REPO="" SCRIPT_URL="./claude-custom" bash install.sh'
```

**Step 3: Commit**

```bash
git add install.sh
git commit -m "feat: add one-line installer script for claude-custom"
```

---

## Task 11: Update README.md

**Files:**
- Modify: `README.md`

**Step 1: Add new installation method at the top**

Add after the title, before "## Features":

```markdown
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
```

**Step 2: Add claude-custom usage section**

Add new section after "## Quick Start":

```markdown
## Using claude-custom

The `claude-custom` tool allows you to manage multiple custom Claude deployments easily.

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

# Migrate existing deployments
claude-custom migrate
```

### Examples

```bash
# Interactive add
claude-custom add doubao

# Non-interactive add
claude-custom add glm --api-key YOUR_KEY --base-url https://open.bigmodel.cn/api/paas/v4 --model glm-4-6

# List all
claude-custom list

# Update API key
claude-custom update doubao --api-key NEW_KEY

# Remove
claude-custom remove glm
```
```

**Step 3: Mark legacy script as "Alternative Method"

Update the section heading from "## Quick Start" to "## Alternative: Direct Deployment Script"

**Step 4: Commit**

```bash
git add README.md
git commit -m "docs: update README with claude-custom installation and usage"
```

---

## Task 12: Add first-run detection for migration

**Files:**
- Modify: `claude-custom`

**Step 1: Add detection in main()**

Add at the start of main(), after the command parsing:

```bash
# Check if this is first run and migrations are available
first_run_check() {
    # Only check for non-help commands
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--version" ]] || [[ "$1" == "-v" ]]; then
        return
    fi

    init_config
    ensure_jq

    # Check if config is empty
    local count=$(jq '.deployments | length' "$CONFIG_FILE")
    if [ "$count" -gt 0 ]; then
        return  # Already has deployments
    fi

    # Check for existing wrappers
    if [ -d "$BIN_DIR" ]; then
        local wrapper_count=$(find "$BIN_DIR" -name "claude-*" -type f 2>/dev/null | wc -l)
        if [ "$wrapper_count" -gt 0 ]; then
            echo ""
            echo -e "${YELLOW}No claude-custom configuration found, but $wrapper_count existing deployment(s) detected.${NC}"
            echo ""
            echo "Run 'claude-custom migrate' to import your existing deployments."
            echo ""
        fi
    fi
}

# Call first-run check at start of main
first_run_check "$command"
```

**Step 2: Test the detection**

```bash
# With empty config and existing wrapper
./claude-custom list
# Expected: Suggestion to migrate

# After migrate
./claude-custom list
# Expected: No suggestion (migrations done)
```

**Step 3: Commit**

```bash
git add claude-custom
git commit -m "feat: add first-run detection to suggest migration"
```

---

## Task 13: Add per-command help

**Files:**
- Modify: `claude-custom`

**Step 1: Add help functions for each command**

```bash
# Add these after show_version()

show_add_help() {
    cat << EOF
Add a new custom model deployment

Usage: claude-custom add <name> [options]

Arguments:
  name              Name for the deployment (will be prefixed with 'claude-')

Options:
  --api-key, -k     API key for the model provider
  --base-url, -u    Base URL for the API endpoint
  --model, -m       Model name/identifier

Examples:
  claude-custom add doubao
  claude-custom add glm --api-key KEY --base-url URL --model glm-4-6

Common Model Configurations:
  Doubao:   --base-url https://ark.cn-beijing.volces.com/api/coding --model doubao-seed-code-preview-latest
  GLM:      --base-url https://open.bigmodel.cn/api/paas/v4 --model glm-4-6
  MiniMax:  --base-url https://api.minimax.chat/v1 --model abab6.5s-chat
EOF
}

show_remove_help() {
    cat << EOF
Remove a deployment

Usage: claude-custom remove <name>

Arguments:
  name              Name of the deployment to remove

Example:
  claude-custom remove doubao
EOF
}

show_list_help() {
    cat << EOF
List all deployments

Usage: claude-custom list

Shows all deployed custom models with their configuration.
EOF
}

show_update_help() {
    cat << EOF
Update a deployment configuration

Usage: claude-custom update <name> [options]

Arguments:
  name              Name of the deployment to update

Options:
  --api-key, -k     New API key
  --base-url, -u    New base URL
  --model, -m       New model name

If an option is not provided, you will be prompted for a value.

Example:
  claude-custom update doubao --api-key NEW_KEY
EOF
}

show_migrate_help() {
    cat << EOF
Import existing deployments

Usage: claude-custom migrate

Scans for deployments created by deploy-claude-custom.sh and imports
them into the claude-custom configuration.
EOF
}
```

**Step 2: Update each cmd_* function to handle --help**

Add at the start of each command function:

```bash
cmd_add() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        show_add_help
        return
    fi
    # ... rest of function
}
```

Repeat for cmd_remove, cmd_list, cmd_update, cmd_migrate.

**Step 3: Test help commands**

```bash
./claude-custom add --help
./claude-custom remove --help
./claude-custom list --help
./claude-custom update --help
./claude-custom migrate --help
```

**Step 4: Commit**

```bash
git add claude-custom
git commit -m "feat: add per-command help documentation"
```

---

## Task 14: Update AGENTS.md

**Files:**
- Modify: `AGENTS.md`

**Step 1: Add section about the new claude-custom tool**

Add after "## Project Structure":

```markdown
### New Architecture (claude-custom)

The recommended way to manage deployments is via the `claude-custom` CLI tool:

```
/usr/local/bin/claude-custom    # Main manager CLI
~/.claude-custom/config.json    # Deployment registry
~/claude-model/bin/claude-*     # Generated wrapper scripts
```

The `claude-custom` command is installed once, then used to add/remove/list/update deployments.
```

**Step 2: Add reference to new files**

Update the "Important Files" table:

| File | Purpose |
|------|---------|
| `claude-custom` | Main CLI manager (new) |
| `install.sh` | One-line installer for claude-custom (new) |
| `deploy-claude-custom.sh` | Legacy single-deployment script |
| `README.md` | User-facing documentation |
| `AGENTS.md` | This file - agent guidance |

**Step 3: Commit**

```bash
git add AGENTS.md
git commit -m "docs: update AGENTS.md with claude-custom architecture"
```

---

## Task 15: Final integration testing and cleanup

**Files:**
- All

**Step 1: Run full integration test**

```bash
# Clean state
rm -rf ~/.claude-custom
rm -rf ~/claude-model

# Test add
./claude-custom add test1 --api-key key1 --base-url https://api1.com/v1 --model model1
./claude-custom add test2 --api-key key2 --base-url https://api2.com/v1 --model model2

# Test list
./claude-custom list

# Test update
./claude-custom update test1 --api-key newkey1

# Test remove
./claude-custom remove test2

# Test list again
./claude-custom list

# Verify wrapper scripts exist and are executable
ls -la ~/claude-model/bin/
cat ~/claude-model/bin/claude-test1
```

**Step 2: Test migration path**

```bash
# Create old-style wrapper
mkdir -p ~/claude-model/bin
cat > ~/claude-model/bin/claude-old << 'EOF'
#!/usr/bin/env bash
export ANTHROPIC_AUTH_TOKEN="old-key"
export ANTHROPIC_BASE_URL="https://old.com/v1"
export ANTHROPIC_MODEL="old-model"
exec ~/claude-model/node_modules/.bin/claude "$@"
EOF
chmod +x ~/claude-model/bin/claude-old

# Test migrate
./claude-custom migrate

# Verify import
./claude-custom list
cat ~/.claude-custom/config.json
```

**Step 3: Test error handling**

```bash
# Test duplicate add
./claude-custom add test1 --api-key key1 --base-url https://api1.com/v1 --model model1
# Should offer to update

# Test remove non-existent
./claude-custom remove nonexistent
# Should show error

# Test invalid URL
./claude-custom add bad --api-key key --base-url not-a-url --model model
# Should show validation error
```

**Step 4: Final commit**

```bash
git add -A
git commit -m "test: complete integration testing and cleanup"
```

---

## Task 16: Create git tag for release

**Files:**
- None (git operation)

**Step 1: Tag the release**

```bash
git tag -a v1.0.0 -m "Release claude-custom manager v1.0.0

Features:
- Add/remove/list/update/migrate custom Claude deployments
- One-line installation via install.sh
- Interactive and non-interactive modes
- Automatic PATH configuration
- Migration from legacy deployments"
```

**Step 2: Push to remote**

```bash
git push origin main --tags
```

---

## Summary

This implementation plan creates a complete `claude-custom` CLI tool with:

1. **Installation** - One-line curl install to `/usr/local/bin`
2. **Commands** - add, remove, list, update, migrate
3. **Configuration** - JSON-based state in `~/.claude-custom/config.json`
4. **Compatibility** - Migrates existing deployments from legacy script
5. **UX** - Interactive prompts, validation, helpful error messages
6. **Documentation** - Updated README and AGENTS.md

The plan follows TDD principles with bite-sized tasks, each commiting independently for easy rollback and review.
