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
    -i, --image IMAGE  Указать Docker образ (по умолчанию: claude-code-tools:latest)
    -t, --test         Запустить тест конфигурации
    -b, --backup       Создать backup ~/.claude
    --dry-run          Показать команду запуска без выполнения
    --debug            Debug режим: сохранить контейнер и предоставить shell доступ
    --no-del           Сохранить контейнер после выхода (без автоудаления)

Переменные окружения:
    CLAUDE_HOME        Директория Claude (по умолчанию: ~/.claude)
    WORKSPACE          Рабочая директория (по умолчанию: текущая)
    CLAUDE_IMAGE       Docker образ (по умолчанию: claude-code-tools:latest)

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

    # Добавляем префикс в зависимости от режима
    if [[ "$DEBUG_MODE" == "true" ]]; then
        container_name="glm-docker-debug-${timestamp}"
    elif [[ "$NO_DEL_MODE" == "true" ]]; then
        container_name="glm-docker-nodebug-${timestamp}"
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
        --name "$container_name"
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
    log_info "CONTAINER_NAME: $container_name"
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

    # Универсальный запуск контейнера для всех режимов
    local docker_exit_code=0

    # Запускаем контейнер с универсальной логикой
    if [[ ${#claude_args[@]} -gt 0 ]]; then
        "${docker_cmd[@]}" "$IMAGE" "${claude_args[@]}" || docker_exit_code=$?
    else
        "${docker_cmd[@]}" "$IMAGE" || docker_exit_code=$?
    fi

    # В режимах без автоудаления показываем информацию
    if [[ "$DEBUG_MODE" == "true" || "$NO_DEL_MODE" == "true" ]]; then
        echo
        log_success "✅ Claude Code завершен"

        if [[ "$NO_DEL_MODE" == "true" ]]; then
            log_warning "⚠️  Контейнер '$container_name' сохранен (ОСТАНОВЛЕН)"
            echo
            log_info "📋 Команды для работы с контейнером:"
            log_info "  docker start -ai $container_name                # Запустить Claude снова"
            log_info "  ./scripts/shell-access.sh $container_name        # Удобный shell доступ"
            log_info "  docker rm -f $container_name                    # Удалить контейнер"
        else
            log_warning "⚠️  Контейнер '$container_name' будет запущен после выхода из shell"
            echo
            log_info "📋 Команды для работы с контейнером:"
            log_info "  docker stop $container_name                     # Остановить контейнер"
            log_info "  docker start -ai $container_name                # Запустить Claude снова"
            log_info "  docker rm -f $container_name                    # Удалить контейнер"
        fi
        echo
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

    # Проверка зависимостей
    check_dependencies

    # Подготовка директорий
    prepare_directories

    # Запуск Claude
    run_claude "$@"
}

# Запуск
main "$@"