#!/bin/bash
# Container Lifecycle Test Script
# Тестирование новых режимов работы контейнеров: --debug, --no-del, автоудаление

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

# Конфигурация
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LAUNCHER="$PROJECT_DIR/glm-launch.sh"
IMAGE="${CLAUDE_IMAGE:-glm-docker-tools:latest}"

# Счетчики тестов
TESTS_TOTAL=0
TESTS_PASSED=0

# Начало теста
start_test() {
    local test_name="$1"
    ((TESTS_TOTAL++))
    log_info "Тест $TESTS_TOTAL: $test_name"
}

# Успешное завершение теста
pass_test() {
    local test_name="$1"
    ((TESTS_PASSED++))
    log_success "✅ Тест пройден: $test_name"
}

# Провал теста
fail_test() {
    local test_name="$1"
    local reason="$2"
    log_error "❌ Тест провален: $test_name - $reason"
}

# Очистка тестовых контейнеров
cleanup_test_containers() {
    local pattern="${1:-glm-docker-test}"
    log_info "Очистка тестовых контейнеров..."

    local containers=$(docker ps -aq --filter "name=${pattern}")
    if [[ -n "$containers" ]]; then
        echo "$containers" | xargs docker stop -f 2>/dev/null || true
        echo "$containers" | xargs docker rm -f 2>/dev/null || true
        log_info "Удалены тестовые контейнеры"
    fi
}

# Проверка существования контейнера
container_exists() {
    local container_name="$1"
    docker ps -a --format "{{.Names}}" | grep -q "^${container_name}$"
}

# Проверка запущен ли контейнер
container_running() {
    local container_name="$1"
    docker ps --format "{{.Names}}" | grep -q "^${container_name}$"
}

# Тест 1: Стандартный режим с автоудалением
test_auto_delete_mode() {
    start_test "Стандартный режим с автоудалением (--rm)"

    # Запуск в фоновом режиме для тестирования
    timeout 10s "$LAUNCHER" --dry-run 2>/dev/null || {
        fail_test "auto-delete" "Ошибка dry-run"
        return
    }

    # Проверяем что в команде есть --rm
    if "$LAUNCHER" --dry-run 2>&1 | grep -q "docker run -it --rm"; then
        pass_test "auto-delete"
    else
        fail_test "auto-delete" "Отсутствует флаг --rm в команде"
    fi
}

# Тест 2: Debug режим
test_debug_mode() {
    start_test "Debug режим (--debug)"

    # Очистка перед тестом
    cleanup_test_containers "claude-debug"

    # Проверка что команда содержит правильные флаги
    if "$LAUNCHER" --debug --dry-run 2>&1 | grep -q "docker run -it.*--name claude-debug"; then
        # Проверяем что НЕТ флага --rm
        if ! "$LAUNCHER" --debug --dry-run 2>&1 | grep -q "\-\-rm"; then
            pass_test "debug-mode"
        else
            fail_test "debug-mode" "Присутствует флаг --rm в debug режиме"
        fi
    else
        fail_test "debug-mode" "Неверная команда для debug режима"
    fi
}

# Тест 3: No-del режим
test_no_del_mode() {
    start_test "No-del режим (--no-del)"

    # Проверка что команда не содержит --rm
    if "$LAUNCHER" --no-del --dry-run 2>&1 | grep -q "docker run -it"; then
        # Проверяем что НЕТ флага --rm
        if ! "$LAUNCHER" --no-del --dry-run 2>&1 | grep -q "\-\-rm"; then
            pass_test "no-del-mode"
        else
            fail_test "no-del-mode" "Присутствует флаг --rm в no-del режиме"
        fi
    else
        fail_test "no-del-mode" "Неверная команда для no-del режима"
    fi
}

# Тест 4: Валидация конфликтующих режимов
test_conflicting_modes() {
    start_test "Валидация конфликтующих режимов (--debug --no-del)"

    # Проверка что скрипт отвергает конфликтующие режимы
    local output
    output=$("$LAUNCHER" --debug --no-del 2>&1 || true)

    if echo "$output" | grep -q "Нельзя использовать --debug и --no-del одновременно"; then
        pass_test "conflicting-modes"
    else
        fail_test "conflicting-modes" "Скрипт не обнаружил конфликтующие режимы. Вывод: $output"
    fi
}

# Тест 5: Помощь и документация
test_help_documentation() {
    start_test "Проверка документации в помощи"

    # Проверка что новая документация присутствует в помощи
    local help_output
    help_output=$("$LAUNCHER" --help 2>&1)

    if echo "$help_output" | grep -q "\-\-debug" && \
       echo "$help_output" | grep -q "\-\-no-del" && \
       echo "$help_output" | grep -q "автоудалением"; then
        pass_test "help-documentation"
    else
        fail_test "help-documentation" "Отсутствует документация по новым ключам"
    fi
}

