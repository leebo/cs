# cs-core.fish - Claude Code Provider Switcher (Fish shell)
# Source this file from ~/.config/fish/config.fish

set -gx CS_HOME "$HOME/.cs"
set -gx CS_PROVIDERS_DIR "$CS_HOME/providers"

# Ensure cs bin is in PATH
if not contains "$CS_HOME/bin" $PATH
    set -gx PATH "$CS_HOME/bin" $PATH
end

function _cs_clear_env
    set -e ANTHROPIC_API_KEY
    set -e ANTHROPIC_BASE_URL
    set -e ANTHROPIC_AUTH_TOKEN
    set -e ANTHROPIC_MODEL
    set -e ANTHROPIC_SMALL_FAST_MODEL
    set -e ANTHROPIC_DEFAULT_SONNET_MODEL
    set -e ANTHROPIC_DEFAULT_OPUS_MODEL
    set -e ANTHROPIC_DEFAULT_HAIKU_MODEL
    set -e OPENAI_API_KEY
    set -e OPENAI_BASE_URL
    set -e OPENAI_MODEL
end

function _cs_save_env
    set -gx CS_SAVED_ANTHROPIC_API_KEY "$ANTHROPIC_API_KEY"
    set -gx CS_SAVED_ANTHROPIC_BASE_URL "$ANTHROPIC_BASE_URL"
    set -gx CS_SAVED_ANTHROPIC_AUTH_TOKEN "$ANTHROPIC_AUTH_TOKEN"
    set -gx CS_SAVED_ANTHROPIC_MODEL "$ANTHROPIC_MODEL"
    set -gx CS_SAVED_ANTHROPIC_SMALL_FAST_MODEL "$ANTHROPIC_SMALL_FAST_MODEL"
    set -gx CS_SAVED_ANTHROPIC_DEFAULT_SONNET_MODEL "$ANTHROPIC_DEFAULT_SONNET_MODEL"
    set -gx CS_SAVED_ANTHROPIC_DEFAULT_OPUS_MODEL "$ANTHROPIC_DEFAULT_OPUS_MODEL"
    set -gx CS_SAVED_ANTHROPIC_DEFAULT_HAIKU_MODEL "$ANTHROPIC_DEFAULT_HAIKU_MODEL"
    set -gx CS_SAVED_OPENAI_API_KEY "$OPENAI_API_KEY"
    set -gx CS_SAVED_OPENAI_BASE_URL "$OPENAI_BASE_URL"
    set -gx CS_SAVED_OPENAI_MODEL "$OPENAI_MODEL"
end

