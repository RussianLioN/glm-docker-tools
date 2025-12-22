#!/bin/bash
# Удобный shell доступ к остановленному контейнеру
# Запускает контейнер, предоставляет shell, затем останавливает

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

# Показать справку
show_help() {
    cat << EOF
Shell Access Script - Удобный доступ к shell сохраненных контейнеров

Использование:
    $0 <container-name>
    $0 -h|--help

Аргументы:
    container-name    Имя контейнера для shell доступа

Примеры:
    $0 glm-docker-debug-1234567890
    $0 glm-docker-nodebug-1234567890

Что делает скрипт:
    1. Запускает остановленный контейнер
    2. Подключается к /bin/bash
    3. Останавливает контейнер после выхода из shell

EOF
}

# Проверка аргументов
if [[ $# -eq 0 ]]; then
    log_error "Требуется указать имя контейнера"
    echo
    show_help
    exit 1
fi

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

CONTAINER_NAME="$1"

# Проверка существования контейнера
if ! docker ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    log_error "Контейнер '$CONTAINER_NAME' не найден"
    log_info "Доступные контейнеры:"
    docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.CreatedAt}}" | grep glm-docker || echo "  Нет glm-docker контейнеров"
    exit 1
fi

# Проверка состояния контейнера
CONTAINER_STATUS=$(docker inspect --format='{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "unknown")

log_info "Контейнер '$CONTAINER_NAME' статус: $CONTAINER_STATUS"

# Если контейнер запущен, просто подключаемся
if [[ "$CONTAINER_STATUS" == "running" ]]; then
    log_warning "Контейнер уже запущен, подключаемся к shell..."
    docker exec -it "$CONTAINER_NAME" /bin/bash
    exit 0
fi

# Запускаем остановленный контейнер
log_info "Запуск контейнера '$CONTAINER_NAME'..."
if ! docker start "$CONTAINER_NAME" >/dev/null; then
    log_error "Не удалось запустить контейнер '$CONTAINER_NAME'"
    exit 1
fi

log_success "Контейнер запущен успешно"

# Подключаемся к shell
echo
log_info "Подключение к shell контейнера..."
log_info "Для выхода из shell введите 'exit' (контейнер будет остановлен)"
echo

docker exec -it "$CONTAINER_NAME" /bin/bash

# Останавливаем контейнер после выхода
echo
log_info "Выход из shell, остановка контейнера '$CONTAINER_NAME'..."
if docker stop "$CONTAINER_NAME" >/dev/null; then
    log_success "Контейнер остановлен"
else
    log_warning "Не удалось остановить контейнер, но это не критично"
fi

echo
log_info "Сессия завершена. Контейнер '$CONTAINER_NAME' сохранен в остановленном состоянии"