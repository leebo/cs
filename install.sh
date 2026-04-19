#!/bin/bash

set -e

CS_HOME="${HOME}/.cs"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Installing cs (Claude Code Provider Switcher)..."

# Create directory structure
mkdir -p "${CS_HOME}/bin"
mkdir -p "${CS_HOME}/lib"
mkdir -p "${CS_HOME}/providers"

# Copy scripts
cp "${SCRIPT_DIR}/bin/cs" "${CS_HOME}/bin/cs"
chmod +x "${CS_HOME}/bin/cs"

cp "${SCRIPT_DIR}/lib/cs-core.sh" "${CS_HOME}/lib/cs-core.sh"
cp "${SCRIPT_DIR}/lib/cs-core.fish" "${CS_HOME}/lib/cs-core.fish"
cp "${SCRIPT_DIR}/lib/cs-wizard.sh" "${CS_HOME}/lib/cs-wizard.sh"

# Copy providers.json as initial catalog cache (skip if already exists)
if [[ -f "${SCRIPT_DIR}/providers.json" ]] && [[ ! -f "${CS_HOME}/providers_catalog.json" ]]; then
    cp "${SCRIPT_DIR}/providers.json" "${CS_HOME}/providers_catalog.json"
    echo "  📋 Copied providers catalog"
fi

# Copy provider configs (merge with existing, don't overwrite)
for f in "${SCRIPT_DIR}/providers"/*.env; do
    if [[ -f "$f" ]]; then
        name=$(basename "$f")
        if [[ ! -f "${CS_HOME}/providers/${name}" ]]; then
            cp "$f" "${CS_HOME}/providers/${name}"
            chmod 600 "${CS_HOME}/providers/${name}"
            echo "  📄 Copied provider: $name"
        else
            echo "  ⏭️  Skipped (exists): $name"
        fi
    fi
done

# Detect shell and configure
SHELL_TYPE=$(basename "$SHELL")

case "$SHELL_TYPE" in
    zsh)
        RC_FILE="${HOME}/.zshrc"
        ;;
    bash)
        # Git Bash on Windows loads ~/.bash_profile, not ~/.bashrc
        if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
            RC_FILE="${HOME}/.bash_profile"
        else
            RC_FILE="${HOME}/.bashrc"
        fi
        ;;
    fish)
        RC_FILE="${HOME}/.config/fish/config.fish"
        mkdir -p "${HOME}/.config/fish"
        ;;
    *)
        RC_FILE="${HOME}/.${SHELL_TYPE}rc"
        ;;
esac

# Add to rc file if not already present
if [[ "$SHELL_TYPE" == "fish" ]]; then
    CORE_FILE="${CS_HOME}/lib/cs-core.fish"
    GREP_PATTERN="cs-core.fish"
    SOURCE_LINE="source \"${CORE_FILE}\""
else
    CORE_FILE="${CS_HOME}/lib/cs-core.sh"
    GREP_PATTERN="cs-core.sh"
    SOURCE_LINE="source \"${CORE_FILE}\""
fi

if [[ "$SHELL_TYPE" == "fish" ]] || [[ -f "$RC_FILE" ]]; then
    touch "$RC_FILE"
    if ! grep -q "$GREP_PATTERN" "$RC_FILE" 2>/dev/null; then
        echo "" >> "$RC_FILE"
        echo "# cs (Claude Code Provider Switcher)" >> "$RC_FILE"
        echo "$SOURCE_LINE" >> "$RC_FILE"
        echo "  🔧 Added to $RC_FILE"
    else
        echo "  ⏭️  Already configured in $RC_FILE"
    fi
else
    echo "  ⚠️  Could not find rc file: $RC_FILE"
    echo "     Please manually add: $SOURCE_LINE"
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Run: source $RC_FILE  (or restart your terminal)"
echo "  2. Run: cs -l           (list providers)"
echo "  3. Run: cs <provider>  (switch provider)"
echo ""
echo "Provider configs are stored in: ${CS_HOME}/providers/"
echo "Edit them directly or use: cs -e <provider>"
