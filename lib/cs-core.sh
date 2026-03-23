# cs-core.sh - Claude Code Provider Switcher Core Functions
# Source this file in your shell rc file (.bashrc or .zshrc)

CS_HOME="${HOME}/.cs"
PROVIDERS_DIR="${CS_HOME}/providers"

# Save current environment variables to restore later
_cs_save_env() {
    CS_SAVED_ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}"
    CS_SAVED_ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL:-}"
    CS_SAVED_ANTHROPIC_AUTH_TOKEN="${ANTHROPIC_AUTH_TOKEN:-}"
    CS_SAVED_ANTHROPIC_MODEL="${ANTHROPIC_MODEL:-}"
    CS_SAVED_ANTHROPIC_SMALL_FAST_MODEL="${ANTHROPIC_SMALL_FAST_MODEL:-}"
    CS_SAVED_ANTHROPIC_DEFAULT_SONNET_MODEL="${ANTHROPIC_DEFAULT_SONNET_MODEL:-}"
    CS_SAVED_ANTHROPIC_DEFAULT_OPUS_MODEL="${ANTHROPIC_DEFAULT_OPUS_MODEL:-}"
    CS_SAVED_ANTHROPIC_DEFAULT_HAIKU_MODEL="${ANTHROPIC_DEFAULT_HAIKU_MODEL:-}"
    CS_SAVED_OPENAI_API_KEY="${OPENAI_API_KEY:-}"
    CS_SAVED_OPENAI_BASE_URL="${OPENAI_BASE_URL:-}"
    CS_SAVED_OPENAI_MODEL="${OPENAI_MODEL:-}"
}

# Restore saved environment variables
_cs_restore_env() {
    if [[ -n "${CS_SAVED_ANTHROPIC_BASE_URL+x}" ]]; then
        export ANTHROPIC_BASE_URL="${CS_SAVED_ANTHROPIC_BASE_URL}"
    else
        unset ANTHROPIC_BASE_URL
    fi

    if [[ -n "${CS_SAVED_ANTHROPIC_API_KEY+x}" ]]; then
        export ANTHROPIC_API_KEY="${CS_SAVED_ANTHROPIC_API_KEY}"
    else
        unset ANTHROPIC_API_KEY
    fi

    if [[ -n "${CS_SAVED_ANTHROPIC_AUTH_TOKEN+x}" ]]; then
        export ANTHROPIC_AUTH_TOKEN="${CS_SAVED_ANTHROPIC_AUTH_TOKEN}"
    else
        unset ANTHROPIC_AUTH_TOKEN
    fi

    if [[ -n "${CS_SAVED_ANTHROPIC_MODEL+x}" ]]; then
        export ANTHROPIC_MODEL="${CS_SAVED_ANTHROPIC_MODEL}"
    else
        unset ANTHROPIC_MODEL
    fi

    if [[ -n "${CS_SAVED_ANTHROPIC_SMALL_FAST_MODEL+x}" ]]; then
        export ANTHROPIC_SMALL_FAST_MODEL="${CS_SAVED_ANTHROPIC_SMALL_FAST_MODEL}"
    else
        unset ANTHROPIC_SMALL_FAST_MODEL
    fi

    if [[ -n "${CS_SAVED_ANTHROPIC_DEFAULT_SONNET_MODEL+x}" ]]; then
        export ANTHROPIC_DEFAULT_SONNET_MODEL="${CS_SAVED_ANTHROPIC_DEFAULT_SONNET_MODEL}"
    else
        unset ANTHROPIC_DEFAULT_SONNET_MODEL
    fi

    if [[ -n "${CS_SAVED_ANTHROPIC_DEFAULT_OPUS_MODEL+x}" ]]; then
        export ANTHROPIC_DEFAULT_OPUS_MODEL="${CS_SAVED_ANTHROPIC_DEFAULT_OPUS_MODEL}"
    else
        unset ANTHROPIC_DEFAULT_OPUS_MODEL
    fi

    if [[ -n "${CS_SAVED_ANTHROPIC_DEFAULT_HAIKU_MODEL+x}" ]]; then
        export ANTHROPIC_DEFAULT_HAIKU_MODEL="${CS_SAVED_ANTHROPIC_DEFAULT_HAIKU_MODEL}"
    else
        unset ANTHROPIC_DEFAULT_HAIKU_MODEL
    fi

    if [[ -n "${CS_SAVED_OPENAI_API_KEY+x}" ]]; then
        export OPENAI_API_KEY="${CS_SAVED_OPENAI_API_KEY}"
    else
        unset OPENAI_API_KEY
    fi

    if [[ -n "${CS_SAVED_OPENAI_BASE_URL+x}" ]]; then
        export OPENAI_BASE_URL="${CS_SAVED_OPENAI_BASE_URL}"
    else
        unset OPENAI_BASE_URL
    fi

    if [[ -n "${CS_SAVED_OPENAI_MODEL+x}" ]]; then
        export OPENAI_MODEL="${CS_SAVED_OPENAI_MODEL}"
    else
        unset OPENAI_MODEL
    fi
}

