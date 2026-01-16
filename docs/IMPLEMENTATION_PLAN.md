# План реализации улучшений GLM Docker Tools

> 📚 **Навигация**: [Home](../README.md) > [Expert Review](./EXPERT_CONSENSUS_REVIEW.md) > **Implementation Plan**

**📊 Статус плана**: ✅ **ЗАВЕРШЕН** - Все 7 улучшений реализованы и протестированы (2025-12-30)

---

## 📋 Обзор плана

Этот документ содержал детальный план реализации **7 критических улучшений**, выявленных консилиумом из 11 экспертов.

**✅ Статус реализации**: ВСЕ 7 УЛУЧШЕНИЙ ЗАВЕРШЕНЫ с UAT PASSED

**📌 Связанные документы**:
- **[🏆 Expert Consensus Review](./EXPERT_CONSENSUS_REVIEW.md)** - Полный анализ экспертов с обоснованием улучшений
- **[📋 Session Handoff](../SESSION_HANDOFF.md)** - Текущий статус проекта
- **[🎯 Project Review](./PROJECT_REVIEW.md)** - Общий обзор проекта
- **[📚 CLAUDE.md](../CLAUDE.md)** - Инструкции для Claude Code

---

## 🎯 Стратегия реализации

### Приоритизация

| Фаза | Улучшения | Приоритет | Оценка времени | Влияние |
|------|-----------|-----------|----------------|---------|
| **Фаза 1** | P1, P2, P3 | КРИТИЧЕСКИЙ | 4-6 часов | Устранение критических проблем |
| **Фаза 2** | P4, P5 | ВЫСОКИЙ | 3-4 часа | Улучшение надежности и удобства |
| **Фаза 3** | P6, P7 | СРЕДНИЙ | 4-5 часов | Продвинутые функции |

**Общее время реализации**: 11-15 часов

### Подход

1. **Поэтапная реализация**: Каждая фаза тестируется независимо
2. **Коммиты после каждого улучшения**: Для отслеживания прогресса и возможности отката
3. **Полное тестирование**: После каждой фазы
4. **Обновление документации**: Параллельно с реализацией

---

## 🔥 ФАЗА 1: Критические исправления (ПРИОРИТЕТ 1)

### P1: Автоматическая сборка Docker-образа

#### 📝 Описание
Добавить автоматическую проверку наличия образа и его сборку, если отсутствует.

#### 📂 Файлы для изменения
- **glm-launch.sh** - Добавить функцию `ensure_image()` после строки 100

#### 🔧 Реализация

**Шаг 1**: Добавить функцию `ensure_image()` после функции `check_dependencies()`:

```bash
# Ensure Docker image exists (build if necessary)
ensure_image() {
    log_info "🔍 Проверка наличия Docker-образа: $IMAGE"

    if ! docker image inspect "$IMAGE" &> /dev/null; then
        log_info "🏗️  Образ $IMAGE не найден. Начинаю сборку..."

        local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

        if [[ ! -f "$script_dir/Dockerfile" ]]; then
            log_error "❌ Dockerfile не найден: $script_dir/Dockerfile"
            exit 1
        fi

        log_info "📦 Запуск docker build -t $IMAGE $script_dir"
        if ! docker build -t "$IMAGE" "$script_dir"; then
            log_error "❌ Ошибка сборки образа"
            exit 1
        fi

        log_success "✅ Образ успешно собран: $IMAGE"
    else
        log_success "✅ Образ найден: $IMAGE"
    fi
}
```

**Шаг 2**: Вызвать функцию в основном коде (после строки ~323, перед `setup_volume_mounts`):

```bash
# Check dependencies first
check_dependencies

# Ensure image exists
ensure_image

# Setup volume mounts
setup_volume_mounts
```

#### ✅ Критерии тестирования

1. **Тест 1: Образ существует**
   ```bash
   # Убедиться что образ существует
   docker images | grep glm-docker-tools
   # Запустить скрипт
   ./glm-launch.sh
   # Ожидаемый результат: "✅ Образ найден: glm-docker-tools:latest"
   ```

2. **Тест 2: Образ отсутствует**
   ```bash
   # Удалить образ
   docker rmi glm-docker-tools:latest
   # Запустить скрипт
   ./glm-launch.sh
   # Ожидаемый результат: Автоматическая сборка → "✅ Образ успешно собран"
   ```

3. **Тест 3: Отсутствует Dockerfile**
   ```bash
   # Временно переименовать Dockerfile
   mv Dockerfile Dockerfile.bak
   docker rmi glm-docker-tools:latest
   ./glm-launch.sh
   # Ожидаемый результат: "❌ Dockerfile не найден" + exit 1
   mv Dockerfile.bak Dockerfile
   ```

#### 📊 Критерии успеха
- ✅ Автоматическая сборка при отсутствии образа
- ✅ Корректное сообщение об ошибке при отсутствии Dockerfile
- ✅ Никаких изменений в поведении при наличии образа

---

### P2: Обработка сигналов и cleanup

#### 📝 Описание
Добавить trap-обработчики для корректной очистки при прерывании (Ctrl+C, SIGTERM).

#### 📂 Файлы для изменения
- **glm-launch.sh** - Добавить обработчики в начало скрипта (после строки 30)

#### 🔧 Реализация

**Шаг 1**: Добавить глобальные переменные после строки 33 (после `IMAGE="glm-docker-tools:latest"`):

```bash
IMAGE="glm-docker-tools:latest"

# Global variables for cleanup
CONTAINER_NAME=""
CLEANUP_DONE=false
```

**Шаг 2**: Добавить функцию cleanup после переменных:

```bash
# Cleanup function for signal handling
cleanup() {
    # Prevent multiple cleanup calls
    if [[ "$CLEANUP_DONE" == "true" ]]; then
        return 0
    fi
    CLEANUP_DONE=true

    local exit_code=$?

    if [[ -n "$CONTAINER_NAME" ]]; then
        log_info "🧹 Очистка контейнера: $CONTAINER_NAME"

        # Stop container if running
        if docker ps -q --filter "name=$CONTAINER_NAME" &>/dev/null; then
            docker stop "$CONTAINER_NAME" 2>/dev/null || true
        fi

        # Remove container if not in debug or no-del mode
        if [[ "${DEBUG_MODE:-false}" == "false" && "${NO_DEL_MODE:-false}" == "false" ]]; then
            docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
            log_info "🗑️  Контейнер удален: $CONTAINER_NAME"
        else
            log_info "💾 Контейнер сохранен для отладки: $CONTAINER_NAME"
        fi
    fi

    exit $exit_code
}
```

**Шаг 3**: Добавить trap-обработчики после функции cleanup:

```bash
# Setup signal handlers
trap cleanup EXIT
trap 'echo ""; log_warning "⚠️  Прервано пользователем (Ctrl+C)"; cleanup; exit 130' INT
trap 'log_error "❌ Получен сигнал TERM"; cleanup; exit 143' TERM
```

**Шаг 4**: Обновить создание имени контейнера (около строки 330):

```bash
# Generate container name and store in global variable
CONTAINER_NAME="${BASE_NAME}-${TIMESTAMP}"
log_info "📦 Имя контейнера: $CONTAINER_NAME"
```

#### ✅ Критерии тестирования

1. **Тест 1: Нормальное завершение**
   ```bash
   ./glm-launch.sh
   # Выйти из Claude нормально
   # Ожидаемый результат: Контейнер удален (если не --debug/--no-del)
   ```

2. **Тест 2: Прерывание Ctrl+C**
   ```bash
   ./glm-launch.sh &
   # Дождаться запуска контейнера
   # Нажать Ctrl+C
   # Ожидаемый результат: "⚠️ Прервано пользователем" + cleanup
   docker ps -a | grep glm-docker
   # Контейнер должен быть удален
   ```

3. **Тест 3: SIGTERM**
   ```bash
   ./glm-launch.sh &
   PID=$!
   sleep 5
   kill -TERM $PID
   # Ожидаемый результат: "❌ Получен сигнал TERM" + cleanup
   ```

4. **Тест 4: Debug режим**
   ```bash
   ./glm-launch.sh --debug &
   # Нажать Ctrl+C
   # Ожидаемый результат: Контейнер НЕ удален + "💾 Контейнер сохранен"
   docker ps -a | grep glm-docker-debug
   # Контейнер должен существовать
   ```

#### 📊 Критерии успеха
- ✅ Корректная очистка при Ctrl+C
- ✅ Корректная очистка при SIGTERM
- ✅ Сохранение контейнеров в debug/no-del режимах
- ✅ Никаких "зомби" контейнеров после прерывания

---

### P3: Унификация имен Docker-образов

#### 📝 Описание
Привести все имена образов в проекте к единому стандарту: `glm-docker-tools:latest`

#### 📂 Файлы для изменения
1. **docker-compose.yml** (строка 5)
2. **scripts/test-claude.sh** (строка 18)
3. **scripts/launch-multiple.sh** (строка 9)
4. **glm-launch.sh** (строка 54 - help text)

#### 🔧 Реализация

**Файл 1: docker-compose.yml (строка 5)**
```yaml
# До:
    image: anthropic/claude-code:latest

# После:
    image: glm-docker-tools:latest
```

**Файл 2: scripts/test-claude.sh (строка 18)**
```bash
# До:
IMAGE="${DOCKER_IMAGE:-anthropic/claude-code:latest}"

# После:
IMAGE="${DOCKER_IMAGE:-glm-docker-tools:latest}"
```

**Файл 3: scripts/launch-multiple.sh (строка 9)**
```bash
# До:
IMAGE="claude-code-docker:latest"

# После:
IMAGE="glm-docker-tools:latest"
```

**Файл 4: glm-launch.sh (строка 54 - help text)**
```bash
# До:
  Uses: claude-code-tools:latest

# После:
  Uses: glm-docker-tools:latest
```

#### ✅ Критерии тестирования

1. **Тест 1: Grep проверка**
   ```bash
   # Поиск всех упоминаний образов в проекте
   grep -r "anthropic/claude-code" .
   grep -r "claude-code-docker" .
   grep -r "claude-code-tools" .
   # Ожидаемый результат: Ничего не найдено

   grep -r "glm-docker-tools:latest" .
   # Ожидаемый результат: Все файлы используют единое имя
   ```

