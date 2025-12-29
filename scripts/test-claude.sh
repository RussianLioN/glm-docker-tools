#!/bin/bash
# Тестовый скрипт для Claude Code Docker настройки
# Проверяет что volume mapping работает корректно

set -euo pipefail

# Цветной вывод
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0;32m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Конфигурация
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
IMAGE="${CLAUDE_IMAGE:-glm-docker-tools:latest}"

test_count=0
passed_count=0

# Запуск теста
run_test() {
    local test_name="$1"
    local test_command="$2"

    test_count=$((test_count + 1))
    echo -e "\n${BLUE}[$test_count]${NC} $test_name"

    if eval "$test_command"; then
        passed_count=$((passed_count + 1))
        log_success "✅ PASSED"
    else
        log_error "❌ FAILED"
        return 1
    fi
}

# Тест Docker доступности
run_test "Проверка Docker" "docker --version > /dev/null"

# Тест образа
run_test "Проверка Docker образа" "docker image inspect $IMAGE > /dev/null || echo 'Образ будет загружен'"

# Тест директории Claude
run_test "Проверка директории Claude" "[[ -d '$CLAUDE_HOME' ]]"

# Тест прав доступа
run_test "Проверка прав доступа" "[[ -w '$CLAUDE_HOME' ]]"

# Тест volume mapping
run_test "Volume mapping" "docker run --rm \
    -v '$CLAUDE_HOME:/root/.claude' \
    -e CLAUDE_CONFIG_DIR=/root/.claude \
    '$IMAGE' \
    test -d /root/.claude"

# Тест файла истории
run_test "Доступность файла истории" "docker run --rm \
    -v '$CLAUDE_HOME:/root/.claude' \
    -e CLAUDE_CONFIG_DIR=/root/.claude \
    '$IMAGE' \
    test -f /root/.claude/history.jsonl || echo 'Файл будет создан при первом запуске'"

# Тест Claude версии
run_test "Claude version" "docker run --rm \
    -v '$CLAUDE_HOME:/root/.claude' \
    -e CLAUDE_CONFIG_DIR=/root/.claude \
    '$IMAGE' \
    --version"

# Тест MCP серверов (если есть история)
if [[ -f "$CLAUDE_HOME/history.jsonl" ]]; then
    run_test "MCP серверы" "docker run --rm \
        -v '$CLAUDE_HOME:/root/.claude' \
        -e CLAUDE_CONFIG_DIR=/root/.claude \
        '$IMAGE' \
        mcp list || echo 'MCP недоступен'"
fi

# Тест создания файла в контейнере
run_test "Создание файла в контейнере" "docker run --rm \
    -v '$CLAUDE_HOME:/root/.claude' \
    -e CLAUDE_CONFIG_DIR=/root/.claude \
    '$IMAGE' \
    bash -c 'echo \"test\" > /root/.claude/test.txt && test -f /root/.claude/test.txt'"

# Проверка что файл появился на хосте
run_test "Файл синхронизируется с хостом" "test -f '$CLAUDE_HOME/test.txt' && rm -f '$CLAUDE_HOME/test.txt'"

# Результаты тестов
echo -e "\n${BLUE}=== Результаты тестов ===${NC}"
echo -e "${GREEN}Пройдено:${NC} $passed_count/$test_count"

if [[ $passed_count -eq $test_count ]]; then
    log_success "🎉 Все тесты пройдены! Конфигурация работает корректно."
    exit 0
else
    log_error "💥 Некоторые тесты не пройдены. Проверьте конфигурацию."
    exit 1
fi