# Clear all provider-related environment variables
_cs_clear_env() {
    unset ANTHROPIC_API_KEY
    unset ANTHROPIC_BASE_URL
    unset ANTHROPIC_AUTH_TOKEN
    unset ANTHROPIC_MODEL
    unset ANTHROPIC_SMALL_FAST_MODEL
    unset ANTHROPIC_DEFAULT_SONNET_MODEL
    unset ANTHROPIC_DEFAULT_OPUS_MODEL
    unset ANTHROPIC_DEFAULT_HAIKU_MODEL
    unset OPENAI_API_KEY
    unset OPENAI_BASE_URL
    unset OPENAI_MODEL
}

# Get provider name from .cs file in current directory or any parent directory
_cs_get_provider_from_file() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/.cs" ]]; then
            cat "$dir/.cs" 2>/dev/null | tr -d '[:space:]'
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

# Check if current directory is under the given path
_cs_is_under_dir() {
    local parent="$1"
    local current="$PWD"

    # Normalize paths
    parent="${parent%/}"
    current="${current%/}"

    # Check if current starts with parent/
    [[ "$current" == "$parent" ]] || [[ "$current" == "$parent/"* ]]
}

# Load provider configuration
_cs_load_provider() {
    local provider="$1"
    local config_file="${PROVIDERS_DIR}/${provider}.env"

    if [[ -f "$config_file" ]]; then
        source "$config_file"
        export CS_PROVIDER="$provider"
        return 0
    else
        return 1
    fi
}

# Main directory change hook
cs_load_from_file() {
    # Get the current directory's provider (from current dir or any parent)
    local current_provider=$(_cs_get_provider_from_file)

    # If we have a provider from a parent .cs file
    if [[ -n "$current_provider" ]]; then
        # If provider changed, load it
        if [[ "$CS_PROVIDER" != "$current_provider" ]]; then
            # Save current environment before loading new one (only if not already saved)
            if [[ -z "$CS_LAST_PROVIDER" ]]; then
                _cs_save_env
            fi

            # Clear and load new provider
            _cs_clear_env
            if _cs_load_provider "$current_provider"; then
                export CS_LAST_PROVIDER="$current_provider"
                export CS_LAST_DIR="$PWD"
                echo "🤖 Provider: $current_provider"
            else
                echo "⚠️  Provider '$current_provider' not found"
                _cs_restore_env
                unset CS_LAST_PROVIDER
                unset CS_LAST_DIR
            fi
        fi
        return 0
    fi

    # No .cs file in current dir or parents
    # If we had a provider before, check if we left the project tree
    if [[ -n "$CS_LAST_PROVIDER" ]]; then
        # Check if we're still under the last project directory
        if ! _cs_is_under_dir "$CS_LAST_DIR"; then
            # Completely left the project, restore environment
            _cs_restore_env
            unset CS_PROVIDER
            unset CS_LAST_PROVIDER
            unset CS_LAST_DIR
            echo "🤖 Restored previous environment (left project directory)"
        fi
    fi
}

# Main cs command function
cs() {
    local cmd="$1"
    local arg="$2"

    case "$cmd" in
        -l|--list)
            _cs_list
            ;;
        -c|--current)
            _cs_current
            ;;
        -e|--edit)
            _cs_edit "$arg"
            ;;
        -a|--add)
            _cs_add "$arg"
            ;;
        -d|--delete)
            _cs_delete "$arg"
            ;;
        -h|--help|"")
            _cs_help
            ;;
        -*)
            echo "❌ Unknown option: $cmd"
            _cs_help
            return 1
            ;;
        *)
            _cs_switch "$cmd"
            ;;
    esac
}

_cs_help() {
    echo "cs - Claude Code Provider Switcher"
    echo ""
    echo "Usage:"
    echo "  cs <provider>       Switch to provider"
    echo "  cs -l               List all providers"
    echo "  cs -c               Show current provider"
    echo "  cs -e <provider>    Edit provider config"
    echo "  cs -a <provider>    Add new provider"
    echo "  cs -d <provider>    Delete provider"
    echo "  cs -h               Show this help"
}

