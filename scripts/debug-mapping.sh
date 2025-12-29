#!/bin/bash
# Скрипт для отладки маппинга директорий Claude

set -euo pipefail

# Цветной вывод
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Cross-platform helper functions
get_file_size() {
    local file="$1"
    case "$OSTYPE" in
        darwin*) stat -f%z "$file" 2>/dev/null || echo "0" ;;
        linux*)  stat -c%s "$file" 2>/dev/null || echo "0" ;;
        *)       find "$file" -printf "%s" 2>/dev/null || echo "0" ;;
    esac
}

get_file_mtime() {
    local file="$1"
    case "$OSTYPE" in
        darwin*) stat -f%Sm "$file" 2>/dev/null || echo "N/A" ;;
        linux*)  stat -c%y "$file" 2>/dev/null | cut -d'.' -f1 || echo "N/A" ;;
        *)       ls -l "$file" 2>/dev/null | awk '{print $6, $7, $8}' || echo "N/A" ;;
    esac
}

CLAUDE_HOME="/Users/s060874gmail.com/.claude"

echo "=== DEBUGGING CLAUDE DIRECTORY MAPPING ==="

log_info "1. Checking host Claude directory:"
echo "Path: $CLAUDE_HOME"
ls -la "$CLAUDE_HOME" | head -10

echo
log_info "2. Checking for configuration files:"
if [[ -f "$CLAUDE_HOME/claude.json" ]]; then
    log_success "Found: $CLAUDE_HOME/claude.json"
    echo "Size: $(get_file_size "$CLAUDE_HOME/claude.json") bytes"
    echo "Modified: $(get_file_mtime "$CLAUDE_HOME/claude.json")"
else
    log_error "Not found: $CLAUDE_HOME/claude.json"
fi

if [[ -f "$CLAUDE_HOME/history.jsonl" ]]; then
    log_success "Found: $CLAUDE_HOME/history.jsonl"
    echo "Size: $(get_file_size "$CLAUDE_HOME/history.jsonl") bytes"
    echo "Lines: $(wc -l < "$CLAUDE_HOME/history.jsonl")"
else
    log_error "Not found: $CLAUDE_HOME/history.jsonl"
fi

echo
log_info "3. Testing Docker volume mapping:"
docker run --rm \
    -v "$CLAUDE_HOME:/root/.claude" \
    -e CLAUDE_CONFIG_DIR=/root/.claude \
    glm-docker-tools:latest \
    bash -c '
        echo "=== Inside Container ==="
        echo "Claude config dir: $CLAUDE_CONFIG_DIR"
        ls -la /root/.claude/ | head -10

        if [[ -f /root/.claude/claude.json ]]; then
            echo "✅ Found claude.json in container"
            echo "Size: $(stat -c%s /root/.claude/claude.json) bytes"
        else
            echo "❌ claude.json NOT found in container"
        fi

        if [[ -f /root/.claude/history.jsonl ]]; then
            echo "✅ Found history.jsonl in container"
            echo "Size: $(stat -c%s /root/.claude/history.jsonl) bytes"
            echo "Lines: $(wc -l < /root/.claude/history.jsonl)"
        else
            echo "❌ history.jsonl NOT found in container"
        fi
    '

echo
log_info "4. Checking ANTHROPIC_API_KEY:"
if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
    log_success "ANTHROPIC_API_KEY is set (${#ANTHROPIC_API_KEY} characters)"
else
    log_error "ANTHROPIC_API_KEY is NOT set"
    echo "Set it with: export ANTHROPIC_API_KEY=your_key_here"
fi

echo
log_info "5. Container inspection command:"
echo "docker inspect claude-debug | jq '.[0].Mounts'"