function _cs_restore_env
    if set -q CS_SAVED_ANTHROPIC_API_KEY
        set -gx ANTHROPIC_API_KEY "$CS_SAVED_ANTHROPIC_API_KEY"
        set -e CS_SAVED_ANTHROPIC_API_KEY
    else
        set -e ANTHROPIC_API_KEY
    end
    if set -q CS_SAVED_ANTHROPIC_BASE_URL
        set -gx ANTHROPIC_BASE_URL "$CS_SAVED_ANTHROPIC_BASE_URL"
        set -e CS_SAVED_ANTHROPIC_BASE_URL
    else
        set -e ANTHROPIC_BASE_URL
    end
    if set -q CS_SAVED_ANTHROPIC_AUTH_TOKEN
        set -gx ANTHROPIC_AUTH_TOKEN "$CS_SAVED_ANTHROPIC_AUTH_TOKEN"
        set -e CS_SAVED_ANTHROPIC_AUTH_TOKEN
    else
        set -e ANTHROPIC_AUTH_TOKEN
    end
    if set -q CS_SAVED_ANTHROPIC_MODEL
        set -gx ANTHROPIC_MODEL "$CS_SAVED_ANTHROPIC_MODEL"
        set -e CS_SAVED_ANTHROPIC_MODEL
    else
        set -e ANTHROPIC_MODEL
    end
    if set -q CS_SAVED_ANTHROPIC_SMALL_FAST_MODEL
        set -gx ANTHROPIC_SMALL_FAST_MODEL "$CS_SAVED_ANTHROPIC_SMALL_FAST_MODEL"
        set -e CS_SAVED_ANTHROPIC_SMALL_FAST_MODEL
    else
        set -e ANTHROPIC_SMALL_FAST_MODEL
    end
    if set -q CS_SAVED_ANTHROPIC_DEFAULT_SONNET_MODEL
        set -gx ANTHROPIC_DEFAULT_SONNET_MODEL "$CS_SAVED_ANTHROPIC_DEFAULT_SONNET_MODEL"
        set -e CS_SAVED_ANTHROPIC_DEFAULT_SONNET_MODEL
    else
        set -e ANTHROPIC_DEFAULT_SONNET_MODEL
    end
    if set -q CS_SAVED_ANTHROPIC_DEFAULT_OPUS_MODEL
        set -gx ANTHROPIC_DEFAULT_OPUS_MODEL "$CS_SAVED_ANTHROPIC_DEFAULT_OPUS_MODEL"
        set -e CS_SAVED_ANTHROPIC_DEFAULT_OPUS_MODEL
    else
        set -e ANTHROPIC_DEFAULT_OPUS_MODEL
    end
    if set -q CS_SAVED_ANTHROPIC_DEFAULT_HAIKU_MODEL
        set -gx ANTHROPIC_DEFAULT_HAIKU_MODEL "$CS_SAVED_ANTHROPIC_DEFAULT_HAIKU_MODEL"
        set -e CS_SAVED_ANTHROPIC_DEFAULT_HAIKU_MODEL
    else
        set -e ANTHROPIC_DEFAULT_HAIKU_MODEL
    end
    if set -q CS_SAVED_OPENAI_API_KEY
        set -gx OPENAI_API_KEY "$CS_SAVED_OPENAI_API_KEY"
        set -e CS_SAVED_OPENAI_API_KEY
    else
        set -e OPENAI_API_KEY
    end
    if set -q CS_SAVED_OPENAI_BASE_URL
        set -gx OPENAI_BASE_URL "$CS_SAVED_OPENAI_BASE_URL"
        set -e CS_SAVED_OPENAI_BASE_URL
    else
        set -e OPENAI_BASE_URL
    end
    if set -q CS_SAVED_OPENAI_MODEL
        set -gx OPENAI_MODEL "$CS_SAVED_OPENAI_MODEL"
        set -e CS_SAVED_OPENAI_MODEL
    else
        set -e OPENAI_MODEL
    end
end

function _cs_get_provider_from_file
    set dir $PWD
    while test "$dir" != "/"
        if test -f "$dir/.cs"
            cat "$dir/.cs" | tr -d '[:space:]'
            return 0
        end
        set dir (dirname "$dir")
    end
    return 1
end

function _cs_is_under_dir
    set parent (string trim --right --chars=/ $argv[1])
    set current (string trim --right --chars=/ $PWD)
    test "$current" = "$parent" || string match -q "$parent/*" "$current"
end

function _cs_load_provider
    set provider $argv[1]
    set config_file "$CS_PROVIDERS_DIR/$provider.env"
    if test -f "$config_file"
        # source the env file by reading exports
        while read -l line
            set -l trimmed (string trim $line)
            if string match -q 'export *' $trimmed
                set -l kv (string replace 'export ' '' $trimmed)
                set -l key (string split '=' $kv)[1]
                set -l val (string split '=' $kv)[2]
                set -gx $key (string trim --chars='"' $val)
            end
        end < "$config_file"
        set -gx CS_PROVIDER $provider
        return 0
    end
    return 1
end

function cs_load_from_file
    set current_provider (_cs_get_provider_from_file)

    if test -n "$current_provider"
        if test "$CS_PROVIDER" != "$current_provider"
            if not set -q CS_LAST_PROVIDER
                _cs_save_env
            end
            _cs_clear_env
            if _cs_load_provider $current_provider
                set -gx CS_LAST_PROVIDER $current_provider
                set -gx CS_LAST_DIR $PWD
                echo "🤖 Provider: $current_provider"
            else
                echo "⚠️  Provider '$current_provider' not found"
                _cs_restore_env
                set -e CS_LAST_PROVIDER
                set -e CS_LAST_DIR
            end
        end
        return
    end

    if set -q CS_LAST_PROVIDER
        if not _cs_is_under_dir "$CS_LAST_DIR"
            _cs_restore_env
            set -e CS_PROVIDER
            set -e CS_LAST_PROVIDER
            set -e CS_LAST_DIR
            echo "🤖 Restored previous environment (left project directory)"
        end
    end
end

# Register directory change hook
function _cs_on_pwd_change --on-variable PWD
    cs_load_from_file
end

# Run on shell startup
cs_load_from_file