_cs_list() {
    if [[ ! -d "$PROVIDERS_DIR" ]]; then
        echo "❌ Providers directory not found: $PROVIDERS_DIR"
        return 1
    fi

    echo "Available providers:"
    local has_provider=false
    for f in "$PROVIDERS_DIR"/*.env; do
        if [[ -f "$f" ]]; then
            has_provider=true
            local name=$(basename "$f" .env)
            local current=""
            [[ "$name" == "$CS_PROVIDER" ]] && current=" *"
            echo "  $name$current"
        fi
    done

    if [[ "$has_provider" == false ]]; then
        echo "  (none)"
    fi
}

_cs_current() {
    if [[ -n "$CS_PROVIDER" ]]; then
        echo "Current provider: $CS_PROVIDER"
    else
        echo "No provider set (using official Claude)"
    fi
}

_cs_edit() {
    local provider="$1"
    if [[ -z "$provider" ]]; then
        echo "❌ Please specify provider name"
        return 1
    fi

    local config_file="${PROVIDERS_DIR}/${provider}.env"
    if [[ ! -f "$config_file" ]]; then
        echo "❌ Provider '$provider' not found. Run 'cs -l' to list."
        return 1
    fi

    ${EDITOR:-vi} "$config_file"
}

_cs_add() {
    local provider="$1"
    if [[ -z "$provider" ]]; then
        echo "❌ Please specify provider name"
        return 1
    fi

    local config_file="${PROVIDERS_DIR}/${provider}.env"
    if [[ -f "$config_file" ]]; then
        echo "❌ Provider '$provider' already exists."
        return 1
    fi

    cat > "$config_file" << 'EOF'
# Provider configuration
# Uncomment and modify as needed:

# For Anthropic/Claude compatible APIs:
# export ANTHROPIC_BASE_URL=https://api.example.com/anthropic
# export ANTHROPIC_AUTH_TOKEN=your_token_here

# For OpenAI compatible APIs:
# export OPENAI_API_KEY=your_key_here
# export OPENAI_BASE_URL=https://api.example.com/v1
# export OPENAI_MODEL=gpt-4o

# Clean up conflicting variables:
# unset OPENAI_API_KEY
# unset ANTHROPIC_AUTH_TOKEN
EOF

    echo "✅ Created: $config_file"
    ${EDITOR:-vi} "$config_file"
}

_cs_delete() {
    local provider="$1"
    if [[ -z "$provider" ]]; then
        echo "❌ Please specify provider name"
        return 1
    fi

    local config_file="${PROVIDERS_DIR}/${provider}.env"
    if [[ ! -f "$config_file" ]]; then
        echo "❌ Provider '$provider' not found."
        return 1
    fi

    read -p "Delete '$provider'? [y/N] " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        rm "$config_file"
        echo "✅ Deleted: $provider"
    fi
}

_cs_switch() {
    local provider="$1"
    local config_file="${PROVIDERS_DIR}/${provider}.env"

    if [[ ! -f "$config_file" ]]; then
        echo "❌ Provider '$provider' not found. Run 'cs -l' to list."
        return 1
    fi

    # If already on this provider, just confirm
    if [[ "$CS_PROVIDER" == "$provider" ]]; then
        echo "✅ Already using $provider"
        return 0
    fi

    # Clear current environment and load new provider
    _cs_clear_env
    source "$config_file"
    export CS_PROVIDER="$provider"

    # Save to .cs file if in a project directory
    if [[ -d ".git" ]] || [[ -f "package.json" ]] || [[ -f "README.md" ]] || [[ -f "Cargo.toml" ]] || [[ -f "go.mod" ]]; then
        echo "$provider" > .cs
        echo "✅ Switched to $provider (saved to .cs)"
    else
        echo "✅ Switched to $provider"
    fi
}

# Zsh chpwd hook - compatible with all zsh versions
if [[ -n "${ZSH_VERSION:-}" ]]; then
    # Method 1: Try autoload + add-zsh-hook (modern zsh)
    if autoload -U add-zsh-hook 2>/dev/null; then
        if type add-zsh-hook >/dev/null 2>&1; then
            add-zsh-hook chpwd cs_load_from_file
        fi
    # Method 2: Use chpwd_functions array (all zsh versions)
    elif type chpwd >/dev/null 2>&1 || [[ -n "${chpwd_functions+x}" ]]; then
        # Add to chpwd_functions array if not already present
        if [[ "${chpwd_functions[*]}" != *"cs_load_from_file"* ]]; then
            chpwd_functions+=(cs_load_from_file)
        fi
    fi
    # Run on shell startup
    cs_load_from_file
fi

# Bash PROMPT_COMMAND hook
if [[ -n "${BASH_VERSION:-}" ]]; then
    cs_chpwd_hook() {
        # Track current directory to detect changes
        if [[ "$CS_LAST_PWD" != "$PWD" ]]; then
            export CS_LAST_PWD="$PWD"
            cs_load_from_file
        fi
    }

    # Append to PROMPT_COMMAND if not already present
    if [[ "$PROMPT_COMMAND" != *"cs_chpwd_hook"* ]]; then
        PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }cs_chpwd_hook"
    fi

    # Run on shell startup
    cs_chpwd_hook
fi

# Ensure cs command is in PATH
if [[ ":$PATH:" != *":${CS_HOME}/bin:"* ]]; then
    export PATH="${CS_HOME}/bin:$PATH"
fi
