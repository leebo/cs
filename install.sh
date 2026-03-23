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

# Copy provider configs (merge with existing, don't overwrite)
for f in "${SCRIPT_DIR}/providers"/*.env; do
    if [[ -f "$f" ]]; then
        name=$(basename "$f")
        if [[ ! -f "${CS_HOME}/providers/${name}" ]]; then
            cp "$f" "${CS_HOME}/providers/${name}"
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
        RC_FILE="${HOME}/.bashrc"
        ;;
    fish)
        RC_FILE="${HOME}/.config/fish/config.fish"
        ;;
    *)
        RC_FILE="${HOME}/.${SHELL_TYPE}rc"
        ;;
esac

# Add to rc file if not already present
if [[ -f "$RC_FILE" ]]; then
    if ! grep -q "cs-core.sh" "$RC_FILE" 2>/dev/null; then
        echo "" >> "$RC_FILE"
        echo "# cs (Claude Code Provider Switcher)" >> "$RC_FILE"
        echo "source ${CS_HOME}/lib/cs-core.sh" >> "$RC_FILE"
        echo "  🔧 Added to $RC_FILE"
    else
        echo "  ⏭️  Already configured in $RC_FILE"
    fi
else
    echo "  ⚠️  Could not find rc file: $RC_FILE"
    echo "     Please manually add: source ${CS_HOME}/lib/cs-core.sh"
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