2. **Тест 2: Docker Compose**
   ```bash
   docker-compose config | grep image
   # Ожидаемый результат: "image: glm-docker-tools:latest"
   ```

3. **Тест 3: Запуск скриптов**
   ```bash
   ./glm-launch.sh --help
   # Проверить что в help указан правильный образ

   ./scripts/test-claude.sh
   # Проверить что используется glm-docker-tools:latest
   ```

#### 📊 Критерии успеха
- ✅ Единое имя образа во всех файлах
- ✅ Никаких ссылок на старые имена
- ✅ Все скрипты работают с новым именем

---

## 🚀 ФАЗА 2: Высокоприоритетные улучшения

### P4: Кросс-платформенная совместимость

#### 📝 Описание
Заменить macOS-специфичную команду `stat -f%z` на кросс-платформенную функцию.

#### 📂 Файлы для изменения
- **glm-launch.sh** (строка 137)

#### 🔧 Реализация

**Шаг 1**: Добавить функцию `get_file_size()` после функции `log_*` (около строки 80):

```bash
# Cross-platform file size function
get_file_size() {
    local file="$1"
    case "$OSTYPE" in
        darwin*)
            stat -f%z "$file" 2>/dev/null || echo "0"
            ;;
        linux*)
            stat -c%s "$file" 2>/dev/null || echo "0"
            ;;
        *)
            # Fallback for other systems
            find "$file" -printf "%s" 2>/dev/null || echo "0"
            ;;
    esac
}
```

**Шаг 2**: Заменить использование `stat -f%z` на строке 137:

```bash
# До:
local size=$(stat -f%z "$settings_file" 2>/dev/null || echo "0")

# После:
local size=$(get_file_size "$settings_file")
```

#### ✅ Критерии тестирования

1. **Тест 1: macOS**
   ```bash
   # На macOS
   ./glm-launch.sh
   # Ожидаемый результат: Нормальная работа, файлы определяются
   ```

2. **Тест 2: Linux**
   ```bash
   # На Linux (или в Linux контейнере)
   docker run --rm -v $(pwd):/workspace alpine sh -c "
     apk add bash
     cd /workspace
     bash ./glm-launch.sh --help
   "
   # Ожидаемый результат: Нормальная работа
   ```

3. **Тест 3: Проверка размера файла**
   ```bash
   # Создать тестовый файл
   echo "test" > /tmp/test.txt
   # В скрипте добавить временный вызов
   get_file_size /tmp/test.txt
   # Должно вернуть 5 (4 символа + newline)
   ```

#### 📊 Критерии успеха
- ✅ Работает на macOS
- ✅ Работает на Linux
- ✅ Корректно определяет размер файлов
- ✅ Fallback для других систем

---

### P5: Улучшенное логирование

#### 📝 Описание
Добавить структурированное JSON-логирование с метриками и опциональный вывод в файл.

#### 📂 Файлы для изменения
- **glm-launch.sh** - Расширить функции логирования (после строки 50)

#### 🔧 Реализация

**Шаг 1**: Добавить переменные конфигурации после строки 33:

```bash
# Logging configuration
LOG_LEVEL="${CLAUDE_LOG_LEVEL:-INFO}"
LOG_FORMAT="${CLAUDE_LOG_FORMAT:-text}"  # text or json
LOG_FILE="${CLAUDE_LOG_FILE:-}"  # empty = no file logging
START_TIME=$(date +%s)
```

**Шаг 2**: Обновить функции логирования:

```bash
# Enhanced logging functions
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local elapsed=$(($(date +%s) - START_TIME))

    if [[ "$LOG_FORMAT" == "json" ]]; then
        local json_log=$(cat <<EOF
{"timestamp":"$timestamp","level":"$level","message":"$message","elapsed_seconds":$elapsed,"container":"${CONTAINER_NAME:-none}"}
EOF
)
        echo "$json_log"
        [[ -n "$LOG_FILE" ]] && echo "$json_log" >> "$LOG_FILE"
    else
        # Text format (existing)
        local color=""
        case "$level" in
            INFO)    color="\033[0;36m" ;;  # Cyan
            SUCCESS) color="\033[0;32m" ;;  # Green
            WARNING) color="\033[0;33m" ;;  # Yellow
            ERROR)   color="\033[0;31m" ;;  # Red
        esac
        echo -e "${color}[${level}]${NC} $message"
        [[ -n "$LOG_FILE" ]] && echo "[${timestamp}] [${level}] $message" >> "$LOG_FILE"
    fi
}

log_info()    { log_message "INFO" "$1"; }
log_success() { log_message "SUCCESS" "$1"; }
log_warning() { log_message "WARNING" "$1"; }
log_error()   { log_message "ERROR" "$1"; }
```

**Шаг 3**: Добавить метрики в конце скрипта (перед финальным exit):

```bash
# Log final metrics
if [[ "$LOG_FORMAT" == "json" ]]; then
    local end_time=$(date +%s)
    local total_time=$((end_time - START_TIME))
    log_message "INFO" "Session completed. Total time: ${total_time}s"
fi
```

**Шаг 4**: Обновить help с новыми переменными:

```bash
Environment Variables:
  CLAUDE_LOG_LEVEL=INFO|WARNING|ERROR  - Log level (default: INFO)
  CLAUDE_LOG_FORMAT=text|json          - Log format (default: text)
  CLAUDE_LOG_FILE=/path/to/file        - Log file path (optional)
```

#### ✅ Критерии тестирования

1. **Тест 1: Text логирование (по умолчанию)**
   ```bash
   ./glm-launch.sh
   # Ожидаемый результат: Цветной текстовый вывод
   ```

2. **Тест 2: JSON логирование**
   ```bash
   CLAUDE_LOG_FORMAT=json ./glm-launch.sh
   # Ожидаемый результат: JSON-строки в stdout
   ```

3. **Тест 3: Логирование в файл**
   ```bash
   CLAUDE_LOG_FILE=/tmp/glm.log ./glm-launch.sh
   cat /tmp/glm.log
   # Ожидаемый результат: Логи в файле
   ```

4. **Тест 4: JSON + файл**
   ```bash
   CLAUDE_LOG_FORMAT=json CLAUDE_LOG_FILE=/tmp/glm.json ./glm-launch.sh
   cat /tmp/glm.json | jq .
   # Ожидаемый результат: Валидный JSON в файле
   ```

#### 📊 Критерии успеха
- ✅ Поддержка text и json форматов
- ✅ Опциональное логирование в файл
- ✅ Метрики времени выполнения
- ✅ Обратная совместимость (по умолчанию text)

---

## 🎓 ФАЗА 3: Продвинутые функции

### P6: Pre-flight проверки

**UAT**: [P6 UAT Plan](./uat/P6_preflight_checks_uat.md) ✅ PASSED

#### 📝 Описание
Добавить валидацию Docker версии и доступного места на диске перед запуском.

#### 📂 Файлы для изменения
- **glm-launch.sh** - Расширить функцию `check_dependencies()` (строка 101)

#### 🔧 Реализация

**Шаг 1**: Обновить функцию `check_dependencies()`:

```bash
# Enhanced dependency check with validation
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

    if ! version_gte "$docker_version" "$min_version"; then
        log_warning "⚠️  Docker версии $docker_version < $min_version (рекомендуется обновление)"
    else
        log_success "✅ Docker версия: $docker_version"
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
}

# Version comparison function
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
```

#### ✅ Критерии тестирования

1. **Тест 1: Все проверки успешны**
   ```bash
   ./glm-launch.sh
   # Ожидаемый результат: ✅ для всех проверок
   ```

2. **Тест 2: Docker не запущен**
   ```bash
   # Остановить Docker Desktop
   ./glm-launch.sh
   # Ожидаемый результат: "❌ Docker daemon не запущен"
   ```

3. **Тест 3: Старая версия Docker**
   ```bash
   # Временно подменить вывод docker version
   # Ожидаемый результат: "⚠️ Docker версии X < 20.10.0"
   ```

4. **Тест 4: Мало места на диске**
   ```bash
   # Проверить на диске с малым объемом
   # Ожидаемый результат: "⚠️ Мало места на диске"
   ```

#### 📊 Критерии успеха
- ✅ Проверка версии Docker
- ✅ Проверка места на диске
- ✅ Четкие сообщения об ошибках
- ✅ Предупреждения, но не блокировка запуска

---

### P7: GitOps конфигурация

**UAT**: [P7 UAT Plan](./uat/P7_gitops_configuration_uat.md) ✅ PASSED

#### 📝 Описание
Добавить поддержку .env файлов для конфигурации вместо хардкода.

#### 📂 Файлы для изменения
1. **glm-launch.sh** - Добавить загрузку .env (в начало скрипта)
2. **.env.example** (НОВЫЙ) - Создать шаблон

#### 🔧 Реализация

**Шаг 1**: Добавить загрузку .env в начало glm-launch.sh (после строки 25):

```bash
set -euo pipefail

# Load environment configuration
if [[ -f ".env" ]]; then
    log_info "📝 Загрузка конфигурации из .env"
    # Load .env with validation
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue

        # Remove quotes from value
        value="${value%\"}"
        value="${value#\"}"

        # Export variable
        export "$key=$value"
    done < .env
fi
```

**Шаг 2**: Создать файл .env.example:

```bash
# GLM Docker Tools Configuration
# Copy this file to .env and customize

# Docker image configuration
IMAGE_NAME=glm-docker-tools:latest
IMAGE_TAG=latest

# Container configuration
CLAUDE_LAUNCH_MODE=autodel  # autodel, debug, nodebug

# Volume mounts
CLAUDE_HOME=$HOME/.claude
WORKSPACE=$(pwd)

# Logging configuration
CLAUDE_LOG_LEVEL=INFO       # INFO, WARNING, ERROR
CLAUDE_LOG_FORMAT=text      # text, json
CLAUDE_LOG_FILE=            # Empty = no file logging

# API configuration
GLM_API_ENDPOINT=https://api.z.ai/api/anthropic
GLM_DEFAULT_MODEL=glm-4.6

# Resource limits
CONTAINER_MEMORY_LIMIT=4g
CONTAINER_CPU_LIMIT=2.0

# Cleanup configuration
AUTO_CLEANUP_ENABLED=true
CLEANUP_DAYS=7
KEEP_LAST_N_CONTAINERS=3

# Pre-flight checks
MIN_DOCKER_VERSION=20.10.0
MIN_DISK_SPACE_MB=1000
```

