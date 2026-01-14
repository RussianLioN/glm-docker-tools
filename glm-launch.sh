#!/bin/bash
# Claude Code Launcher - Чистое решение
# Запуск Claude Code с правильным volume mapping для унифицированной истории чатов

set -euo pipefail

# Load environment configuration from .env file (P7: GitOps Configuration)
if [[ -f ".env" ]]; then
    # shellcheck disable=SC2046
    export $(grep -v '^#' .env | grep -v '^$' | xargs)
fi

# Container tracking for cleanup
CONTAINER_NAME=""
CONTAINER_CREATED=false
CLEANUP_IN_PROGRESS=false

# Цветной вывод
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Settings isolation tracking (P8)
SETTINGS_BACKUP=""
SETTINGS_AUTO_CREATED=false

# Interactive mode detection (P9 Variant C)
NON_INTERACTIVE=false

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

# Structured logging and metrics functions
log_json() {
    local level="$1" message="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local log_file="${CLAUDE_HOME}/glm-launch.log"

    echo "{\"timestamp\":\"$timestamp\",\"level\":\"$level\",\"message\":\"$message\"}" >> "$log_file" 2>/dev/null || true
}

log_metric() {
    local metric="$1" value="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local metrics_file="${CLAUDE_HOME}/metrics.jsonl"

    echo "{\"timestamp\":\"$timestamp\",\"metric\":\"$metric\",\"value\":\"$value\"}" >> "$metrics_file" 2>/dev/null || true
}

# =============================================================================
# P9 Variant C: Detect Interactive Mode
# =============================================================================

detect_interactive_mode() {
    # Check 1: Explicit flags (highest priority)
    if [[ "${1:-}" == "--ci" ]] || [[ "${1:-}" == "--non-interactive" ]]; then
        NON_INTERACTIVE=true
        return 0
    fi

    # Check 2: CI environment variables (common CI systems)
    if [[ "${CI:-}" == "true" ]] || \
       [[ "${GITHUB_ACTIONS:-}" == "true" ]] || \
       [[ "${GITLAB_CI:-}" == "true" ]] || \
       [[ "${JENKINS_HOME:-}" ]]; then
        NON_INTERACTIVE=true
        return 0
    fi

    # Check 3: TTY detection (most reliable)
    if ! tty -s <&1; then
        NON_INTERACTIVE=true
        return 0
    fi

    # Default: Interactive mode
    NON_INTERACTIVE=false
    return 0
}

# =============================================================================
# P9: Show Migration Notification (One-time)
# =============================================================================

show_migration_notification() {
    local notification_file="./.claude/.migration_notification_shown"

    # Check if notification was already shown for this project
    if [[ -f "$notification_file" ]]; then
        return 0
    fi

    cat << 'EOF' >&2
⚠️  API Key Loaded from Legacy Source

   Current source: .claude/settings.json (Priority 3)

   Migration recommended: secrets/.env (Priority 2)

   Benefits of migration:
   ✓ GitOps compliance (single source of truth)
   ✓ Better security (secrets/ directory with .gitignore)
   ✓ CI/CD friendly (env var override)
   ✓ Future-proof (upcoming features)

   Quick migration:
   ┌────────────────────────────────────────────────────────────┐
   │  ./setup-secrets.sh                                       │
   └────────────────────────────────────────────────────────────┘

   Or manually:
   ┌────────────────────────────────────────────────────────────┐
   │  mkdir -p secrets                                         │
   │  echo 'GLM_API_KEY=...' > secrets/.env                    │
   │  chmod 600 secrets/.env                                   │
   └────────────────────────────────────────────────────────────┘

   See: docs/SECRETS_MANAGEMENT.md

EOF

    # Create marker file to prevent spam (only if .claude exists)
    if [[ -d "./.claude" ]]; then
        touch "$notification_file" 2>/dev/null || true
    fi
}

# Конфигурация с умолчаниями
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
WORKSPACE="${WORKSPACE:-$(pwd)}"
IMAGE="${CLAUDE_IMAGE:-glm-docker-tools:latest}"
SHOW_HELP=false
DEBUG_MODE=false
NO_DEL_MODE=false

# Показать справку
show_help() {
    cat << EOF
Claude Code Launcher - Чистое решение для запуска Claude Code

Использование:
    $0 [OPTIONS] [CLAUDE_ARGS...]

Опции:
    -h, --help          Показать эту справку
    -w, --workspace DIR Указать рабочую директорию (по умолчанию: текущая)
    -i, --image IMAGE  Указать Docker образ (по умолчанию: glm-docker-tools:latest)
    -t, --test         Запустить тест конфигурации
    -b, --backup       Создать backup ~/.claude
    --dry-run          Показать команду запуска без выполнения
    --debug            Debug режим: сохранить контейнер и предоставить shell доступ
    --no-del           Сохранить контейнер после выхода (без автоудаления)
    --ci               CI/CD режим: неинтерактивный, fail-fast (без авто-setup)

Переменные окружения:
    CLAUDE_HOME        Директория Claude (по умолчанию: ~/.claude)
    WORKSPACE          Рабочая директория (по умолчанию: текущая)
    CLAUDE_IMAGE       Docker образ (по умолчанию: glm-docker-tools:latest)

Примеры:
    $0                          # Запуск Claude с автоудалением контейнера
    $0 --debug                  # Debug режим с сохранением контейнера и shell доступом
    $0 --no-del                 # Запуск с сохранением контейнера
    $0 /resume                   # Запуск с командой resume
    $0 -w ~/project              # Указать рабочую директорию
    $0 --test                    # Тест конфигурации
    $0 --backup                  # Создать backup

EOF
}

