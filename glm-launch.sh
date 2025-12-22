#!/bin/bash
# Claude Code Launcher - Чистое решение
# Запуск Claude Code с правильным volume mapping для унифицированной истории чатов

set -euo pipefail

# Цветной вывод
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

# Конфигурация с умолчаниями
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
WORKSPACE="${WORKSPACE:-$(pwd)}"
IMAGE="${CLAUDE_IMAGE:-glm-docker-tools:latest}"
SHOW_HELP=false

# Показать справку
show_help() {
    cat << EOF
Claude Code Launcher - Чистое решение для запуска Claude Code

Использование:
    $0 [OPTIONS] [CLAUDE_ARGS...]

Опции:
    -h, --help          Показать эту справку
    -w, --workspace DIR Указать рабочую директорию (по умолчанию: текущая)
    -i, --image IMAGE  Указать Docker образ (по умолчанию: claude-code-tools:latest)
    -t, --test         Запустить тест конфигурации
    -b, --backup       Создать backup ~/.claude
    --dry-run          Показать команду запуска без выполнения

Переменные окружения:
    CLAUDE_HOME        Директория Claude (по умолчанию: ~/.claude)
    WORKSPACE          Рабочая директория (по умолчанию: текущая)
    CLAUDE_IMAGE       Docker образ (по умолчанию: claude-code-tools:latest)

Примеры:
    $0                          # Запуск Claude в текущей директории
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

# Проверка зависимостей
check_dependencies() {
    # Проверка Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker не установлен или не запущен"
        exit 1
    fi

    # Проверка что Docker запущен
    if ! docker info &> /dev/null; then
        log_error "Docker daemon не запущен"
        exit 1
    fi

    # Проверка образа
    if ! docker image inspect "$IMAGE" &> /dev/null; then
        log_warning "Образ $IMAGE не найден, будет загружен при первом запуске"
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
        local size=$(stat -f%z "$CLAUDE_HOME/history.jsonl" 2>/dev/null || echo "0")
        if [[ $size -gt 0 ]]; then
            log_success "История чатов найдена ($(stat -f%z "$CLAUDE_HOME/history.jsonl") байт)"
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

    # Генерация уникального имени контейнера
    local timestamp=$(date +%s)
    local container_name="glm-docker-${timestamp}"

    # Проверка и удаление существующего контейнера с таким именем
    if docker ps -a --format "{{.Names}}" | grep -q "^claude-debug$"; then
        log_warning "Найден существующий контейнер claude-debug, удаляем..."
        docker stop claude-debug >/dev/null 2>&1 || true
        docker rm claude-debug >/dev/null 2>&1 || true
    fi

    # Подготовка Docker команды
    local docker_cmd=(
        docker run -it
        --name "$container_name"
        -v "$CLAUDE_HOME:/root/.claude"
        -v "$WORKSPACE:/workspace"
        -w /workspace
        -e CLAUDE_CONFIG_DIR=/root/.claude
        "$IMAGE"
    )

    # Показать команду если dry-run
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "Dry run mode. Команда:"
        printf '%s ' "${docker_cmd[@]}"
        if [[ ${#claude_args[@]} -gt 0 ]]; then
            printf ' %s ' "${claude_args[@]}"
        fi
        echo
        return
    fi

    log_info "Запуск Claude Code..."
    log_info "CONTAINER_NAME: $container_name"
    log_info "CLAUDE_HOME: $CLAUDE_HOME"
    log_info "WORKSPACE: $WORKSPACE"
    log_info "IMAGE: $IMAGE"

    # Проверка конфигурации перед запуском
    if [[ -f "$CLAUDE_HOME/settings.json" ]]; then
        log_success "Найден конфигурационный файл: $CLAUDE_HOME/settings.json"
        ls -la "$CLAUDE_HOME/settings.json"
        echo "Содержимое (только API настройки):"
        grep -E "(ANTHROPIC_AUTH_TOKEN|ANTHROPIC_BASE_URL|ANTHROPIC_API_KEY)" "$CLAUDE_HOME/settings.json" || echo "Прямых API настроек не найдено"
    else
        log_warning "Конфигурационный файл не найден: $CLAUDE_HOME/settings.json"
        log_info "Доступные файлы в CLAUDE_HOME:"
        ls -la "$CLAUDE_HOME" | head -10
    fi

    # Запуск контейнера
    if [[ ${#claude_args[@]} -gt 0 ]]; then
        "${docker_cmd[@]}" "${claude_args[@]}"
    else
        "${docker_cmd[@]}"
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

# Показать справку
if [[ "$SHOW_HELP" == "true" ]]; then
    show_help
    exit 0
fi

# Основная логика
main() {
    log_info "Claude Code Launcher v1.0"

    # Проверка зависимостей
    check_dependencies

    # Подготовка директорий
    prepare_directories

    # Запуск Claude
    run_claude "$@"
}

# Запуск
main "$@"