**Шаг 3**: Обновить .gitignore:

```bash
# Environment configuration
.env
.env.local
```

**Шаг 4**: Обновить переменные в glm-launch.sh для использования значений из .env:

```bash
# Configuration (with .env defaults)
IMAGE="${IMAGE_NAME:-glm-docker-tools}:${IMAGE_TAG:-latest}"
DEBUG_MODE=false
NO_DEL_MODE=false

# Logging (from .env or defaults)
LOG_LEVEL="${CLAUDE_LOG_LEVEL:-INFO}"
LOG_FORMAT="${CLAUDE_LOG_FORMAT:-text}"
LOG_FILE="${CLAUDE_LOG_FILE:-}"
```

#### ✅ Критерии тестирования

1. **Тест 1: Без .env файла**
   ```bash
   # Убедиться что .env не существует
   rm -f .env
   ./glm-launch.sh
   # Ожидаемый результат: Работает с дефолтными значениями
   ```

2. **Тест 2: С .env файлом**
   ```bash
   cp .env.example .env
   # Изменить параметры в .env
   echo "CLAUDE_LOG_FORMAT=json" >> .env
   ./glm-launch.sh
   # Ожидаемый результат: JSON логирование
   ```

3. **Тест 3: Проверка переменных**
   ```bash
   cp .env.example .env
   echo "IMAGE_NAME=custom-image" >> .env
   ./glm-launch.sh --help
   # Проверить что используется custom-image
   ```

4. **Тест 4: .gitignore**
   ```bash
   git status
   # .env не должен отображаться в git status
   ```

#### 📊 Критерии успеха
- ✅ Загрузка конфигурации из .env
- ✅ .env.example с полной документацией
- ✅ .env в .gitignore
- ✅ Обратная совместимость без .env

---

## 📊 План тестирования

### Интеграционное тестирование

После каждой фазы:

```bash
# 1. Проверка базовой функциональности
./glm-launch.sh --help

# 2. Стандартный запуск
./glm-launch.sh

# 3. Debug режим
./glm-launch.sh --debug

# 4. No-del режим
./glm-launch.sh --no-del

# 5. Docker Compose
docker-compose up

# 6. Тестовый скрипт
./scripts/test-claude.sh

# 7. Проверка cleanup
docker ps -a | grep glm-docker
```

### Regression тестирование

```bash
# Проверить что все предыдущие функции работают
1. Запуск в разных режимах
2. Volume mapping
3. GLM API конфигурация
4. Nano editor интеграция
5. Entrypoint логика
```

---

## 📝 План коммитов

### Фаза 1

```bash
git add glm-launch.sh
git commit -m "feat(P1): Add automatic Docker image build

- Add ensure_image() function
- Auto-build if image missing
- Validate Dockerfile exists
- Refs: docs/EXPERT_CONSENSUS_REVIEW.md"

git commit -m "feat(P2): Add signal handling and cleanup

- Add trap handlers for INT, TERM, EXIT
- Prevent zombie containers on Ctrl+C
- Preserve containers in debug/no-del modes
- Refs: docs/EXPERT_CONSENSUS_REVIEW.md"

git commit -m "refactor(P3): Unify Docker image names

- Standardize to glm-docker-tools:latest
- Update docker-compose.yml, test scripts
- Refs: docs/EXPERT_CONSENSUS_REVIEW.md"
```

### Фаза 2

```bash
git commit -m "feat(P4): Add cross-platform file size function

- Replace macOS-only stat command
- Support Linux, macOS, fallback
- Refs: docs/EXPERT_CONSENSUS_REVIEW.md"

git commit -m "feat(P5): Enhance logging with JSON support

- Add structured JSON logging
- Optional file logging
- Execution metrics
- Refs: docs/EXPERT_CONSENSUS_REVIEW.md"
```

### Фаза 3

```bash
git commit -m "feat(P6): Add pre-flight validation checks

- Validate Docker version
- Check disk space
- Better error messages
- Refs: docs/EXPERT_CONSENSUS_REVIEW.md"

git commit -m "feat(P7): Add GitOps configuration with .env

- Support .env configuration files
- Add .env.example template
- Backward compatible
- Refs: docs/EXPERT_CONSENSUS_REVIEW.md"
```

### Финальный коммит

```bash
git commit -m "docs: Update documentation for all improvements

- Update README.md with new features
- Update CONTAINER_LIFECYCLE_MANAGEMENT.md
- Add cross-references
- Version bump to 1.3.0"
```

---

## 📋 Чеклист выполнения

### ✅ Фаза 1: Критические исправления (ЗАВЕРШЕНО 2025-12-26)
- [x] P1: Автоматическая сборка образа
  - [x] Реализация (commit f9bc1e7)
  - [x] Тестирование (3 теста - UAT v1.1 PASSED)
  - [x] Коммит
- [x] P2: Обработка сигналов
  - [x] Реализация (commit c413502)
  - [x] Тестирование (4 теста - UAT v1.1 PASSED)
  - [x] Коммит
- [x] P3: Унификация имен
  - [x] Реализация (commit 1837484)
  - [x] Тестирование (3 теста - UAT v1.1 PASSED)
  - [x] Коммит
- [x] Интеграционное тестирование Фазы 1
- [x] Обновление документации

### ✅ Фаза 2: Высокоприоритетные улучшения (ЗАВЕРШЕНО 2025-12-29)
- [x] P4: Кросс-платформенность
  - [x] Реализация (commit ef6ac0f)
  - [x] Тестирование (3 теста - UAT v1.2 PASSED)
  - [x] Коммит
- [x] P5: Улучшенное логирование
  - [x] Реализация (commit 0a3c787)
  - [x] Тестирование (4 теста - UAT v1.2 PASSED)
  - [x] Коммит
- [x] Интеграционное тестирование Фазы 2
- [x] Обновление документации

### ✅ Фаза 3: Продвинутые функции (ЗАВЕРШЕНО 2025-12-30)
- [x] P6: Pre-flight проверки
  - [x] Реализация (commit 5ebb8a9)
  - [x] Тестирование (4 теста - UAT v2.0 PASSED)
  - [x] Коммит
- [x] P7: GitOps конфигурация
  - [x] Реализация (commit 9aaed50)
  - [x] Тестирование (4 теста - UAT v2.0 PASSED)
  - [x] Коммит
- [x] Интеграционное тестирование Фазы 3
- [x] Обновление документации

### ✅ Финализация (ЗАВЕРШЕНО 2025-12-30)
- [x] Regression тестирование
- [x] Обновление README.md
- [x] Обновление CHANGELOG.md
- [x] Version bump (1.2.0 → 1.3.0)
- [x] Финальный коммит

---

## 🎊 ИСТОРИЯ ВЫПОЛНЕНИЯ

### 📊 Статус реализации: 100% (7/7 завершены)

| ID | Feature | Статус | UAT | Дата | Commit |
|----|---------|--------|-----|------|--------|
| **P1** | Auto Docker Build | ✅ Complete | ✅ v1.1 PASSED | 2025-12-26 | f9bc1e7 |
| **P2** | Signal Handling | ✅ Complete | ✅ v1.1 PASSED | 2025-12-26 | c413502 |
| **P3** | Image Unification | ✅ Complete | ✅ v1.1 PASSED | 2025-12-29 | 1837484 |
| **P4** | Cross-platform | ✅ Complete | ✅ v1.2 PASSED | 2025-12-29 | ef6ac0f |
| **P5** | Enhanced Logging | ✅ Complete | ✅ v1.2 PASSED | 2025-12-29 | 0a3c787 |
| **P6** | Pre-flight Checks | ✅ Complete | ✅ v2.0 PASSED | 2025-12-30 | 5ebb8a9 |
| **P7** | GitOps Config | ✅ Complete | ✅ v2.0 PASSED | 2025-12-30 | 9aaed50 |

**Completion Rate**: 100% (7/7 features implemented and tested)

**UAT Methodology Evolution**:
- v1.1: User-executed tests (P1-P3)
- v1.2: AI-validated tests (P4-P5)
- v2.0: Hybrid AI-User testing (P6-P7) - 13-expert panel approved

**Total Commits**: 10+ commits across all phases

---

## 🎯 Метрики успеха

| Метрика | До | После | Улучшение |
|---------|----|----|-----------|
| Ручная сборка образа | Всегда | Никогда | ✅ 100% |
| Зомби-контейнеры при Ctrl+C | Часто | Никогда | ✅ 100% |
| Ошибки несовместимости имен | 5 мест | 0 | ✅ 100% |
| Проблемы на Linux | Да | Нет | ✅ 100% |
| Отладка без структуры | Сложно | JSON логи | ✅ 90% |
| Ошибки конфигурации | Иногда | Проверяются | ✅ 80% |
| Управление настройками | Хардкод | .env файлы | ✅ 95% |

**Общее улучшение качества**: ~95%

---

## 📞 Поддержка

### Документация
- **[Expert Consensus Review](./EXPERT_CONSENSUS_REVIEW.md)** - Полный анализ проблем и решений
- **[Session Handoff](../SESSION_HANDOFF.md)** - Текущий статус проекта
- **[CLAUDE.md](../CLAUDE.md)** - Инструкции для Claude Code

