#!/usr/bin/env bash
# Cleanup old FPATH installation

echo "🧹 Cleaning up old installation..."

# Remove old FPATH files
if [[ -f "/usr/local/share/zsh/site-functions/glm" ]]; then
    rm -f "/usr/local/share/zsh/site-functions/glm"
    echo "✅ Removed /usr/local/share/zsh/site-functions/glm"
fi

if [[ -f "/usr/local/share/zsh/site-functions/_glm" ]]; then
    rm -f "/usr/local/share/zsh/site-functions/_glm"
    echo "✅ Removed /usr/local/share/zsh/site-functions/_glm"
fi

# Remove ALL GLM blocks from ~/.zshrc (both old autoload and old source)
zshrc="$HOME/.zshrc"
if grep -q "GLM" "$zshrc" 2>/dev/null; then
    backup="${zshrc}.bak.cleanup.$(date +%s)"
    cp "$zshrc" "$backup"
    echo "📦 Backed up ~/.zshrc to $backup"
    
    temp_file=$(mktemp)
    # Remove all GLM-related blocks (from marker to end of block)
    awk '
    /^# GLM/ { skip = 1; next }
    /^# FPATH functions need explicit autoload/ { skip = 1; next }
    /^autoload -U glm/ { skip = 1; next }
    skip && /^$/ { skip = 0; next }
    !skip { print }
    ' "$zshrc" > "$temp_file"
    mv "$temp_file" "$zshrc"
    echo "✅ Removed all GLM blocks from ~/.zshrc"
fi

echo ""
echo "✅ Cleanup complete! Now run:"
echo "  cd ~/coding/projects/glm-docker-tools"
echo "  ./scripts/setup-aliases.sh --install"
