#!/bin/bash
# Multiple Claude Containers Launcher
# Запуск множественных контейнеров Claude Code с shared авторизацией

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

# Конфигурация
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
WORKSPACE="${WORKSPACE:-$(pwd)}"
IMAGE="${CLAUDE_IMAGE:-glm-docker-tools:latest}"
CONTAINER_PREFIX="claude-instance"

# Показать справку
show_help() {
    cat << EOF
Multiple Claude Containers Launcher

Использование:
    $0 [OPTIONS] [COUNT]

Опции:
    -h, --help          Показать эту справку
    -w, --workspace DIR Указать рабочую директорию
    -i, --image IMAGE  Указать Docker образ
    -l, --list          Показать запущенные контейнеры
    -s, --stop          Остановить все контейнеры Claude
    -c, --clean         Остановить и удалить все контейнеры Claude

Аргументы:
    COUNT               Количество контейнеров для запуска (по умолчанию: 1)

Примеры:
    $0                  # Запустить 1 контейнер
    $0 3                # Запустить 3 контейнера
    $0 --list           # Показать запущенные контейнеры
    $0 --stop           # Остановить все контейнеры
    $0 --clean          # Очистить все контейнеры

EOF
}

# Показать запущенные контейнеры
list_containers() {
    log_info "Запущенные контейнеры Claude:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(NAMES|claude-)" || echo "Нет запущенных контейнеров Claude"
}

# Остановить все контейнеры Claude
stop_containers() {
    log_info "Остановка всех контейнеров Claude..."
    local containers=$(docker ps -q --filter "name=${CONTAINER_PREFIX}")
    if [[ -n "$containers" ]]; then
        echo "$containers" | xargs docker stop
        log_success "Все контейнеры остановлены"
    else
        log_warning "Нет запущенных контейнеров для остановки"
    fi
}

# Очистить все контейнеры Claude
clean_containers() {
    log_info "Очистка всех контейнеров Claude..."
    local containers=$(docker ps -aq --filter "name=${CONTAINER_PREFIX}")
    if [[ -n "$containers" ]]; then
        echo "$containers" | xargs docker stop 2>/dev/null || true
        echo "$containers" | xargs docker rm
        log_success "Все контейнеры удалены"
    else
        log_warning "Нет контейнеров для очистки"
    fi
}

# Запуск множественных контейнеров
launch_multiple() {
    local count=${1:-1}

    if [[ ! $count =~ ^[0-9]+$ ]] || [[ $count -lt 1 ]]; then
        log_error "Некорректное количество контейнеров: $count"
        exit 1
    fi

    if [[ $count -gt 10 ]]; then
        log_warning "Запуск более 10 контейнеров может нагрузить систему"
        read -p "Продолжить? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi

    log_info "Запуск $count контейнеров Claude..."

    for i in $(seq 1 $count); do
        local timestamp=$(date +%s%N | tail -c 6)
        local container_name="${CONTAINER_PREFIX}-${i}-${timestamp}"

        log_info "Запуск контейнера $container_name..."

        if docker run -d \
            --name "$container_name" \
            -v "$CLAUDE_HOME:/root/.claude" \
            -v "$WORKSPACE:/workspace" \
            -w /workspace \
            -e CLAUDE_CONFIG_DIR=/root/.claude \
            -e TZ=Europe/Moscow \
            "$IMAGE" \
            tail -f /dev/null; then

            log_success "Контейнер $container_name запущен"
        else
            log_error "Не удалось запустить контейнер $container_name"
        fi
    done

    log_success "Завершено! Используйте '$0 --list' для просмотра контейнеров"
    log_info "Для подключения к контейнеру используйте: docker exec -it <container_name> claude"
}

# Разбор аргументов
ACTION="launch"
COUNT=1

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -w|--workspace)
            WORKSPACE="$2"
            shift 2
            ;;
        -i|--image)
            IMAGE="$2"
            shift 2
            ;;
        -l|--list)
            ACTION="list"
            shift
            ;;
        -s|--stop)
            ACTION="stop"
            shift
            ;;
        -c|--clean)
            ACTION="clean"
            shift
            ;;
        -*)
            log_error "Неизвестная опция: $1"
            show_help
            exit 1
            ;;
        *)
            if [[ "$1" =~ ^[0-9]+$ ]]; then
                COUNT="$1"
            else
                log_error "Некорректный аргумент: $1"
                exit 1
            fi
            shift
            ;;
    esac
done

# Выполнение действия
case "$ACTION" in
    launch)
        launch_multiple "$COUNT"
        ;;
    list)
        list_containers
        ;;
    stop)
        stop_containers
        ;;
    clean)
        clean_containers
        ;;
esac