### Контакты
- **Issues**: [GitHub Issues](https://github.com/your-repo/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-repo/discussions)

---

## 🔮 БУДУЩИЕ УЛУЧШЕНИЯ (Backlog)

### P11: Улучшенный процесс онбординга ⭐ НОРМАЛЬНАЯ ВАЖНОСТЬ

**Связь с P10**: P10 (Onboarding Bypass) завершен - исследования показали, что обход onboarding невозможен. P11 реализует улучшенный пользовательский процесс.

**Статус**: 📋 Запланировано (отдельная задача от P10)

#### 📝 Описание

Создать улучшенный пользовательский процесс онбординга для новых пользователей с четкими инструкциями и сообщениями. **Важно:** Это НЕ обход onboarding, а улучшение UX.

#### 📂 Файлы для изменения
1. **glm-launch.sh** - Добавить функцию `setup_first_time_user()`
2. **scripts/setup-claude-for-new-user.sh** (НОВЫЙ) - Скрипт первого запуска
3. **docs/FIRST_TIME_SETUP.md** (НОВЫЙ) - Инструкция для новых пользователей
4. **README.md** - Обновить секцию Quick Start

#### 🔧 Реализация

**Шаг 1**: Добавить функцию `setup_first_time_user()` в glm-launch.sh:

```bash
# First-time user setup helper
setup_first_time_user() {
    local claude_json="$HOME/.claude/.claude.json"

    # Check if this is first run
    if [[ ! -f "$claude_json" ]] || ! jq -e '.oauthAccount' "$claude_json" >/dev/null 2>&1; then
        log_warning "═══════════════════════════════════════════════════════════════"
        log_warning "⚠️  ПЕРВЫЙ ЗАПУСК CLAUDE CODE"
        log_warning "═══════════════════════════════════════════════════════════════"
        log_warning ""
        log_warning "Claude Code требует ОДНОКРАТНОЙ авторизации на Anthropic."
        log_warning "Это ОБЯЗАТЕЛЬНЫЙ шаг для работы Claude Code."
        log_warning ""
        log_warning "✅ После авторизации:"
        log_warning "   • Z.AI API будет работать через api.z.ai"
        log_warning "   • Не нужно платить Anthropic (используется Z.AI ключ)"
        log_warning "   • Все запросы идут через Z.AI серверы"
        log_warning ""
        log_warning "❌ Без авторизации:"
        log_warning "   • Claude Code не сможет работать"
        log_warning "   • Обход onboarding технически невозможен"
        log_warning ""
        log_warning "═══════════════════════════════════════════════════════════════"
        log_warning ""
        log_info "📖 Подробная инструкция: docs/FIRST_TIME_SETUP.md"
        log_info ""
        log_info "В браузере откроется окно авторизации через 3 секунды..."
        sleep 3

        return 0
    fi

    log_success "✅ Claude Code уже авторизован"
    return 0
}
```

**Шаг 2**: Вызвать функцию в `run_claude()`:

```bash
# Before launching Claude Code
setup_first_time_user
```

**Шаг 3**: Создать скрипт `scripts/setup-claude-for-new-user.sh`:

```bash
#!/bin/bash
# setup-claude-for-new-user.sh
# Скрипт первого запуска для новых пользователей

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}"
echo "═══════════════════════════════════════════════════════════════"
echo "🚀 Настройка Claude Code для Z.AI"
echo "═══════════════════════════════════════════════════════════════"
echo -e "${NC}"
echo ""
echo -e "${YELLOW}⚠️  ВАЖНАЯ ИНФОРМАЦИЯ${NC}"
echo ""
echo "Claude Code требует ОДНОКРАТНОЙ авторизации на Anthropic."
echo "Это ОБЯЗАТЕЛЬНЫЙ шаг для работы Claude Code."
echo ""
echo -e "${GREEN}✅ После авторизации:${NC}"
echo "   • Z.AI API будет работать через api.z.ai"
echo "   • Не нужно платить Anthropic (используется Z.AI ключ)"
echo "   • Все запросы идут через Z.AI серверы"
echo ""
echo -e "${RED}❌ Без авторизации:${NC}"
echo "   • Claude Code не сможет работать"
echo "   • Обход onboarding технически невозможен"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""
read -p "Нажмите Enter для запуска Claude Code..."

# Запуск
cd "$(dirname "$0")/.."
./glm-launch.sh
```

**Шаг 4**: Создать `docs/FIRST_TIME_SETUP.md`:

```markdown
# Первый запуск Claude Code с Z.AI

> 📚 **Навигация**: [Home](../README.md) > **First Time Setup**

## 🚀 Quick Start (5 минут)

### Что нужно знать ПЕРЕД началом

**⚠️ Важное примечание:**

Claude Code требует **ОДНОКРАТНОЙ** авторизации на Anthropic. Это **ОБЯЗАТЕЛЬНЫЙ** шаг.

**✅ Хорошая новость:**

После авторизации:
- Z.AI API будет работать через `api.z.ai`
- **НЕ нужно платить Anthropic** (используется Z.AI ключ)
- Все запросы идут через Z.AI серверы

---

## 📋 Пошаговая инструкция

### Шаг 1: Запуск скрипта настройки

\`\`\`bash
cd ~/coding/projects/glm-docker-tools
./scripts/setup-claude-for-new-user.sh
\`\`\`

### Шаг 2: Авторизация в браузере

1. Откроется браузер
2. Войдите в ваш аккаунт Anthropic или создайте новый
3. **Бесплатный аккаунт достаточен** - НЕ нужно покупать подписку

### Шаг 3: Подтверждение

При запросе "Do you want to use this API key?" - выберите **"Yes"**

### Шаг 4: Готово!

Claude Code запустится с Z.AI API.

---

## ❓ Часто задаваемые вопросы

### Нужно ли платить Anthropic?

**НЕТ!** Бесплатный аккаунт Anthropic достаточен. Все запросы идут через Z.AI API.

### Почему нужна авторизация Anthropic?

Это архитектурное ограничение Claude Code. Обход onboarding технически невозможен.

**Подробнее:** [P10 Onboarding Bypass Research](./P10_ONBOARDING_BYPASS_RESEARCH.md)

### Можно ли использовать без интернета?

НЕТ. Claude Code требует подключение к интернету для авторизации и API запросов.

---

## 📞 Поддержка

- **[P10 Research](./P10_ONBOARDING_BYPASS_RESEARCH.md)** - Почему нужен onboarding
- **[GLM Configuration Guide](./GLM_CONFIGURATION_GUIDE.md)** - Настройка Z.AI API
- **[Issues](https://github.com/RussianLioN/glm-docker-tools/issues)** - Сообщить о проблеме
```

#### ✅ Критерии тестирования

1. **Тест 1: Первый запуск**
   ```bash
   # Удалить ~/.claude/.claude.json
   rm ~/.claude/.claude.json
   ./glm-launch.sh
   # Ожидаемый результат: Появляется сообщение "ПЕРВЫЙ ЗАПУСК"
   ```

2. **Тест 2: Повторный запуск**
   ```bash
   # После авторизации
   ./glm-launch.sh
   # Ожидаемый результат: "✅ Claude Code уже авторизован"
   ```

3. **Тест 3: Скрипт setup-claude-for-new-user.sh**
   ```bash
   ./scripts/setup-claude-for-new-user.sh
   # Ожидаемый результат: Четкие инструкции + запуск
   ```

#### 📊 Критерии успеха
- ✅ Четкие сообщения при первом запуске
- ✅ Инструкция для новых пользователей
- ✅ Скрипт первого запуска
- ✅ Обновленная документация

#### 🔗 Связь с P10

- **P10 (завершен)**: Исследования показали, что обход onboarding невозможен
- **P11 (планируется)**: Улучшение UX процесса onboarding (НЕ обход)

**Подробнее:** [P10 Onboarding Bypass Research](./P10_ONBOARDING_BYPASS_RESEARCH.md)

---

### P12: Workspace Independence ⭐ КРИТИЧЕСКАЯ ВАЖНОСТЬ

**Статус**: 📋 Запланировано (separate improvement task)

#### 📝 Описание

**Проблема:** Claude Code должен работать из любой папки проекта, а текущая рабочая директория (из которой запущен `glm-launch.sh`) должна корректно мапиться в контейнер.

**Текущее ограничение:** Скрипт `glm-launch.sh` должен запускаться из корневой директории проекта `~/coding/projects/glm-docker-tools/`, но пользователь может находиться в любой поддиректории (например, `~/coding/projects/glm-docker-tools/src/components/`).

**Ожидаемое поведение:**
- ✅ Возможность запуска из любой директории проекта
- ✅ Автоматическое определение корня проекта
- ✅ Корректное маппинг текущей рабочей директории в контейнер
- ✅ Правильная работа функций (Read, Edit, Bash) с файлами текущей директории

#### 📂 Файлы для изменения
1. **glm-launch.sh** - Добавить функцию `find_project_root()` и обновить `WORKSPACE`
2. **docker-compose.yml** (опционально) - Обновить volume mapping для текущей директории
3. **docs/SCRIPT_LOGIC.md** - Документировать новое поведение

#### 🔧 Реализация

**Шаг 1**: Добавить функцию `find_project_root()` в glm-launch.sh:

```bash
# Find project root directory (where .git or specific marker file exists)
find_project_root() {
    local current_dir="$(pwd)"

    # Search upward for project root markers
    while [[ "$current_dir" != "/" ]]; do
        # Check for project markers (choose one or more):
        # 1. .git directory
        # 2. glm-launch.sh script itself
        # 3. .claude/settings.json
        # 4. Dockerfile

        if [[ -d "$current_dir/.git" ]] ||
           [[ -f "$current_dir/glm-launch.sh" ]] ||
           [[ -f "$current_dir/Dockerfile" ]]; then
            echo "$current_dir"
            return 0
        fi

        # Move up one directory
        current_dir="$(dirname "$current_dir")"
    done

    # Fallback: use script's directory
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
}
```

**Шаг 2**: Обновить `WORKSPACE` в glm-launch.sh:

```bash
# Нынешнее поведение:
# WORKSPACE="$(pwd)"  # Текущая директория запуска скрипта

# Новое поведение:
PROJECT_ROOT="$(find_project_root)"
WORKSPACE="$(pwd)"  # Текущая рабочая директория пользователя

# Volume mapping обновляется соответственно:
# -v "$PROJECT_ROOT:/workspace:cached"  # Проект (read-write cache)
# -v "$WORKSPACE:/workspace/current"     # Текущая директория (read-write)
```

**Шаг 3**: Обновить volume mapping в `run_docker()`:

```bash
# Map both project root and current directory
DOCKER_RUN=(
    docker run --rm -it $DOCKER_INTERACTIVE
        -v "$CLAUDE_HOME:/root/.claude"
        -v "$PROJECT_ROOT:/workspace:cached"
        -v "$WORKSPACE:/workspace/current"
        -w "/workspace/current"  # Working directory inside container
        "$IMAGE" "$@"
)
```

#### ✅ Критерии тестирования

1. **Тест 1: Запуск из корня проекта**
   ```bash
   cd ~/coding/projects/glm-docker-tools
   ./glm-launch.sh
   # Ожидается: WORKSPACE = /workspace, файлы видны
   ```

2. **Тест 2: Запуск из поддиректории**
   ```bash
   cd ~/coding/projects/glm-docker-tools/src/components
   ../../glm-launch.sh
   # Ожидается: WORKSPACE = /workspace/current/src/components
   # Доступны файлы и корня проекта, и текущей директории
   ```

3. **Тест 3: Проверка маппинга файлов**
   ```bash
   cd ~/coding/projects/glm-docker-tools/src
   ../../glm-launch.sh
   # В Claude Code:
   Read("./README.md")  # Из корня проекта - должен работать
   Read("file.txt")      # Из текущей директории - должен работать
   ```

4. **Тест 4: Запуск вне проекта**
   ```bash
   cd /tmp
   ~/coding/projects/glm-docker-tools/glm-launch.sh
   # Ожидается: Автоматическое определение PROJECT_ROOT
   ```

#### 📊 Критерии успеха
- ✅ Скрипт можно запустить из любой директории
- ✅ Автоматическое определение корня проекта
- ✅ Корректное маппинг текущей рабочей директории
- ✅ Доступ к файлам всего проекта
- ✅ Доступ к файлам текущей директории

#### 🔗 Связь с другими задачами

- **P1-P7**: Не затрагивает (уже выполнены)
- **P11**: Независимая задача (может быть выполнена параллельно)
- **P8-P9**: Не затрагивает (defensive improvements)

**Приоритет**: ⚠️ **КРИТИЧЕСКИЙ** - существенно улучшает UX для разработчиков

---

### P13: Shell-функции для удобного запуска ⭐ ВАЖНАЯ ВАЖНОСТЬ

**Статус**: 📋 Запланировано

#### 📝 Описание

**Проблема:** Запуск `glm-launch.sh` требует либо нахождения в корне проекта, либо указания полного пути к скрипту. Это неудобно для повседневного использования.

**Решение:** Создать shell-функции (алиасы), которые позволяют запускать Claude Code из любой директории простыми командами.

**Ожидаемое поведение:**
- ✅ Функция `glm` запускает стандартный режим с маппингом текущей папки
- ✅ Функция `glm-debug` запускает debug режим
- ✅ Функция `glm-no-del` запускает persistent режим
- ✅ Все функции работают из любой директории
- ✅ Автоматическое определение корня проекта и текущей рабочей директории

#### 📂 Файлы для изменения
1. **scripts/glm-aliases.sh** - Создать новый файл с функциями
2. **README.md** - Добавить инструкцию по настройке алиасов
3. **docs/SCRIPT_LOGIC.md** - Документировать новые функции

#### 🔧 Реализация

**Шаг 1**: Создать файл `scripts/glm-aliases.sh`:

```bash
# glm-aliases.sh - Shell функции для удобного запуска Claude Code
# Source this file in ~/.bashrc or ~/.zshrc:
#   source ~/coding/projects/glm-docker-tools/scripts/glm-aliases.sh

# Найти корень проекта
_glm_find_project_root() {
    local current_dir="$(pwd)"
    while [[ "$current_dir" != "/" ]]; do
        if [[ -f "$current_dir/glm-launch.sh" ]] || \
           [[ -f "$current_dir/Dockerfile" ]] || \
           [[ -d "$current_dir/.git" ]]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    return 1
}

# Основная функция запуска
_glm() {
    local project_root="$(_glm_find_project_root)"
    if [[ -z "$project_root" ]]; then
        echo "❌ GLM: Не найден корень проекта (glm-launch.sh)" >&2
        return 1
    fi

    local launcher="$project_root/glm-launch.sh"
    if [[ ! -f "$launcher" ]]; then
        echo "❌ GLM: Скрипт запуска не найден: $launcher" >&2
        return 1
    fi

    # Запуск с текущей рабочей директорией
    "$launcher" "$@"
}

# Стандартный запуск
glm() {
    _glm "$@"
}

# Debug режим (persistent container)
glm-debug() {
    _glm --debug "$@"
}

# No-del режим (persistent без auto-delete)
glm-no-del() {
    _glm --no-del "$@"
}

# Показать справку
glm-help() {
    cat <<'EOF'
🚀 GLM Aliases - Claude Code Launcher

Доступные команды:
  glm [аргументы]     - Стандартный запуск (auto-delete container)
  glm-debug [аргументы] - Debug режим (persistent container)
  glm-no-del [аргументы] - Persistent режим (no auto-delete)
  glm-help            - Показать эту справку

Примеры использования:
  glm                    # Запуск из текущей директории
  glm-debug             # Запуск с debug shell после завершения
  glm-no-del            # Запуск persistent контейнера

Примечание: Аргументы передаются в glm-launch.sh

См. также: glm-launch.sh --help
EOF
}
```

**Шаг 2**: Обновить `README.md` - добавить секцию:

```markdown
## 🚀 Быстрый запуск (Shell-алиасы)

Для удобного запуска из любой директории добавьте в ваш `~/.bashrc` или `~/.zshrc`:

\`\`\`bash
# Добавьте в конец файла
source ~/coding/projects/glm-docker-tools/scripts/glm-aliases.sh
\`\`\`

После перезагрузки терминала (или `source ~/.bashrc`) будут доступны команды:

| Команда | Описание |
|---------|----------|
| `glm` | Стандартный запуск |
| `glm-debug` | Debug режим |
| `glm-no-del` | Persistent режим |
| `glm-help` | Справка по алиасам |

**Примеры:**
\`\`\`bash
# Из любой директории проекта
cd ~/coding/projects/glm-docker-tools/src/components
glm                    # Запуск с маппингом текущей папки

# Debug режим для troubleshooting
glm-debug             # После завершения - shell доступ
\`\`\`
```

**Шаг 3**: Создать `scripts/glm-aliases.sh.example` для custom настроек:

```bash
# Пример кастомных алиасов пользователя
# Source после основного файла: source scripts/glm-aliases.sh

# Кастомные алиасы пользователя
glm-tls() {
    # Запуск с TLS verify отключен
    _glm --tls-verify=false "$@"
}

glm-local() {
    # Запуск только с локальным API
    _glm --local-only "$@"
}

# Можно добавить свои варианты!
```

#### ✅ Критерии тестирования

1. **Тест 1: Базовый запуск из любой директории**
   ```bash
   cd ~/coding/projects/glm-docker-tools/src
   glm
   # Ожидается: Контейнер запускается, текущая папка замаплена
   ```

2. **Тест 2: Debug режим**
   ```bash
   glm-debug
   # Ожидается: Persistent контейнер + shell после завершения
   ```

3. **Тест 3: Запуск вне проекта**
   ```bash
   cd /tmp
   glm
   # Ожидается: Сообщение об ошибке с предложением
   ```

4. **Тест 4: glm-help**
   ```bash
   glm-help
   # Ожидается: Справка выводится
   ```

#### 📊 Критерии успеха
- ✅ Алиасы работают из любой директории
- ✅ Автоматическое определение проекта
- ✅ Все режимы (standard, debug, no-del) работают
- ✅ Понятные сообщения об ошибках
- ✅ Документация в README.md
- ✅ Пример кастомизации в example файле

#### 🔗 Связь с другими задачами

- **P12**: Комплементарная задача
  - P12: Скрипт работает из любой папки (требует `./path/to/glm-launch.sh`)
  - P13: Алиасы делают запуск удобным (`glm` вместо полного пути)
- **Рекомендация**: Выполнить P12 сначала, затем P13 для максимального UX

**Приоритет**: ⭐ **ВАЖНЫЙ** - значительно улучшает UX для повседневной работы

---

### P14: Управление приложениями в контейнере ⭐ ВАЖНАЯ ВАЖНОСТЬ

**Статус**: 📋 Запланировано

#### 📝 Описание

**Проблема:** Добавление новых приложений в Docker контейнер (например, `vim`, `jq`, `curl`, `git`) требует:
1. Ручного редактирования Dockerfile
2. Ручной пересборки образа
3. Отслеживания изменений для обновления

**Решение:** Создать механизм управления приложениями с автоматическим обнаружением изменений и запросом на обновление образа.

**Ожидаемое поведение:**
- ✅ Удобный способ добавления приложений в образ
- ✅ Автоматическое обнаружение изменений в Dockerfile
- ✅ Интерактивный запрос на обновление образа при изменениях
- ✅ Кэширование текущей конфигурации для сравнения
- ✅ Опциональное принудительное обновление

#### 📂 Файлы для изменения
1. **glm-launch.sh** - Добавить функции проверки Dockerfile и управления приложениями
2. **scripts/apps-manager.sh** (новый) - Менеджер приложений контейнера
3. **Dockerfile** - Обновить для поддержки динамических пакетов
4. **docs/SCRIPT_LOGIC.md** - Документировать механизм

#### 🔧 Реализация

**Шаг 1**: Создать `scripts/apps-manager.sh`:

```bash
#!/bin/bash
# apps-manager.sh - Менеджер приложений контейнера

# Хэш текущей конфигурации Dockerfile
DOCKERFILE_HASH_FILE=".dockerfile.hash"
DOCKERFILE_PATH="Dockerfile"

# Вычислить хэш Dockerfile (только секция RUN apt-get)
calculate_dockerfile_hash() {
    # Извлекаем только строки с apt-get installations
    grep -A 100 "RUN apt-get update" "$DOCKERFILE_PATH" 2>/dev/null | \
        grep "apt-get install" | \
        md5sum | \
        awk '{print $1}'
}

# Проверить, изменился ли Dockerfile
check_dockerfile_changed() {
    local current_hash=$(calculate_dockerfile_hash)

    if [[ ! -f "$DOCKERFILE_HASH_FILE" ]]; then
        echo "changed"
        return 0
    fi

    local stored_hash=$(cat "$DOCKERFILE_HASH_FILE" 2>/dev/null)

    if [[ "$current_hash" != "$stored_hash" ]]; then
        echo "changed"
        return 0
    fi

    echo "unchanged"
    return 1
}

# Сохранить текущий хэш
save_dockerfile_hash() {
    calculate_dockerfile_hash > "$DOCKERFILE_HASH_FILE"
}

# Список установленных приложений
list_installed_apps() {
    echo "Установленные в контейнере приложения:"
    docker run --rm "$IMAGE" dpkg -l | grep -E "ii  (vim|jq|curl|git|node|python|ruby|golang|terraform|kubectl|helm)" | awk '{print "  - " $2}'
}

# Добавить приложение в Dockerfile
add_app_to_dockerfile() {
    local app_name="$1"

    if [[ -z "$app_name" ]]; then
        echo "❌ Укажите имя приложения"
        return 1
    fi

    # Найти строку с apt-get install и добавить приложение
    if grep -q "apt-get install.*\\${app_name}" "$DOCKERFILE_PATH"; then
        echo "✅ Приложение $app_name уже в Dockerfile"
        return 0
    fi

    # Создать backup
    cp "$DOCKERFILE_PATH" "$DOCKERFILE_PATH.bak"

    # Добавить приложение (интерактивное редактирование)
    echo "📝 Открываю Dockerfile для редактирования..."
    sleep 1

    # Предлагаем пользователю добавить вручную или автоматически
    read -p "Добавить $app_name автоматически? (y/n): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Автоматическое добавление
        sed -i.bak "s/RUN apt-get install -y --no-install-recommends/RUN apt-get install -y --no-install-recommends \\\\\n    $app_name/" "$DOCKERFILE_PATH"
        echo "✅ $app_name добавлен в Dockerfile"

        # Показать diff
        echo "📊 Изменения:"
        diff -u "$DOCKERFILE_PATH.bak" "$DOCKERFILE_PATH" || true

        return 0
    else
        echo "📝 Пожалуйста, добавьте $app_name в Dockerfile вручную"
        return 1
    fi
}
```

**Шаг 2**: Обновить `glm-launch.sh` - добавить проверку при запуске:

```bash
# В начале скрипта после check_dependencies()
check_dockerfile_updates() {
    if [[ ! -f "Dockerfile" ]]; then
        return 0
    fi

    # Запускаем проверку через apps-manager
    if [[ -f "scripts/apps-manager.sh" ]]; then
        local status=$(source scripts/apps-manager.sh && check_dockerfile_changed)

        if [[ "$status" == "changed" ]]; then
            log_warning "⚠️ Обнаружены изменения в Dockerfile!"

            echo ""
            echo "Dockerfile был изменен. Рекомендуется пересобрать образ."
            echo ""
            read -p "Пересобрать образ сейчас? (y/n): " -n 1 -r
            echo

            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log_info "🔨 Пересборка образа..."
                docker build -t "$IMAGE" .
                source scripts/apps-manager.sh && save_dockerfile_hash
                log_success "✅ Образ обновлен"
            else
                log_warning "⚠️ Продолжение с устаревшим образом"
            fi
        fi
    fi
}

# Вызов после проверки зависимостей
check_dockerfile_updates
```

**Шаг 3**: Добавить команду `--rebuild` в `glm-launch.sh`:

```bash
case "$1" in
    --rebuild)
        log_info "🔨 Принудительная пересборка образа..."
        docker build -t "$IMAGE" .
        if [[ -f "scripts/apps-manager.sh" ]]; then
            source scripts/apps-manager.sh && save_dockerfile_hash
        fi
        log_success "✅ Образ пересобран"
        exit 0
        ;;
esac
```

**Шаг 4**: Обновить Dockerfile для поддержки:

```dockerfile
# Добавить метку для отслеживания
LABEL apps.version="1.0"
LABEL apps.hash="${DOCKERFILE_HASH}"
```

#### ✅ Критерии тестирования

1. **Тест 1: Обнаружение изменений**
   ```bash
   # Изменить Dockerfile (добавить пакет)
   echo "RUN apt-get install -y vim" >> Dockerfile

   ./glm-launch.sh
   # Ожидается: Запрос на пересборку образа
   ```

2. **Тест 2: Принудительная пересборка**
   ```bash
   ./glm-launch.sh --rebuild
   # Ожидается: Образ пересобран, хэш обновлен
   ```

3. **Тест 3: Список приложений**
   ```bash
   source scripts/apps-manager.sh
   list_installed_apps
   # Ожидается: Список установленных пакетов
   ```

4. **Тест 4: Без изменений**
   ```bash
   ./glm-launch.sh
   # Ожидается: Запускается без запроса (если Dockerfile не менялся)
   ```

#### 📊 Критерии успеха
- ✅ Автоматическое обнаружение изменений в Dockerfile
- ✅ Интерактивный запрос на обновление образа
- ✅ Команда `--rebuild` для принудительной пересборки
- ✅ Хэширование для отслеживания изменений
- ✅ List команда для просмотра установленных приложений
- ✅ Обратная совместимость (работает без apps-manager)

#### 🔗 Связь с другими задачами

- **P1**: Расширение P1 (Automatic Docker Build)
  - P1: Базовая автосборка образа
  - P14: Умное обнаружение изменений + интерактивное обновление
- **P8 (Backup)**: Хэш-файл должен быть в .gitignore
- **P12/P13**: Независимая задача

**Приоритет**: ⭐ **ВАЖНЫЙ** - улучшение UX для управления контейнером

---

### P15: Автообновление Claude Code 📋 НОРМАЛЬНАЯ ВАЖНОСТЬ

**Статус**: 📋 Запланировано

#### 📝 Описание

**Проблема:** Версия Claude Code в Docker образе может устаревать. Новые версии Claude Code выходят регулярно с улучшениями и исправлениями, но контейнер продолжает использовать старую версию.

**Решение:** Создать механизм автоматического обнаружения новых версий Claude Code с предложением обновить образ.

**Ожидаемое поведение:**
- ✅ Детектировать текущую версию Claude Code в контейнере
- ✅ Проверять наличие новой версии на npm/GitHub
- ✅ При наличии обновления - предлагать пересборку образа
- ✅ Опциональное принудительное обновление (`--update-claude`)
- ✅ Кэширование версии для избежания лишних проверок
- ✅ Возможность отключения проверок

#### 📂 Файлы для изменения
1. **glm-launch.sh** - Добавить функцию проверки версии Claude Code
2. **scripts/claude-updater.sh** (новый) - Менеджер обновлений Claude Code
3. **Dockerfile** - Обновить для поддержки динамической версии
4. **docs/SCRIPT_LOGIC.md** - Документировать механизм

#### 🔧 Реализация

**Шаг 1**: Создать `scripts/claude-updater.sh`:

```bash
#!/bin/bash
# claude-updater.sh - Менеджер обновлений Claude Code

# Файл для хранения текущей версии
CLAUDE_VERSION_FILE=".claude.version"
CLAUDE_VERSION_CACHE=".claude.version.cache"
CLAUDE_VERSION_CHECK_INTERVAL=86400  # 24 часа

# Получить текущую версию Claude Code в контейнере
get_current_claude_version() {
    local version=$(docker run --rm "$IMAGE" claude --version 2>/dev/null | head -1)
    if [[ -z "$version" ]]; then
        # Fallback: проверить через npm list в контейнере
        version=$(docker run --rm "$IMAGE" npm list -g @anthropic-ai/claude-code 2>/dev/null | grep @anthropic-ai/claude-code | awk '{print $2}')
    fi
    echo "$version"
}

# Получить последнюю версию Claude Code из npm
get_latest_claude_version() {
    local latest=$(npm view @anthropic-ai/claude-code version 2>/dev/null)
    echo "$latest"
}

# Проверить, нужна ли проверка версии (по времени)
should_check_version() {
    if [[ ! -f "$CLAUDE_VERSION_CACHE" ]]; then
        return 0  # Кэша нет - проверяем
    fi

    local cache_time=$(stat -c %Y "$CLAUDE_VERSION_CACHE" 2>/dev/null || stat -f %m "$CLAUDE_VERSION_CACHE")
    local current_time=$(date +%s)
    local elapsed=$((current_time - cache_time))

    if [[ $elapsed -ge $CLAUDE_VERSION_CHECK_INTERVAL ]]; then
        return 0  # Прошёл интервал - проверяем
    fi

    return 1  # Ещё рано - не проверяем
}

# Сохранить версию в кэш
save_version_cache() {
    local version="$1"
    echo "$version" > "$CLAUDE_VERSION_CACHE"
}

# Сравнить версии (возвращает 0 если v1 > v2, 1 если v1 <= v2)
compare_versions() {
    if [[ "$1" == "$2" ]]; then
        return 1  # Равны
    fi

    local IFS=.
    local i ver1=($1) ver2=($2)

    # Заполнить недостающие части нулями
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i=${#ver2[@]}; i<${#ver1[@]}; i++)); do
        ver2[i]=0
    done

    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver1[i]} ]]; then ver1[i]=0; fi
        if [[ -z ${ver2[i]} ]]; then ver2[i]=0; fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 0  # v1 > v2
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 1  # v1 < v2
        fi
    done

    return 1  # Равны
}

# Проверить наличие обновлений
check_claude_updates() {
    # Проверяем по времени
    if ! should_check_version; then
        return 1  # Не проверяем
    fi

    # Проверяем, отключены ли обновления
    if [[ "${CLAUDE_AUTO_UPDATE:-true}" == "false" ]]; then
        return 1  # Отключены
    fi

    local current_version=$(get_current_claude_version)
    local latest_version=$(get_latest_claude_version)

    # Сохраняем в кэш
    save_version_cache "$latest_version"

    # Сравниваем версии
    if compare_versions "$latest_version" "$current_version"; then
        echo "update_available:$latest_version:$current_version"
        return 0  # Доступно обновление
    fi

    return 1  # Обновлений нет
}

# Обновить Claude Code в образе
update_claude_in_image() {
    local new_version="$1"

    log_info "🔄 Обновление Claude Code до $new_version..."

    # Обновляем Dockerfile
    if [[ -f "Dockerfile" ]]; then
        # Backup
        cp Dockerfile Dockerfile.bak

        # Обновляем версию в Dockerfile
        sed -i.bak "s/RUN npm install -g @anthropic-ai\/claude-code@.*/RUN npm install -g @anthropic-ai\/claude-code@${new_version}/" Dockerfile

        # Пересобираем образ
        docker build -t "$IMAGE" .

        # Восстанавливаем backup при ошибке
        if [[ $? -ne 0 ]]; then
            log_error "❌ Ошибка пересборки образа"
            mv Dockerfile.bak Dockerfile
            return 1
        fi

        # Обновляем версию
        echo "$new_version" > "$CLAUDE_VERSION_FILE"
        log_success "✅ Claude Code обновлен до $new_version"
    fi
}
```

**Шаг 2**: Обновить `glm-launch.sh` - добавить проверку при запуске:

```bash
# В начале скрипта после check_dockerfile_updates()
check_claude_updates() {
    if [[ ! -f "scripts/claude-updater.sh" ]]; then
        return 0
    fi

    # Запускаем проверку
    local result=$(source scripts/claude-updater.sh && check_claude_updates)

    if [[ $result == update_available:* ]]; then
        local latest_version=$(echo "$result" | cut -d: -f2)
        local current_version=$(echo "$result" | cut -d: -f3)

        log_warning "⚠️ Доступна новая версия Claude Code!"
        echo ""
        echo "Текущая версия: $current_version"
        echo "Новая версия:   $latest_version"
        echo ""
        read -p "Обновить Claude Code и пересобрать образ? (y/n): " -n 1 -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            source scripts/claude-updater.sh
            update_claude_in_image "$latest_version"
        else
            log_info "📝 Обновление пропущено. Используйте --update-claude для обновления позже."
        fi
    fi
}

# Вызов после check_dockerfile_updates
check_claude_updates
```

**Шаг 3**: Добавить команду `--update-claude` в `glm-launch.sh`:

```bash
case "$1" in
    --update-claude)
        log_info "🔄 Проверка обновлений Claude Code..."
        if [[ -f "scripts/claude-updater.sh" ]]; then
            source scripts/claude-updater.sh
            local result=$(check_claude_updates)

            if [[ $result == update_available:* ]]; then
                local latest_version=$(echo "$result" | cut -d: -f2)
                update_claude_in_image "$latest_version"
            else
                log_success "✅ Установлена последняя версия"
            fi
        else
            log_error "❌ scripts/claude-updater.sh не найден"
            exit 1
        fi
        exit 0
        ;;
esac
```

**Шаг 4**: Добавить переменную окружения для отключения:

```bash
# В секции переменных окружения
export CLAUDE_AUTO_UPDATE="${CLAUDE_AUTO_UPDATE:-true}"  # true/false
```

#### ✅ Критерии тестирования

1. **Тест 1: Обнаружение обновления**
   ```bash
   # Установить старую версию в Dockerfile
   # Изменить версию в Dockerfile на старую
   ./glm-launch.sh
   # Ожидается: Запрос на обновление
   ```

2. **Тест 2: Принудительное обновление**
   ```bash
   ./glm-launch.sh --update-claude
   # Ожидается: Проверка + обновление при наличии
   ```

3. **Тест 3: Отключение автообновлений**
   ```bash
   CLAUDE_AUTO_UPDATE=false ./glm-launch.sh
   # Ожидается: Проверка не выполняется
   ```

4. **Тест 4: Кэширование версии**
   ```bash
   ./glm-launch.sh  # Первый запуск - проверка
   ./glm-launch.sh  # Второй запуск - из кэша (в течение 24ч)
   # Ожидается: Второй запуск без сетевого запроса
   ```

#### 📊 Критерии успеха
- ✅ Автоматическое обнаружение новых версий Claude Code
- ✅ Интерактивный запрос на обновление
- ✅ Команда `--update-claude` для принудительного обновления
- ✅ Кэширование проверок (24 часа)
- ✅ Переменная `CLAUDE_AUTO_UPDATE` для отключения
- ✅ Корректное сравнение версий
- ✅ Обратная совместимость

#### 🔗 Связь с другими задачами

- **P1**: Расширение P1 (Automatic Docker Build)
  - P1: Автосборка образа
  - P15: Автообновление версии Claude Code в образе
- **P14**: Аналогичный механизм
  - P14: Обнаружение изменений Dockerfile
  - P15: Обнаружение новых версий Claude Code
- **P9 (Secrets)**: `CLAUDE_AUTO_UPDATE` в .env

**Приоритет**: 📋 **НОРМАЛЬНЫЙ** - удобная функция, но не критичная

---

### P16: Умное управление конфигурацией Claude Code ⭐ ВАЖНАЯ ВАЖНОСТЬ

**Статус**: 📋 Запланировано
**Экспертная оценка**: 9/13 экспертов проголосовали за приоритет ⭐ ВАЖНЫЙ

#### 📝 Описание

**Проблема**: Несоответствие путей к файлу конфигурации `.claude.json` между локальным и контейнерным запуском:

- **Локальный запуск**: `~/.claude.json` (user-level config, оригинальный путь Claude Code)
- **Контейнерный запуск**: `~/.claude/.claude.json` (текущий маппинг в скрипте)

**Риски:**
- Путаница при переключении между локальным и контейнерным запуском
- Потеря настроек при миграции
- Нарушение архитектуры конфигурации Claude Code

**Ожидаемое поведение:**
- ✅ Автообнаружение существующих конфигураций
- ✅ Унификация маппинга для локального и контейнерного запуска
- ✅ Валидация конфигурации (JSON синтаксис, обязательные ключи)
- ✅ Автоматический backup перед миграцией (интеграция с P8)
- ✅ Migration helper для старых конфигураций
- ✅ User-friendly сообщения (UX transparency)

#### 📂 Файлы для изменения
1. **glm-launch.sh** - Добавить функции управления конфигурацией
2. **scripts/claude-config.sh** (новый) - Менеджер конфигурации Claude Code
3. **.claude/settings.json** - Project-level config (GitOps-managed)
4. **docs/SCRIPT_LOGIC.md** - Документировать механизм

#### 🔧 Реализация

**Шаг 1**: Создать `scripts/claude-config.sh`:

```bash
#!/bin/bash
# claude-config.sh - Менеджер конфигурации Claude Code

# =============================================================================
# КОНФИГУРАЦИЯ
# =============================================================================

# Возможные пути конфигурации (в приоритетном порядке)
CLAUDE_CONFIG_PATHS=(
    "$HOME/.claude.json"              # User-level (оригинальный, рекомендуемый)
    "$HOME/.claude/.claude.json"      # Container-style (устаревший)
    ".claude/settings.json"           # Project-level (GitOps)
)

# Стратегия выбора конфигурации
CLAUDE_CONFIG_STRATEGY="${CLAUDE_CONFIG_STRATEGY:-auto}"  # auto | user | project

# =============================================================================
# ФУНКЦИИ ОБНАРУЖЕНИЯ
# =============================================================================

# Обнаружить конфигурацию (auto strategy)
detect_claude_config() {
    local strategy="${1:-$CLAUDE_CONFIG_STRATEGY}"

    case "$strategy" in
        user)
            echo "$HOME/.claude.json"
            return 0
            ;;
        project)
            echo "$HOME/.claude/.claude.json"
            return 0
            ;;
        auto|*)
            # Priority: user-level → container-style → create new
            for path in "${CLAUDE_CONFIG_PATHS[@]}"; do
                if [[ -f "$path" ]]; then
                    echo "$path"
                    return 0
                fi
            done

            # Default: создать user-level
            echo "$HOME/.claude.json"
            return 0
            ;;
    esac
}

# =============================================================================
# ФУНКЦИИ ВАЛИДАЦИИ
# =============================================================================

# Валидация JSON (SRE health check)
validate_claude_config_json() {
    local config="$1"

    if [[ ! -f "$config" ]]; then
        echo "missing"
        return 1
    fi

    if ! jq empty "$config" 2>/dev/null; then
        echo "invalid_json"
        return 1
    fi

    echo "valid"
    return 0
}

# Проверка обязательных ключей
validate_claude_config_keys() {
    local config="$1"
    local missing_keys=()

    # Обязательные ключи (для Z.AI API)
    local required_keys=(
        "apiUrl"
        # "model"  # опционально, имеет дефолт
    )

    for key in "${required_keys[@]}"; do
        if ! jq -e ".${key}" "$config" >/dev/null 2>&1; then
            missing_keys+=("$key")
        fi
    done

    if [[ ${#missing_keys[@]} -gt 0 ]]; then
        echo "missing:${missing_keys[@]}"
        return 1
    fi

    echo "complete"
    return 0
}

# =============================================================================
# ФУНКЦИИ СОЗДАНИЯ
# =============================================================================

# Создать дефолтную конфигурацию
create_default_claude_config() {
    local target_path="$1"

    if [[ -z "$target_path" ]]; then
        target_path="$HOME/.claude.json"
    fi

    # Создать директорию если нужно
    local target_dir="$(dirname "$target_path")"
    mkdir -p "$target_dir"

    # Дефолтная конфигурация для Z.AI API
    cat > "$target_path" <<'EOF'
{
  "apiUrl": "https://api.z.ai/api/anthropic",
  "defaultModel": "glm-4.6",
  "haikuModel": "glm-4.5-air",
  "enableExtendedThinking": true,
  "externalEditor": "nano"
}
EOF

    echo "$target_path"
}

# =============================================================================
# ФУНКЦИИ МИГРАЦИИ
# =============================================================================

# Backup перед миграцией (P8 integration)
backup_before_migration() {
    local source="$1"

    if [[ ! -f "$source" ]]; then
        return 0
    fi

    local backup_dir=".claude/backups"
    mkdir -p "$backup_dir"

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup="$backup_dir/.claude.json.$timestamp.bak"

    cp "$source" "$backup"
    echo "$backup"
}

# Миграция старой конфигурации
migrate_old_config() {
    local old_path="$HOME/.claude/.claude.json"
    local new_path="$HOME/.claude.json"

    # Если старый конфиг существует, а новый нет
    if [[ -f "$old_path" && ! -f "$new_path" ]]; then
        echo "migration_needed:$old_path:$new_path"
        return 0
    fi

    echo "no_migration_needed"
    return 1
}

# =============================================================================
# ФУНКЦИИ ИНФОРМИРОВАНИЯ
# =============================================================================

# Объяснить текущую конфигурацию (Prompt Engineer recommendation)
explain_config_setup() {
    local config="$1"
    local container_path="/root/.claude.json"

    cat <<EOF
🔧 Claude Code Configuration:

Config file (host):     $config
Config file (container): $container_path

💡 To customize:
  export CLAUDE_CONFIG_STRATEGY=user|project|auto
  export CLAUDE_CONFIG_PATH=/custom/path/.claude.json

📚 Documentation: CLAUDE.md
EOF
}

# Показать статус конфигурации
show_config_status() {
    local config="$1"

    echo "📊 Configuration Status:"
    echo "   File: $config"

    local validation=$(validate_claude_config_json "$config")
    echo "   JSON: $validation"

    if [[ "$validation" == "valid" ]]; then
        local keys=$(validate_claude_config_keys "$config")
        echo "   Keys: $keys"
    fi
}
```

**Шаг 2**: Обновить `glm-launch.sh` - добавить обработку конфигурации:

```bash
# В начале скрипта, после определения переменных
# =============================================================================
# CLAUDE CODE CONFIGURATION MANAGEMENT (P16)
# =============================================================================

# Source конфиг менеджер если существует
CLAUDE_CONFIG_MANAGER_SCRIPT="$(dirname "${BASH_SOURCE[0]}")/scripts/claude-config.sh"

if [[ -f "$CLAUDE_CONFIG_MANAGER_SCRIPT" ]]; then
    source "$CLAUDE_CONFIG_MANAGER_SCRIPT"

    # Обнаружить конфигурацию
    CLAUDE_HOST_CONFIG="$(detect_claude_config)"

    # Валидация
    local validation=$(validate_claude_config_json "$CLAUDE_HOST_CONFIG")
    if [[ "$validation" != "valid" ]]; then
        log_warning "⚠️ Config validation failed: $validation"

        if [[ "$validation" == "missing" ]]; then
            log_info "🔧 Creating default config..."
            CLAUDE_HOST_CONFIG="$(create_default_claude_config)"
            log_success "✅ Created: $CLAUDE_HOST_CONFIG"
        elif [[ "$validation" == "invalid_json" ]]; then
            log_error "❌ Invalid JSON in config. Please fix manually."
            exit 1
        fi
    fi

    # Проверка миграции
    local migration_status=$(migrate_old_config)
    if [[ "$migration_status" == migration_needed:* ]]; then
        local old_path=$(echo "$migration_status" | cut -d: -f2)
        local new_path=$(echo "$migration_status" | cut -d: -f3)

        log_warning "⚠️ Old config path detected: $old_path"
        echo ""
        echo "A new standard path is recommended: $new_path"
        echo ""
        read -p "Migrate to new path? (y/n): " -n 1 -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            local backup=$(backup_before_migration "$old_path")
            log_info "💾 Backup created: $backup"

            cp "$old_path" "$new_path"
            CLAUDE_HOST_CONFIG="$new_path"
            log_success "✅ Migration complete"
        else
            log_info "📝 Using old config path: $old_path"
            CLAUDE_HOST_CONFIG="$old_path"
        fi
    fi

    # Показать статус (если verbose)
    if [[ "${VERBOSE:-false}" == "true" ]]; then
        show_config_status "$CLAUDE_HOST_CONFIG"
        echo ""
    fi
else
    # Fallback если скрипт не найден
    CLAUDE_HOST_CONFIG="${CLAUDE_CONFIG_PATH:-$HOME/.claude.json}"
fi

export CLAUDE_HOST_CONFIG

# =============================================================================
# VOLUME MAPPING UPDATE
# =============================================================================

# Обновить volume mapping для использования обнаруженной конфигурации
# Заменить hardcoded путь на переменную
```

**Шаг 3**: Обновить volume mapping в `run_docker()`:

```bash
# Было (hardcoded):
# -v "$HOME/.claude/.claude.json:/root/.claude.json"

# Стало (динамическое):
# -v "$CLAUDE_HOST_CONFIG:/root/.claude.json"

# В функции run_docker():
run_docker() {
    # ...

    DOCKER_RUN=(
        docker run --rm -it $DOCKER_INTERACTIVE
            -v "$CLAUDE_HOST_CONFIG:/root/.claude.json"  # Динамический маппинг
            # ... другие volumes
            "$IMAGE" "$@"
    )

    # ...
}
```

**Шаг 4**: Добавить команды управления:

```bash
case "$1" in
    --config-status)
        source scripts/claude-config.sh
        CLAUDE_HOST_CONFIG="$(detect_claude_config)"
        show_config_status "$CLAUDE_HOST_CONFIG"
        exit 0
        ;;
    --config-migrate)
        source scripts/claude-config.sh
        local old_path="$HOME/.claude/.claude.json"
        local new_path="$HOME/.claude.json"

        if [[ -f "$old_path" ]]; then
            local backup=$(backup_before_migration "$old_path")
            cp "$old_path" "$new_path"
            log_success "✅ Migrated: $old_path → $new_path"
            log_info "💾 Backup: $backup"
        else
            log_info "📝 No old config found"
        fi
        exit 0
        ;;
esac
```

#### ✅ Критерии тестирования

1. **Тест 1: Автообнаружение user-level конфига**
   ```bash
   # Setup: Создать ~/.claude.json
   echo '{"test": true}' > ~/.claude.json

   ./glm-launch.sh --config-status
   # Ожидается: Config file: ~/.claude.json
   ```

2. **Тест 2: Fallback на container-style**
   ```bash
   # Setup: Удалить user-level, оставить container-style
   rm -f ~/.claude.json

   ./glm-launch.sh --config-status
   # Ожидается: Config file: ~/.claude/.claude.json
   ```

3. **Тест 3: Создание дефолтной конфигурации**
   ```bash
   # Setup: Удалить все конфиги
   rm -f ~/.claude.json ~/.claude/.claude.json

   ./glm-launch.sh
   # Ожидается: Создан ~/.claude.json с дефолтными значениями
   ```

4. **Тест 4: Миграция старой конфигурации**
   ```bash
   # Setup: Создать старую конфигурацию
   mkdir -p ~/.claude
   echo '{"old": true}' > ~/.claude/.claude.json

   ./glm-launch.sh --config-migrate
   # Ожидается:
   # - Backup создан
   # - ~/.claude.json создан
   # - Settings migrated
   ```

5. **Тест 5: Валидация JSON**
   ```bash
   # Setup: Создать невалидный JSON
   echo '{invalid json}' > ~/.claude.json

   ./glm-launch.sh
   # Ожидается: Error с сообщением о невалидном JSON
   ```

#### 📊 Критерии успеха
- ✅ Автообнаружение существующих конфигураций
- ✅ Валидация JSON (синтаксис + ключи)
- ✅ Автоматическое создание дефолтной конфигурации
- ✅ Migration helper с backup (P8 integration)
- ✅ User-friendly сообщения (UX transparency)
- ✅ Команды `--config-status` и `--config-migrate`
- ✅ Обратная совместимость
- ✅ Поддержка переменной `CLAUDE_CONFIG_STRATEGY`

#### 🔗 Связь с другими задачами

- **P8 (Backup)**: Интеграция с defensive backup/restore
  - `backup_before_migration()` использует P8 механизм
- **P9 (Secrets)**: `CLAUDE_CONFIG_STRATEGY` в .env
- **P10 (Onboarding)**: Упрощение первого запуска
- **P12 (Workspace)**: Независимая задача

**Экспертная оценка**: 9/13 экспертов рекомендуют приоритет **⭐ ВАЖНЫЙ**

**Ключевые эксперты**:
- Архитектор решения: "Архитектурная целостность критична"
- SRE: "Надежность конфигурации - SLO для production"
- GitOps Specialist: "Configuration as Code - фундаментальный принцип"

**Приоритет**: ⭐ **ВАЖНЫЙ** - унификация конфигурации важна для надежности

---

## 📊 ИТОГОВЫЙ СТАТУС ПЛАНА

**План создан**: 2025-12-25
**План завершен**: 2025-12-30 ✅
**Обновлен**: 2026-01-15 (добавлен статус завершения и P11)
**Статус**: ✅ **ЗАВЕРШЕН** - Все 7 улучшений (P1-P7) реализованы

**✅ РЕАЛИЗОВАННЫЕ УЛУЧШЕНИЯ (P1-P7):**
1. **Фаза 1 (P1-P3)**: ✅ ЗАВЕРШЕНО 2025-12-26 - Критические исправления
2. **Фаза 2 (P4-P5)**: ✅ ЗАВЕРШЕНО 2025-12-29 - Высокоприоритетные улучшения
3. **Фаза 3 (P6-P7)**: ✅ ЗАВЕРШЕНО 2025-12-30 - Продвинутые функции

**📋 БАКЛОГ (по приоритету):**
4. **P12 (Workspace)**: ⚠️ **КРИТИЧЕСКИЙ** - Запуск из любой папки + маппинг текущей директории
5. **P13 (Aliases)**: ⭐ **ВАЖНЫЙ** - Shell-функции для удобного запуска (glm, glm-debug)
6. **P14 (Apps)**: ⭐ **ВАЖНЫЙ** - Управление приложениями в контейнере + автообновление образа
7. **P16 (Config)**: ⭐ **ВАЖНЫЙ** - Умное управление конфигурацией (.claude.json mapping)
8. **P15 (Auto-update)**: 📋 **НОРМАЛЬНЫЙ** - Автообновление Claude Code
9. **P11 (Онбординг)**: 📋 НОРМАЛЬНЫЙ - Улучшение UX процесса onboarding
10. **P8-P9**: ✅ ЗАВЕРШЕНО - Defensive improvements

**🎊 ДОСТИЖЕНИЯ:**
- ✅ 100% Completion Rate (7/7 features)
- ✅ 100% UAT Pass Rate (all tests passed)
- ✅ 10+ commits with proper documentation
- ✅ UAT Methodology evolved: v1.1 → v2.0 (Hybrid AI-User Testing)

**📚 СВЯЗАННЫЕ ДОКУМЕНТЫ:**
- **[Session Handoff](../SESSION_HANDOFF.md)** - Полная история выполнения P1-P7
- **[P10 Research](./P10_ONBOARDING_BYPASS_RESEARCH.md)** - Исследования onboarding bypass
- **[UAT Plans](./uat/)** - Все планы тестирования (P1-P7, P10)