# Создание backup
create_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$HOME/.claude-backups/$timestamp"

    if [[ -d "$CLAUDE_HOME" ]]; then
        mkdir -p "$backup_dir"
        cp -al "$CLAUDE_HOME" "$backup_dir/"
        log_success "Backup создан: $backup_dir"
    else
        log_warning "Директория ~/.claude не найдена, backup не создан"
    fi
}

# P8: Validate GLM configuration in settings.json
validate_glm_settings() {
    local settings_file="$1"

    # Check file exists
    if [[ ! -f "$settings_file" ]]; then
        return 1
    fi

    # Validate JSON syntax
    if ! jq empty "$settings_file" 2>/dev/null; then
        log_error "Invalid JSON in $settings_file"
        return 1
    fi

    # Check for GLM configuration markers
    if ! grep -qE "api\.z\.ai|glm-[0-9]" "$settings_file"; then
        log_error "Not a GLM configuration (missing api.z.ai or glm model)"
        return 1
    fi

    # Validate required fields
    if ! jq -e '.ANTHROPIC_BASE_URL, .ANTHROPIC_MODEL, .ANTHROPIC_AUTH_TOKEN' "$settings_file" >/dev/null 2>&1; then
        log_error "Missing required fields in settings.json"
        return 1
    fi

    return 0
}

# P8: Auto-create project settings.json if missing (silent operation)
auto_create_project_settings() {
    # Check if project settings already exist
    if [[ -f "./.claude/settings.json" ]]; then
        return 0  # Already exists, nothing to do
    fi

    # Create .claude directory if needed
    mkdir -p "./.claude"

    # Priority 1: Use project GLM template (ALWAYS trusted source for GLM)
    if [[ -f "./.claude/settings.template.json" ]]; then
        cp "./.claude/settings.template.json" "./.claude/settings.json"
        chmod 600 "./.claude/settings.json"
        SETTINGS_AUTO_CREATED=true
        return 0
    fi

    # Priority 2: Create minimal hardcoded GLM configuration
    # Note: Token placeholder - user must replace with actual GLM API key via P9
    cat > "./.claude/settings.json" <<'EOF'
{
  "ANTHROPIC_AUTH_TOKEN": "YOUR_GLM_API_KEY_HERE",
  "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic",
  "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.5-air",
  "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-4.7",
  "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-4.7",
  "ANTHROPIC_MODEL": "glm-4.7",
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "YOUR_GLM_API_KEY_HERE",
    "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.5-air",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-4.7",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-4.7",
    "ANTHROPIC_MODEL": "glm-4.7",
    "alwaysThinkingEnabled": "true"
  },
  "includeCoAuthoredBy": false
}
EOF
    chmod 600 "./.claude/settings.json"
    SETTINGS_AUTO_CREATED=true

    echo "📝 Создан GLM конфигурационный файл из встроенного шаблона" >&2
    echo "   Используйте secrets/.env для указания API ключа" >&2

    return 0
}

