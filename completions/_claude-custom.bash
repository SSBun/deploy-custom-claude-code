#!/usr/bin/env bash
# bash/zsh completion script for claude-custom wrapper tools
# Usage: source this file or place in bash_completion.d

_claude_complete() {
    local cur prev words cword split
    _init_completion -n =: || return

    local CONFIG_DIR="$HOME/.claude-custom"
    local CONFIG_FILE="$CONFIG_DIR/config.json"
    local BIN_DIR="$CONFIG_DIR/bin"

    case $prev in
        --use-model|-m)
            # Complete with available models from current deployment
            if [[ -f "$CONFIG_FILE" ]]; then
                # Extract deployment basename from command (e.g., 'claude-glm' -> 'glm')
                local cmd_base="${COMP_WORDS[0]//claude-/}"

                # Get models for this deployment
                local models
                models=$(jq -r --arg name "$cmd_base" '.deployments[$name].models[]? // .deployments[$name].model // empty' "$CONFIG_FILE" 2>/dev/null)

                if [[ -n "$models" ]]; then
                    COMPREPLY=( $(compgen -W "$models" -- "$cur") )
                fi
            fi
            return 0
            ;;
    esac

    # Complete claude-* wrapper commands
    if [[ ${cur} == claude-* ]]; then
        COMPREPLY=( $(compgen -W "$(ls "$BIN_DIR"/claude-* 2>/dev/null | sed 's|.*/||')" -- "$cur") )
        return 0
    fi

    # Standard options
    local opts="--use-model --help"
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}

# Register for all claude-* commands
complete -F _claude_complete claude-
