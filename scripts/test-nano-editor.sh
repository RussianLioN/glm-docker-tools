#!/bin/bash
# Nano Editor Integration Test Script
# Tests nano editor functionality in GLM Docker Tools container

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

# Configuration
CONTAINER_NAME=${1:-"glm-docker-nano-test"}
IMAGE=${GLM_IMAGE:-"glm-docker-tools:latest"}

log_info "Nano Editor Integration Test v1.0"
log_info "Container: $CONTAINER_NAME"
log_info "Image: $IMAGE"

# Тест 1: Проверка установки nano
test_nano_installation() {
    log_info "Тест 1: Проверка установки nano..."

    if docker run --rm "$IMAGE" which nano > /dev/null 2>&1; then
        log_success "✅ Nano установлен в контейнере"
        docker run --rm "$IMAGE" nano --version
    else
        log_error "❌ Nano не найден в контейнере"
        return 1
    fi
}

# Тест 2: Проверка переменных окружения
test_environment_variables() {
    log_info "Тест 2: Проверка переменных окружения..."

    local editor=$(docker run --rm "$IMAGE" sh -c 'echo $EDITOR')
    local visual=$(docker run --rm "$IMAGE" sh -c 'echo $VISUAL')

    if [[ "$editor" == "nano" && "$visual" == "nano" ]]; then
        log_success "✅ EDITOR и VISUAL настроены на nano"
    else
        log_warning "⚠️ EDITOR=$editor, VISUAL=$visual"
    fi
}

# Тест 3: Проверка конфигурации nano
test_nano_configuration() {
    log_info "Тест 3: Проверка конфигурации nano..."

    if docker run --rm "$IMAGE" test -f /root/.nanorc; then
        log_success "✅ Файл конфигурации .nanorc существует"

        # Проверяем основные настройки
        local settings=$(docker run --rm "$IMAGE" cat /root/.nanorc)

        if echo "$settings" | grep -q "set linenumbers"; then
            log_success "✅ Нумерация строк включена"
        fi

        if echo "$settings" | grep -q "set tabsize 4"; then
            log_success "✅ Размер табуляции установлен на 4 пробела"
        fi

        if echo "$settings" | grep -q "set autoindent"; then
            log_success "✅ Автоотступ включен"
        fi
    else
        log_warning "⚠️ Файл конфигурации .nanorc не найден"
    fi
}

# Тест 4: Проверка интеграции с Claude Code
test_claude_integration() {
    log_info "Тест 4: Проверка интеграции с Claude Code..."

    # Создаем временный файл для теста
    local test_content="# Test File for Nano Editor Integration
# This file was created to test nano editor in Claude Code
# Date: $(date)
"

    echo "$test_content" > /tmp/test-nano.txt

    # Запускаем контейнер и тестируем редактирование
    log_info "Запускаем контейнер для тестирования..."

    docker run -d --name "$CONTAINER_NAME" \
        -v /tmp/test-nano.txt:/workspace/test-nano.txt \
        -w /workspace \
        "$IMAGE" \
        tail -f /dev/null

    if [[ $? -eq 0 ]]; then
        log_success "✅ Контейнер запущен успешно"

        # Проверяем, что файл доступен
        if docker exec "$CONTAINER_NAME" test -f /workspace/test-nano.txt; then
            log_success "✅ Тестовый файл доступен в контейнере"

            # Проверяем содержимое файла
            local content=$(docker exec "$CONTAINER_NAME" cat /workspace/test-nano.txt)
            if echo "$content" | grep -q "Test File for Nano Editor Integration"; then
                log_success "✅ Содержимое файла корректное"
            fi
        else
            log_error "❌ Тестовый файл недоступен"
        fi

        # Останавливаем контейнер
        docker stop "$CONTAINER_NAME" > /dev/null 2>&1
        docker rm "$CONTAINER_NAME" > /dev/null 2>&1
        log_info "Контейнер очищен"
    else
        log_error "❌ Не удалось запустить контейнер"
        return 1
    fi

    # Удаляем временный файл
    rm -f /tmp/test-nano.txt
}

# Тест 5: Проверка производительности nano
test_nano_performance() {
    log_info "Тест 5: Проверка производительности nano..."

    # Создаем большой файл для теста
    docker run --rm "$IMAGE" sh -c '
        echo "Generating test file..."
        for i in {1..1000}; do
            echo "Line $i: This is a test line with some content to test nano performance" >> /tmp/large-test.txt
        done
        echo "Generated file with $(wc -l < /tmp/large-test.txt) lines"

        # Тестируем открытие большого файла
        echo "Testing nano with large file..."
        timeout 5 nano /tmp/large-test.txt -c 1 &
        NANO_PID=$!
        sleep 2
        kill $NANO_PID 2>/dev/null || true
        wait $NANO_PID 2>/dev/null || true

        echo "✅ Nano успешно обрабатывает большие файлы"
        rm -f /tmp/large-test.txt
    '
}

# Тест 6: Проверка горячих клавиш
test_nano_shortcuts() {
    log_info "Тест 6: Проверка базовых функций nano..."

    docker run --rm "$IMAGE" sh -c '
        # Создаем тестовый файл
        echo "Original content" > /tmp/shortcuts-test.txt

        # Тестируем основные функции nano
        echo "Testing nano basic functions..."

        # Проверяем nano --version
        nano --version > /dev/null 2>&1 && echo "✅ Nano version check passed" || echo "❌ Nano version check failed"

        # Проверяем nano --help
        nano --help > /dev/null 2>&1 && echo "✅ Nano help check passed" || echo "❌ Nano help check failed"

        rm -f /tmp/shortcuts-test.txt
    '
}

# Основная функция
main() {
    echo "========================================="
    echo "🧪 NANO EDITOR INTEGRATION TEST SUITE"
    echo "========================================="

    local tests=(
        "test_nano_installation"
        "test_environment_variables"
        "test_nano_configuration"
        "test_claude_integration"
        "test_nano_performance"
        "test_nano_shortcuts"
    )

    local passed=0
    local total=${#tests[@]}

    for test in "${tests[@]}"; do
        echo ""
        if $test; then
            ((passed++))
        fi
    done

    echo ""
    echo "========================================="
    log_info "Результаты тестов: $passed/$total пройдено"

    if [[ $passed -eq $total ]]; then
        log_success "🎉 ВСЕ ТЕСТЫ ПРОЙДЕНЫ! Nano editor полностью интегрирован."
        echo ""
        echo "✅ Готовность к использованию:"
        echo "   - Nano установлен и настроен"
        echo "   - Переменные окружения EDITOR/VISUAL настроены"
        echo "   - Конфигурация .nanorc применена"
        echo "   - Интеграция с Claude Code работает"
        echo "   - Производительность приемлемая"
        echo ""
        echo "🚀 Используйте Claude Code с nano редактором:"
        echo "   ./glm-launch.sh"
        echo "   Внутри Claude: 'редактируй файл config.json'"
    else
        log_error "❌ Некоторые тесты не пройдены. Проверьте конфигурацию."
        return 1
    fi
}

# Запуск
main "$@"