# P9: Load API secret from secure sources (Priority chain)
load_api_secret() {
    local secret_value=""
    local legacy_source=false  # Track if key loaded from legacy settings.json

    # Priority 1: Environment variable (CI/CD, runtime)
    if [[ -n "${GLM_API_KEY:-}" ]]; then
        secret_value="$GLM_API_KEY"
    elif [[ -n "${ANTHROPIC_AUTH_TOKEN:-}" ]]; then
        secret_value="$ANTHROPIC_AUTH_TOKEN"
    fi

    # Priority 2: Secrets file
    if [[ -z "$secret_value" && -f "secrets/.env" ]]; then
        # Validate file permissions (warn if insecure) - output to stderr
        local perms
        perms=$(stat -f%A "secrets/.env" 2>/dev/null || stat -c%a "secrets/.env" 2>/dev/null)
        if [[ "$perms" != "600" && "$perms" != "400" ]]; then
            echo "⚠️  Insecure permissions on secrets/.env: $perms (should be 600)" >&2
        fi

        # Extract GLM_API_KEY (explicit whitelist)
        secret_value=$(grep -E "^GLM_API_KEY=" "secrets/.env" 2>/dev/null | cut -d'=' -f2- | head -1)
        # Remove surrounding quotes if present
        secret_value="${secret_value%\"}"
        secret_value="${secret_value#\"}"
        secret_value="${secret_value%\'}"
        secret_value="${secret_value#\'}"

        # Fallback to ANTHROPIC_AUTH_TOKEN
        if [[ -z "$secret_value" ]]; then
            secret_value=$(grep -E "^ANTHROPIC_AUTH_TOKEN=" "secrets/.env" 2>/dev/null | cut -d'=' -f2- | head -1)
            # Remove surrounding quotes if present
            secret_value="${secret_value%\"}"
            secret_value="${secret_value#\"}"
            secret_value="${secret_value%\'}"
            secret_value="${secret_value#\'}"
        fi
    fi

    # Priority 3: Existing settings.json (backward compatibility)
    if [[ -z "$secret_value" && -f "./.claude/settings.json" ]]; then
        secret_value=$(jq -r '.ANTHROPIC_AUTH_TOKEN // empty' "./.claude/settings.json" 2>/dev/null)
        if [[ -z "$secret_value" || "$secret_value" == "YOUR_GLM_API_KEY_HERE" ]]; then
            secret_value=""
        else
            legacy_source=true  # Mark as loaded from legacy source
        fi
    fi

    # Priority 4: Handle missing secret (Variant C - Hybrid)
    if [[ -z "$secret_value" ]]; then
        if [[ "$NON_INTERACTIVE" == "true" ]]; then
            # Variant A: Fail-fast for CI/CD (machine-readable)
            echo "ERROR: GLM_API_KEY not found in secrets file or environment" >&2
            echo "" >&2
            echo "To fix:" >&2
            echo "  - Run './setup-secrets.sh' in interactive terminal" >&2
            echo "  - Or set GLM_API_KEY environment variable" >&2
            echo "  - Or create secrets/.env file manually" >&2
            echo "" >&2
            echo "Get your API key from: https://z.ai/settings/api-keys" >&2
            return 1
        else
            # Variant B: Auto-launch setup for interactive users (user-friendly)
            cat << 'EOF'
┌─────────────────────────────────────────────────────────────────┐
│  🔑 API Key Not Found                                            │
│                                                                  │
│  Let's get you set up! This will only take a minute.            │
│                                                                  │
│  Starting interactive setup...                                   │
└─────────────────────────────────────────────────────────────────┘
EOF

            # Check if setup-secrets.sh exists
            if [[ ! -f "./setup-secrets.sh" ]]; then
                echo "❌ ERROR: setup-secrets.sh not found!" >&2
                echo "" >&2
                echo "   Please download it from the repository" >&2
                return 1
            fi

            # Execute setup script (direct call, NOT exec - preserves shell context)
            "./setup-secrets.sh"
            local exit_code=$?

            # Check if setup succeeded
            if (( exit_code != 0 )); then
                echo "" >&2
                echo "❌ Setup failed or was cancelled" >&2
                echo "" >&2
                echo "   To try again manually:" >&2
                echo "   ┌────────────────────────────────────────────────────────────┐" >&2
                echo "   │  ./setup-secrets.sh                                       │" >&2
                echo "   └────────────────────────────────────────────────────────────┘" >&2
                echo "" >&2
                echo "   Or create secrets file manually:" >&2
                echo "   ┌────────────────────────────────────────────────────────────┐" >&2
                echo "   │  mkdir -p secrets                                         │" >&2
                echo "   │  echo 'GLM_API_KEY=your_key_here' > secrets/.env         │" >&2
                echo "   │  chmod 600 secrets/.env                                   │" >&2
                echo "   └────────────────────────────────────────────────────────────┘" >&2
                echo "" >&2
                echo "   Get your API key from: https://z.ai/settings/api-keys" >&2
                return 1
            fi

            # Reload secret after successful setup
            echo "" >&2
            echo "✅ Setup completed! Reloading API key..." >&2

            # Try loading from secrets file again
            if [[ -f "secrets/.env" ]]; then
                secret_value=$(grep -E "^GLM_API_KEY=" "secrets/.env" 2>/dev/null | cut -d'=' -f2- | head -1)
                secret_value="${secret_value%\"}"
                secret_value="${secret_value#\"}"
                secret_value="${secret_value%\'}"
                secret_value="${secret_value#\'}"
            fi

            # Final verification
            if [[ -z "$secret_value" ]]; then
                echo "❌ Setup completed but API key still not found!" >&2
                echo "   Please run './setup-secrets.sh' manually to debug" >&2
                return 1
            fi

            echo "✅ API key loaded successfully!" >&2
        fi
    fi

    # Show migration notification if key loaded from legacy source
    if [[ "$legacy_source" == "true" && ! -f "secrets/.env" ]]; then
        show_migration_notification
    fi

    # Final validation: check key length - output to stderr
    if [[ ${#secret_value} -lt 32 ]]; then
        echo "⚠️  API key appears too short (${#secret_value} chars)" >&2
    fi

    # Output ONLY the secret value to stdout
    echo "$secret_value"
    return 0
}

# P9: Inject API key into settings.json from template
inject_api_key_to_settings() {
    local api_key="$1"
    local template="./.claude/settings.template.json"
    local output="./.claude/settings.json"

    # Create .claude directory if needed
    mkdir -p "./.claude"

    # Check if settings.json already exists with valid key
    if [[ -f "$output" ]]; then
        local existing_key
        existing_key=$(jq -r '.ANTHROPIC_AUTH_TOKEN // empty' "$output" 2>/dev/null)
        if [[ "$existing_key" == "$api_key" ]]; then
            echo "✅ API key already injected in settings.json" >&2
            return 0
        fi
    fi

    # Check template exists
    if [[ ! -f "$template" ]]; then
        echo "❌ Template not found: $template" >&2
        return 1
    fi

    # Inject API key using jq (atomic operation) - inject in BOTH locations
    if ! jq --arg token "$api_key" \
        '.ANTHROPIC_AUTH_TOKEN = $token | .env.ANTHROPIC_AUTH_TOKEN = $token' \
        "$template" > "$output.tmp" 2>/dev/null; then
        echo "❌ Failed to inject API key into settings" >&2
        rm -f "$output.tmp"
        return 1
    fi

    # Atomic move
    mv "$output.tmp" "$output"
    chmod 600 "$output"

    echo "✅ API key injected into settings.json" >&2
    return 0
}

# =============================================================================
# P10: Set Onboarding Bypass Flag (Defensive implementation)
# =============================================================================

set_onboarding_flag() {
    # P10 Research: ~/.claude.json is the CORRECT file (official config)
    # ~/.claude/.claude.json appears to be a backup/copy created during container ops
    # Sources: https://code.claude.com/docs/en/settings.md
    #          https://github.com/anthropics/claude-code/issues/13827
    #          https://github.com/anthropics/claude-code/issues/4714
    local claude_json="$HOME/.claude.json"

    # Check if .claude.json exists
    if [[ ! -f "$claude_json" ]]; then
        log_warning "⚠️  ~/.claude.json not found (may not exist yet)"
        return 0  # Don't fail - file may not exist on first run
    fi

    # 1. Check if already set (idempotent)
    if jq -e '.hasCompletedOnboarding == true' "$claude_json" 2>/dev/null; then
        log_info "✅ Onboarding already completed"
        return 0
    fi

    # 2. Create backup (defensive implementation)
    local backup_file="${claude_json}.bak.$$"
    if ! cp "$claude_json" "$backup_file"; then
        log_error "❌ Failed to create backup of .claude.json"
        return 1
    fi

    # 3. Atomic write with jq
    local tmp_file=$(mktemp)
    if ! jq '.hasCompletedOnboarding = true' "$claude_json" > "$tmp_file" 2>/dev/null; then
        log_error "❌ Failed to set onboarding flag"
        rm -f "$tmp_file"
        rm -f "$backup_file"
        return 1
    fi

    # 4. Validate JSON
    if ! jq empty "$tmp_file" 2>/dev/null; then
        log_error "❌ Generated invalid JSON"
        rm -f "$tmp_file"
        rm -f "$backup_file"
        return 1
    fi

    # 5. Atomic move
    if ! mv "$tmp_file" "$claude_json"; then
        log_error "❌ Failed to write .claude.json"
        rm -f "$tmp_file"
        # Restore from backup
        cp "$backup_file" "$claude_json"
        rm -f "$backup_file"
        return 1
    fi

    # 6. Verify success
    if ! jq -e '.hasCompletedOnboarding == true' "$claude_json" 2>/dev/null; then
        log_error "❌ Flag verification failed"
        # Restore from backup
        cp "$backup_file" "$claude_json"
        rm -f "$backup_file"
        return 1
    fi

    # Clean up backup on success
    rm -f "$backup_file"

    log_success "✅ Onboarding bypass enabled"
    log_info "   Location: ~/.claude.json (user-level config)"
    log_info "   Scope: Affects ALL Claude Code projects"
    return 0
}

# P8: Backup system settings before launch (Defensive implementation)
backup_system_settings() {
    if [[ ! -f "$CLAUDE_HOME/settings.json" ]]; then
        return 0  # No settings to backup
    fi

    # Layer 1: Pre-backup validation

    # Validate source JSON structure
    if ! jq empty "$CLAUDE_HOME/settings.json" 2>/dev/null; then
        log_error "❌ Source settings.json corrupted, cannot backup"
        log_error "   File: $CLAUDE_HOME/settings.json"
        return 1
    fi

    # Check disk space (minimum 1MB = 1024KB)
    local available=$(df -k "$CLAUDE_HOME" | awk 'NR==2 {print $4}')
    if [[ $available -lt 1024 ]]; then
        log_error "❌ Insufficient disk space for backup (need 1MB, have ${available}KB)"
        return 1
    fi

    # Check write permissions
    if [[ ! -w "$CLAUDE_HOME" ]]; then
        log_error "❌ No write permission to $CLAUDE_HOME"
        return 1
    fi

    # Layer 2: Atomic backup with verification

    local backup_file="$CLAUDE_HOME/.settings.backup.$$"

    # Atomic copy
    if ! cp "$CLAUDE_HOME/settings.json" "$backup_file"; then
        log_error "❌ Failed to create backup"
        return 1
    fi

    # Verify backup integrity (JSON validation)
    if ! jq empty "$backup_file" 2>/dev/null; then
        log_error "❌ Backup corrupted after creation"
        rm -f "$backup_file"
        return 1
    fi

    # Verify file size matches
    local orig_size=$(stat -f%z "$CLAUDE_HOME/settings.json" 2>/dev/null || stat -c%s "$CLAUDE_HOME/settings.json" 2>/dev/null)
    local backup_size=$(stat -f%z "$backup_file" 2>/dev/null || stat -c%s "$backup_file" 2>/dev/null)

    if [[ $backup_size -ne $orig_size ]]; then
        log_error "❌ Backup size mismatch (original: ${orig_size}B, backup: ${backup_size}B)"
        rm -f "$backup_file"
        return 1
    fi

    # Layer 3: Backup rotation (keep last 3)

    local backup_dir="$CLAUDE_HOME/.backups"
    mkdir -p "$backup_dir"

    # Copy verified backup to persistent location
    local timestamp=$(date +%Y%m%d-%H%M%S)
    cp "$backup_file" "$backup_dir/settings-$timestamp.json"

    # Rotate old backups (keep last 3)
    ls -t "$backup_dir"/settings-*.json 2>/dev/null | tail -n +4 | xargs -r rm -f 2>/dev/null || true

    log_success "✅ Backup created and verified: $backup_file"
    log_info "   Persistent backup: $backup_dir/settings-$timestamp.json"

    echo "$backup_file"
    return 0
}

# P8: Restore system settings after container exit (Defensive implementation)
restore_system_settings() {
    local backup_file="$1"

    if [[ -z "$backup_file" || ! -f "$backup_file" ]]; then
        log_info "ℹ️  No backup to restore"
        return 0
    fi

    # Layer 1: Pre-restore validation

    # Validate backup before restore
    if ! jq empty "$backup_file" 2>/dev/null; then
        log_error "❌ Backup file corrupted, cannot restore"
        log_error "   Backup location: $backup_file"
        log_error "   💡 Manual recovery: cp $backup_file $CLAUDE_HOME/settings.json"
        return 1
    fi

    # Layer 2: Atomic restore with emergency backup

    # Create temporary restore for testing
    local temp_restore="$CLAUDE_HOME/.settings.restore.tmp.$$"
    if ! cp "$backup_file" "$temp_restore"; then
        log_error "❌ Failed to create temporary restore"
        return 1
    fi

    # Create emergency backup of current settings (in case restore fails)
    local emergency_backup="$CLAUDE_HOME/.settings.emergency.$$"
    if [[ -f "$CLAUDE_HOME/settings.json" ]]; then
        cp "$CLAUDE_HOME/settings.json" "$emergency_backup" 2>/dev/null || true
    fi

    # Atomic restore (mv is atomic on same filesystem)
    if ! mv "$temp_restore" "$CLAUDE_HOME/settings.json"; then
        log_error "❌ Failed to restore settings"

        # Attempt emergency recovery
        if [[ -f "$emergency_backup" ]]; then
            log_warning "⚠️  Attempting emergency recovery..."
            if mv "$emergency_backup" "$CLAUDE_HOME/settings.json" 2>/dev/null; then
                log_success "✅ Emergency recovery successful"
            else
                log_error "❌ Emergency recovery failed"
                log_error "   💡 Manual recovery needed: $backup_file or $emergency_backup"
            fi
        fi
        return 1
    fi

    log_success "✅ System settings restored: $CLAUDE_HOME/settings.json"

    # Layer 3: Cleanup and archival

    # Keep backup for emergency recovery (don't delete immediately)
    local safe_backup="$CLAUDE_HOME/.settings.last_session"
    if ! mv "$backup_file" "$safe_backup" 2>/dev/null; then
        # If move fails, at least try to remove temp backup
        rm -f "$backup_file" 2>/dev/null || true
    fi

    # Remove emergency backup (restore succeeded)
    rm -f "$emergency_backup" 2>/dev/null || true

    # Backup project settings if auto-created
    if [[ "$SETTINGS_AUTO_CREATED" == "true" && -f "./.claude/settings.json" ]]; then
        if cp "./.claude/settings.json" "./.claude/settings.json.dkrbkp" 2>/dev/null; then
            log_info "   Project settings backed up: ./.claude/settings.json.dkrbkp"
        fi
    fi

    return 0
}

# Version comparison function
# Returns 0 if $1 >= $2, returns 1 otherwise
version_gte() {
    local version="$1"
    local required="$2"

    # Simple version comparison (major.minor.patch)
    local v1=(${version//./ })
    local v2=(${required//./ })

    for i in 0 1 2; do
        local num1=${v1[$i]:-0}
        local num2=${v2[$i]:-0}

        if [[ $num1 -gt $num2 ]]; then
            return 0
        elif [[ $num1 -lt $num2 ]]; then
            return 1
        fi
    done

    return 0  # Equal versions
}

# Enhanced dependency check with validation (P6: Pre-flight Checks)
check_dependencies() {
    log_info "🔍 Проверка зависимостей..."

    # Check Docker installation
    if ! command -v docker &> /dev/null; then
        log_error "❌ Docker не установлен. Установите Docker Desktop: https://docker.com"
        exit 1
    fi

    # Check Docker daemon
    if ! docker info &> /dev/null; then
        log_error "❌ Docker daemon не запущен. Запустите Docker Desktop."
        exit 1
    fi

    # Check Docker version
    local docker_version=$(docker version --format '{{.Server.Version}}' 2>/dev/null)
    local min_version="20.10.0"

    if [[ -n "$docker_version" ]]; then
        if ! version_gte "$docker_version" "$min_version"; then
            log_warning "⚠️  Docker версии $docker_version < $min_version (рекомендуется обновление)"
        else
            log_success "✅ Docker версия: $docker_version"
        fi
    else
        log_warning "⚠️  Не удалось определить версию Docker"
    fi

    # Check available disk space
    local required_space_mb=1000  # 1GB
    local available_space=$(df -m . | tail -1 | awk '{print $4}')

    if [[ "$available_space" -lt "$required_space_mb" ]]; then
        log_warning "⚠️  Мало места на диске: ${available_space}MB (рекомендуется ${required_space_mb}MB)"
    else
        log_success "✅ Доступно места: ${available_space}MB"
    fi

    # Check Docker Compose (optional)
    if command -v docker-compose &> /dev/null; then
        log_success "✅ Docker Compose установлен"
    else
        log_info "ℹ️  Docker Compose не найден (опционально)"
    fi

    # P10: Check jq for onboarding bypass (optional)
    if [[ "${CLAUDE_SKIP_ONBOARDING:-false}" == "true" ]]; then
        if ! command -v jq &> /dev/null; then
            log_warning "⚠️  jq требуется для обхода onboarding, но не найден"
            log_info "   Продолжение без обхода onboarding..."
            unset CLAUDE_SKIP_ONBOARDING
        else
            log_success "✅ jq найден (для onboarding bypass)"
        fi
    fi
}

# Ensure Docker image exists (build if necessary)
ensure_image() {
    log_info "🔍 Проверка наличия Docker-образа: $IMAGE"

    # DEBUG: Показать timestamp для отслеживания
    log_info "DEBUG: Timestamp проверки: $(date '+%Y-%m-%d %H:%M:%S.%3N')"

    # DEBUG: Показать все образы glm-docker-tools
    log_info "DEBUG: Список всех образов glm-docker-tools:"
    docker images --filter "reference=glm-docker-tools*" --format "  {{.Repository}}:{{.Tag}} | ID: {{.ID}} | Created: {{.CreatedAt}}" || log_warning "  (нет образов)"

    # Проверка 1: Используем docker images -q для надежности
    local image_id=$(docker images -q "$IMAGE" 2>/dev/null)
    log_info "DEBUG: docker images -q результат: '${image_id:-EMPTY}'"

    # Проверка 2: docker image inspect для детальной информации
    local inspect_status=0
    docker image inspect "$IMAGE" &> /dev/null || inspect_status=$?
    log_info "DEBUG: docker image inspect exit code: $inspect_status"

    if [[ -z "$image_id" ]]; then
        log_info "🏗️  Образ $IMAGE не найден (image_id пуст). Начинаю сборку..."
        log_info "DEBUG: Причина: docker images -q не вернул ID"

        local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

        if [[ ! -f "$script_dir/Dockerfile" ]]; then
            log_error "❌ Dockerfile не найден: $script_dir/Dockerfile"
            exit 1
        fi

        log_info "📦 Запуск docker build -t $IMAGE $script_dir"
        local build_start=$(date +%s)

        if ! docker build -t "$IMAGE" "$script_dir"; then
            log_error "❌ Ошибка сборки образа"
            exit 1
        fi

        local build_end=$(date +%s)
        local build_duration=$((build_end - build_start))

        log_success "✅ Образ успешно собран: $IMAGE (за ${build_duration}с)"

        # Проверка после сборки
        local new_image_id=$(docker images -q "$IMAGE" 2>/dev/null)
        if [[ -n "$new_image_id" ]]; then
            log_success "DEBUG: Сборка подтверждена, новый ID: $new_image_id"
        else
            log_error "❌ КРИТИЧЕСКАЯ ОШИБКА: Образ собран, но недоступен!"
            log_error "DEBUG: docker images -q всё ещё возвращает пустой результат"
            exit 1
        fi
    else
        log_success "✅ Образ найден: $IMAGE (ID: ${image_id:0:12})"
        log_info "DEBUG: Проверка успешна, выход из ensure_image() без сборки"
        return 0
    fi
}

# Создание необходимых директорий
prepare_directories() {
    # Создание директории Claude
    mkdir -p "$CLAUDE_HOME"

    # Проверка прав доступа
    if [[ ! -w "$CLAUDE_HOME" ]]; then
        log_error "Нет прав записи в $CLAUDE_HOME"
        exit 1
    fi

    log_info "Директория готова: $CLAUDE_HOME"
}

# Тестирование конфигурации
test_configuration() {
    log_info "Тестирование конфигурации Claude..."

    # Тест volume mapping
    if ! docker run --rm \
        -v "$CLAUDE_HOME:/root/.claude" \
        -e CLAUDE_CONFIG_DIR=/root/.claude \
        "$IMAGE" \
        ls /root/.claude/ >/dev/null 2>&1; then
        log_error "Volume mapping не работает"
        exit 1
    fi

    # Тест доступа к истории
    if [[ -f "$CLAUDE_HOME/history.jsonl" ]]; then
        local size=$(get_file_size "$CLAUDE_HOME/history.jsonl")
        if [[ $size -gt 0 ]]; then
            log_success "История чатов найдена ($(get_file_size "$CLAUDE_HOME/history.jsonl") байт)"
        fi
    else
        log_warning "История чатов не найдена, будет создана новая"
    fi

    # Тест запуска Claude
    if ! docker run --rm \
        -v "$CLAUDE_HOME:/root/.claude" \
        -e CLAUDE_CONFIG_DIR=/root/.claude \
        "$IMAGE" \
        --version >/dev/null 2>&1; then
        log_error "Claude не запускается"
        exit 1
    fi

    log_success "✅ Все тесты пройдены!"
}

# Запуск Claude
run_claude() {
    local claude_args=("$@")

    # P9 Variant C: Detect interactive mode before loading secrets
    detect_interactive_mode "${1:-}"

    # P9: Load API secret from secure sources (Priority chain)
    local api_key
    api_key=$(load_api_secret)
    if [[ $? -ne 0 ]]; then
        exit 1
    fi

    # P9: Inject API key into settings.json
    if ! inject_api_key_to_settings "$api_key"; then
        log_error "Failed to configure API key"
        exit 1
    fi

    # P10: Set onboarding bypass flag (if enabled)
    if [[ "${CLAUDE_SKIP_ONBOARDING:-false}" == "true" ]]; then
        if ! set_onboarding_flag; then
            log_warning "⚠️  Failed to set onboarding bypass"
            log_info "   Continuing anyway..."
        fi
    fi

    # P8: Validate project GLM configuration
    if [[ -f "./.claude/settings.json" ]]; then
        if ! validate_glm_settings "./.claude/settings.json"; then
            log_error "Project settings validation failed"
            exit 1
        fi
    fi

    # P8: Backup system settings
    SETTINGS_BACKUP=$(backup_system_settings)

    # Генерация уникального имени контейнера
    local timestamp=$(date +%s)
    CONTAINER_NAME="glm-docker-${timestamp}"

    # Добавляем префикс в зависимости от режима
    if [[ "$DEBUG_MODE" == "true" ]]; then
        CONTAINER_NAME="glm-docker-debug-${timestamp}"
    elif [[ "$NO_DEL_MODE" == "true" ]]; then
        CONTAINER_NAME="glm-docker-nodebug-${timestamp}"
    fi

    
    # Подготовка Docker команды с учетом режима
    local docker_cmd=(docker run -it)

    # Добавление флагов в зависимости от режима
    if [[ "$DEBUG_MODE" == "false" && "$NO_DEL_MODE" == "false" ]]; then
        docker_cmd+=(--rm)  # Автоудаление по умолчанию
    fi

    # Определяем режим для передачи в контейнер
    local launch_mode="autodel"
    if [[ "$DEBUG_MODE" == "true" ]]; then
        launch_mode="debug"
    elif [[ "$NO_DEL_MODE" == "true" ]]; then
        launch_mode="nodebug"
    fi

    docker_cmd+=(
        --name "$CONTAINER_NAME"
        -v "$CLAUDE_HOME:/root/.claude"
        -v "$WORKSPACE:/workspace"
        -w /workspace
        -e CLAUDE_CONFIG_DIR=/root/.claude
        -e CLAUDE_LAUNCH_MODE="$launch_mode"
    )

    # Показать команду если dry-run
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "Dry run mode. Команда:"
        printf '%s ' "${docker_cmd[@]}"
        printf '%s ' "$IMAGE"
        if [[ ${#claude_args[@]} -gt 0 ]]; then
            printf '%s ' "${claude_args[@]}"
        fi
        echo
        return
    fi

    log_info "Запуск Claude Code..."
    log_info "CONTAINER_NAME: $CONTAINER_NAME"
    log_info "CLAUDE_HOME: $CLAUDE_HOME"
    log_info "WORKSPACE: $WORKSPACE"
    log_info "IMAGE: $IMAGE"

    # Показать режим работы
    if [[ "$DEBUG_MODE" == "true" ]]; then
        log_info "РЕЖИМ: DEBUG (контейнер будет сохранен, shell доступ доступен)"
    elif [[ "$NO_DEL_MODE" == "true" ]]; then
        log_info "РЕЖИМ: NO-DEL (контейнер будет сохранен)"
    else
        log_info "РЕЖИМ: AUTO-DEL (контейнер будет удален при выходе)"
    fi

    # Проверка конфигурации перед запуском
    echo
    # Check for project GLM settings (Claude Code will find these automatically at /workspace/.claude/)
    if [[ -f "./.claude/settings.json" ]]; then
        log_success "🎯 Project GLM configuration detected"
        log_info "  Location: ./.claude/settings.json"
        log_info "  Container path: /workspace/.claude/settings.json"
        echo "  GLM API Configuration:"
        grep "ANTHROPIC_BASE_URL" "./.claude/settings.json" 2>/dev/null | sed 's/^/    /' || echo "    (unable to read)"
        echo
        log_info "  ⚠️  Project settings will override user settings in ~/.claude/"
        log_info "  ✓ OAuth tokens and chat history remain shared"
    elif [[ -f "$CLAUDE_HOME/settings.json" ]]; then
        log_info "No project settings found (will use user settings from ~/.claude/)"
        log_info "  Create project config: ./scripts/setup-glm-config.sh"
    else
        log_warning "No configuration found in system or project"
        log_info "  Create project config: ./scripts/setup-glm-config.sh"
    fi
    echo

    # Универсальный запуск контейнера для всех режимов
    local docker_exit_code=0

    # Mark container as created for cleanup
    CONTAINER_CREATED=true

    # Log metrics before launch
    log_metric "container_start" "$CONTAINER_NAME"
    log_metric "launch_mode" "$launch_mode"
    log_metric "docker_image" "$IMAGE"
    log_json "INFO" "Starting container: $CONTAINER_NAME (mode: $launch_mode, image: $IMAGE)"

    # Track duration
    local start_time=$SECONDS

    # Запускаем контейнер с универсальной логикой
    if [[ ${#claude_args[@]} -gt 0 ]]; then
        "${docker_cmd[@]}" "$IMAGE" "${claude_args[@]}" || docker_exit_code=$?
    else
        "${docker_cmd[@]}" "$IMAGE" || docker_exit_code=$?
    fi

    # Log metrics after exit
    local duration=$((SECONDS - start_time))
    log_metric "exit_code" "$docker_exit_code"
    log_metric "duration_seconds" "$duration"
    log_json "INFO" "Container exited: $CONTAINER_NAME (exit_code: $docker_exit_code, duration: ${duration}s)"

    # В режимах без автоудаления показываем информацию
    if [[ "$DEBUG_MODE" == "true" || "$NO_DEL_MODE" == "true" ]]; then
        echo
        log_success "✅ Claude Code завершен"

        if [[ "$NO_DEL_MODE" == "true" ]]; then
            log_warning "⚠️  Контейнер '$CONTAINER_NAME' сохранен (ОСТАНОВЛЕН)"
            echo
            log_info "📋 Команды для работы с контейнером:"
            log_info "  docker start -ai $CONTAINER_NAME                # Запустить Claude снова"
            log_info "  ./scripts/shell-access.sh $CONTAINER_NAME        # Удобный shell доступ"
            log_info "  docker rm -f $CONTAINER_NAME                    # Удалить контейнер"
        else
            log_warning "⚠️  Контейнер '$CONTAINER_NAME' будет запущен после выхода из shell"
            echo
            log_info "📋 Команды для работы с контейнером:"
            log_info "  docker stop $CONTAINER_NAME                     # Остановить контейнер"
            log_info "  docker start -ai $CONTAINER_NAME                # Запустить Claude снова"
            log_info "  docker rm -f $CONTAINER_NAME                    # Удалить контейнер"
        fi
        echo
    fi
}

# Cleanup function for signal handling
cleanup() {
    # Prevent recursive cleanup
    if [[ "$CLEANUP_IN_PROGRESS" == "true" ]]; then
        return 0
    fi
    CLEANUP_IN_PROGRESS=true

    if [[ -n "$CONTAINER_NAME" && "$CONTAINER_CREATED" == "true" ]]; then
        log_info "🧹 Cleanup: обработка контейнера $CONTAINER_NAME..."

        # Check if container exists
        if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
            # Stop container if running
            if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
                log_info "Остановка контейнера..."
                docker stop "$CONTAINER_NAME" &>/dev/null || true
            fi

            # Remove only in auto-del mode
            if [[ "$DEBUG_MODE" == "false" && "$NO_DEL_MODE" == "false" ]]; then
                log_info "Удаление контейнера..."
                docker rm -f "$CONTAINER_NAME" &>/dev/null || true
                log_success "✅ Контейнер очищен"
            else
                log_warning "⚠️  Контейнер сохранен: $CONTAINER_NAME"
                log_info "Для удаления: docker rm -f $CONTAINER_NAME"
            fi
        fi
    fi

    # P8: Restore system settings if backup exists
    if [[ -n "$SETTINGS_BACKUP" ]]; then
        restore_system_settings "$SETTINGS_BACKUP"
    fi
}

# Разбор аргументов командной строки
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            SHOW_HELP=true
            shift
            ;;
        -w|--workspace)
            WORKSPACE="$2"
            shift 2
            ;;
        -i|--image)
            IMAGE="$2"
            shift 2
            ;;
        -t|--test)
            test_configuration
            exit 0
            ;;
        -b|--backup)
            create_backup
            exit 0
            ;;
        --dry-run)
            export DRY_RUN=true
            shift
            ;;
        --debug)
            DEBUG_MODE=true
            shift
            ;;
        --no-del)
            NO_DEL_MODE=true
            shift
            ;;
        --ci|--non-interactive)
            NON_INTERACTIVE=true
            shift
            ;;
        --)
            shift
            break
            ;;
        -*)
            log_error "Неизвестная опция: $1"
            show_help
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# Валидация конфликтующих режимов
if [[ "$DEBUG_MODE" == "true" && "$NO_DEL_MODE" == "true" ]]; then
    log_error "Нельзя использовать --debug и --no-del одновременно"
    show_help
    exit 1
fi

# Показать справку
if [[ "$SHOW_HELP" == "true" ]]; then
    show_help
    exit 0
fi

# Основная логика
main() {
    log_info "Claude Code Launcher v1.1"

    # Set up signal handlers for cleanup
    trap cleanup SIGINT SIGTERM SIGQUIT ERR EXIT

    # Проверка зависимостей
    check_dependencies

    # Ensure image exists
    ensure_image

    # Подготовка директорий
    prepare_directories

    # Запуск Claude
    run_claude "$@"
}

# Запуск
main "$@"