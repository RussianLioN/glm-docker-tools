#!/bin/bash
# Setup GLM project configuration
# Interactive script to create ./.claude/settings.json with GLM API configuration

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

PROJECT_CLAUDE_DIR="./.claude"
SETTINGS_FILE=".claude/settings.json"

echo "🔧 GLM Configuration Setup"
echo "========================"
echo ""
echo "This script will create a project-specific GLM API configuration."
echo "Your GLM settings will override system Anthropic settings while"
echo "preserving shared OAuth tokens and chat history."
echo ""

# Create .claude directory if it doesn't exist
if [[ ! -d "$PROJECT_CLAUDE_DIR" ]]; then
    mkdir -p "$PROJECT_CLAUDE_DIR"
    log_success "Created .claude directory"
fi

# Check if settings.json already exists
if [[ -f "$SETTINGS_FILE" ]]; then
    log_warning "settings.json already exists"
    echo ""
    echo "Current configuration:"
    grep "ANTHROPIC_BASE_URL" "$SETTINGS_FILE" 2>/dev/null | sed 's/^/  /' || echo "  (unable to read)"
    echo ""
    read -p "Overwrite existing configuration? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Aborted."
        exit 0
    fi

    # Backup existing file
    local backup_file="${SETTINGS_FILE}.bak.$(date +%Y%m%d_%H%M%S)"
    cp "$SETTINGS_FILE" "$backup_file"
    log_info "Backup created: $backup_file"
fi

# Prompt for GLM API configuration
echo ""
echo "📝 Enter your GLM API configuration:"
echo "   (Press Enter to use default values)"
echo ""

# Use defaults from environment if available, otherwise prompt
DEFAULT_API_BASE="${GLM_API_BASE:-https://api.z.ai/api/anthropic}"
DEFAULT_API_MODEL="${GLM_API_MODEL:-glm-4.7}"

read -p "ANTHROPIC_AUTH_TOKEN (Z.AI API token): " API_TOKEN
read -p "ANTHROPIC_BASE_URL [$DEFAULT_API_BASE]: " API_BASE
read -p "ANTHROPIC_MODEL [$DEFAULT_API_MODEL]: " API_MODEL

# Use defaults if empty
API_BASE="${API_BASE:-$DEFAULT_API_BASE}"
API_MODEL="${API_MODEL:-$DEFAULT_API_MODEL}"

# Validate token is provided
if [[ -z "$API_TOKEN" || "$API_TOKEN" == "YOUR_GLM_TOKEN_HERE" ]]; then
    log_error "API token is required!"
    echo ""
    echo "Get your Z.AI API token from: https://api.z.ai/"
    exit 1
fi

# Create settings.json
cat > "$SETTINGS_FILE" << EOF
{
  "_comment": "GLM API Configuration - Project Specific",
  "_created": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "ANTHROPIC_AUTH_TOKEN": "$API_TOKEN",
  "ANTHROPIC_BASE_URL": "$API_BASE",
  "ANTHROPIC_MODEL": "$API_MODEL",
  "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.5-air",
  "ANTHROPIC_DEFAULT_OPUS_MODEL": "$API_MODEL",
  "ANTHROPIC_DEFAULT_SONNET_MODEL": "$API_MODEL",
  "alwaysThinkingEnabled": true,
  "env": {
    "EDITOR": "nano",
    "VISUAL": "nano",
    "ANTHROPIC_AUTH_TOKEN": "$API_TOKEN",
    "ANTHROPIC_BASE_URL": "$API_BASE",
    "ANTHROPIC_MODEL": "$API_MODEL",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.5-air",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "$API_MODEL",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "$API_MODEL",
    "API_TIMEOUT_MS": "3000000"
  }
}
EOF

# Set secure permissions
chmod 600 "$SETTINGS_FILE"

echo ""
log_success "GLM configuration created at $SETTINGS_FILE"
echo ""
echo "📋 Configuration Summary:"
echo "   Base URL: $API_BASE"
echo "   Model: $API_MODEL"
echo ""
echo "🧪 Test configuration:"
echo "   ./glm-launch.sh --test"
echo ""
echo "🚀 Run Claude Code with GLM:"
echo "   ./glm-launch.sh"
echo ""
echo "📖 For more information, see docs/GLM_CONFIGURATION_GUIDE.md"