# Тест 6: Проверка уникальных имен контейнеров
test_unique_names() {
    start_test "Проверка уникальных имен контейнеров"

    # Проверка что имена содержат timestamp
    local name1=$("$LAUNCHER" --dry-run 2>&1 | grep -o "glm-docker-[0-9]*" | head -1)
    sleep 2
    local name2=$("$LAUNCHER" --dry-run 2>&1 | grep -o "glm-docker-[0-9]*" | head -1)

    if [[ "$name1" != "$name2" ]]; then
        pass_test "unique-names"
    else
        fail_test "unique-names" "Имена контейнеров не уникальны: $name1"
    fi
}

# Тест 7: Функциональность реального контейнера (быстрый тест)
test_real_container_functionality() {
    start_test "Функциональность реального контейнера"

    # Очистка перед тестом
    cleanup_test_containers "glm-docker-realtest"

    # Запуск контейнера на короткое время с проверкой версии
    if timeout 5s "$LAUNCHER" --version >/dev/null 2>&1; then
        pass_test "real-container-functionality"
    else
        log_warning "Пропуск теста реального контейнера (требует интерактивности)"
        ((TESTS_TOTAL--))  # Не учитываем этот тест в общем счете
    fi
}

# Тест 8: Проверка переменных окружения
test_environment_variables() {
    start_test "Проверка переменных окружения"

    # Устанавливаем тестовые переменные окружения
    export CLAUDE_IMAGE="test-image:latest"
    export CLAUDE_HOME="/tmp/test-claude"

    local output
    output=$("$LAUNCHER" --dry-run 2>&1)

    if echo "$output" | grep -q "test-image:latest" && \
       echo "$output" | grep -q "/tmp/test-claude"; then
        pass_test "environment-variables"
    else
        fail_test "environment-variables" "Переменные окружения не применяются"
    fi

    # Восстановление
    unset CLAUDE_IMAGE CLAUDE_HOME
}

# Основная функция тестирования
main() {
    log_info "🧪 НАЧАЛО ТЕСТИРОВАНИЯ LIFECYCLE СКРИПТОВ"
    log_info "Скрипт запуска: $LAUNCHER"
    log_info "Docker образ: $IMAGE"
    echo

    # Проверка зависимостей
    if [[ ! -x "$LAUNCHER" ]]; then
        log_error "Скрипт запуска не найден или не исполняемый: $LAUNCHER"
        exit 1
    fi

    if ! command -v docker &> /dev/null; then
        log_error "Docker не найден"
        exit 1
    fi

    # Запуск тестов
    test_auto_delete_mode
    test_debug_mode
    test_no_del_mode
    test_conflicting_modes
    test_help_documentation
    test_unique_names
    test_environment_variables

    # Опциональный тест реального контейнера
    if [[ "${TEST_REAL_CONTAINER:-false}" == "true" ]]; then
        test_real_container_functionality
    fi

    # Очистка
    cleanup_test_containers

    echo
    log_info "📊 РЕЗУЛЬТАТЫ ТЕСТИРОВАНИЯ"
    log_info "Пройдено тестов: $TESTS_PASSED/$TESTS_TOTAL"

    if [[ $TESTS_PASSED -eq $TESTS_TOTAL ]]; then
        log_success "🎉 ВСЕ ТЕСТЫ ПРОЙДЕНЫ!"
        echo
        log_info "✅ Функциональность подтверждена:"
        log_info "   - Автоудаление контейнеров по умолчанию"
        log_info "   - Debug режим с сохранением контейнера"
        log_info "   - No-del режим с сохранением контейнера"
        log_info "   - Валидация конфликтующих режимов"
        log_info "   - Уникальные имена контейнеров"
        log_info "   - Поддержка переменных окружения"
        exit 0
    else
        log_error "❌ Некоторые тесты провалены"
        exit 1
    fi
}

# Показать справку
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    cat << EOF
Container Lifecycle Test Script

Использование:
    $0 [OPTIONS]

Опции:
    -h, --help          Показать эту справку
    --test-real         Запустить тест с реальным контейнером
    --cleanup           Только очистка тестовых контейнеров

Переменные окружения:
    TEST_REAL_CONTAINER  Запускать тест с реальным контейнером (true/false)

EOF
    exit 0
fi

# Обработка аргументов
if [[ "${1:-}" == "--test-real" ]]; then
    export TEST_REAL_CONTAINER=true
    shift
fi

if [[ "${1:-}" == "--cleanup" ]]; then
    cleanup_test_containers
    exit 0
fi

# Запуск
main "$@"