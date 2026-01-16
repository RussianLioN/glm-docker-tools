# Логика Работы Скрипта GLM Docker Tools

> 📋 **КРИТИЧЕСКАЯ ЛОГИКА** | [Home](../README.md) > [CLAUDE.md](../CLAUDE.md) > **Script Logic**

**⚠️ СТАТУС**: 🔴 **ОБЯЗАТЕЛЬНОЕ ПРОЧТЕНИЕ КАЖДУЮ СЕССИЮ**

**Создано**: 2025-12-30
**Обновлено**: 2026-01-16
**Версия**: 2.1 (P12+B Current-First + P13 Shell Aliases)

---

## 🎯 Назначение

Этот документ фиксирует **критическую логику работы** скрипта `glm-launch.sh`, механизма управления настройками (P8: Settings Isolation) и секретами (P9: Secrets Management).

**ВАЖНО**: При любом изменении кода, связанного с settings management, этот документ ДОЛЖЕН быть обновлен ПЕРВЫМ.

---

## 🔴 Критическая Логика Settings Management

### 1. Приоритет Конфигурационных Файлов

```
┌─────────────────────────────────────────────────────────────┐
│                    ПРИОРИТЕТ ФАЙЛОВ                         │
└─────────────────────────────────────────────────────────────┘

PRIMARY (приоритет):
  📁 ./.claude/settings.json
     ↳ Проектный GLM конфигурационный файл
     ↳ Используется контейнером В ПЕРВУЮ ОЧЕРЕДЬ
     ↳ Содержит GLM API настройки + токен

SECONDARY (игнорируется для GLM):
  📁 ~/.claude/settings.json
     ↳ Системный конфигурационный файл (например, Claude Pro)
     ↳ Используется для OAuth tokens, chat history (shared)
     ↳ НЕ используется для API endpoint в GLM контейнере
```

**Правило**: Проектный файл ВСЕГДА перекрывает системный для API settings.

---

### 2. Токен Аутентификации (ANTHROPIC_AUTH_TOKEN)

```
┌─────────────────────────────────────────────────────────────┐
│              РАСПОЛОЖЕНИЕ ТОКЕНА                            │
└─────────────────────────────────────────────────────────────┘

✅ ПРАВИЛЬНО:
   Токен В ФАЙЛЕ: ./.claude/settings.json
   {
     "ANTHROPIC_AUTH_TOKEN": "your_actual_glm_api_key"
   }

❌ НЕПРАВИЛЬНО:
   • Токен в переменной окружения (export ANTHROPIC_AUTH_TOKEN=...)
   • Токен в системном файле (~/.claude/settings.json)
   • Токен отсутствует в проектном файле

❌ НИКОГДА:
   • Не коммитить токен в Git (файл в .gitignore)
   • Не хранить токен в открытом виде в документации
```

**Правило**: Токен СТРОГО в проектном `.claude/settings.json`, nowhere else.

---

### 3. Обязательные Поля в settings.json

**Минимальная валидная конфигурация**:
```json
{
  "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic",
  "ANTHROPIC_MODEL": "glm-4.7",
  "ANTHROPIC_AUTH_TOKEN": "your_glm_api_key_here"
}
```

**Полная рекомендованная конфигурация**:
```json
{
  "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic",
  "ANTHROPIC_MODEL": "glm-4.7",
  "ANTHROPIC_AUTH_TOKEN": "your_glm_api_key_here",
  "ANTHROPIC_HAIKU_MODEL": "glm-4.5-air"
}
```

**Таблица полей**:
| Поле | Обязательность | Описание | Значение по умолчанию |
|------|---------------|----------|----------------------|
| `ANTHROPIC_BASE_URL` | ✅ REQUIRED | GLM API endpoint | `https://api.z.ai/api/anthropic` |
| `ANTHROPIC_MODEL` | ✅ REQUIRED | GLM модель по умолчанию | `glm-4.7` |
| `ANTHROPIC_AUTH_TOKEN` | ✅ REQUIRED | GLM API ключ | (пользователь должен указать) |
| `ANTHROPIC_HAIKU_MODEL` | ⚪ OPTIONAL | GLM haiku модель | `glm-4.5-air` |

---

### 4. Auto-Create Логика

**Если `./.claude/settings.json` отсутствует**, скрипт автоматически создает его:

```
┌─────────────────────────────────────────────────────────────┐
│              AUTO-CREATE PRIORITY                           │
└─────────────────────────────────────────────────────────────┘

Priority 1: Template-based
   IF ./.claude/settings.template.json EXISTS
   THEN copy to ./.claude/settings.json
   ✅ Преимущество: пользователь может кастомизировать template

Priority 2: Hardcoded fallback
   IF template NOT exists
   THEN create from hardcoded config:
   {
     "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic",
     "ANTHROPIC_MODEL": "glm-4.7",
     "ANTHROPIC_AUTH_TOKEN": "YOUR_GLM_API_KEY_HERE",
     "ANTHROPIC_HAIKU_MODEL": "glm-4.5-air"
   }
   ⚠️  Placeholder токен! Пользователь должен заменить.
```

**Функция**: `auto_create_project_settings()` (glm-launch.sh:169-202)

**Важно**:
- ✅ Создание SILENT (без предупреждений)
- ✅ Файл создается с правами `600` (только owner)
- ✅ Логируется: "📝 Создан GLM конфигурационный файл..."

---

### 5. Validation (validate_glm_settings)

**Что проверяет** `validate_glm_settings()` (glm-launch.sh:138-166):

```
┌─────────────────────────────────────────────────────────────┐
│              VALIDATION CHECKS                              │
└─────────────────────────────────────────────────────────────┘

Check 1: File exists
   ✅ ./.claude/settings.json существует

Check 2: JSON syntax valid
   ✅ jq empty $file выполняется без ошибок

Check 3: GLM markers present
   ✅ Файл содержит "api.z.ai" ИЛИ "glm-[0-9]"
   Пример: grep -qE "api\.z\.ai|glm-[0-9]"

Check 4: Required fields present
   ✅ ANTHROPIC_BASE_URL exists
   ✅ ANTHROPIC_MODEL exists
   ✅ ANTHROPIC_AUTH_TOKEN exists (В ФАЙЛЕ!)
```

**Результат**:
- ✅ Все проверки пройдены → `return 0` (success)
- ❌ Любая проверка failed → `return 1` + error message

**Пример ошибок**:
```
❌ "Invalid JSON in settings.json"
❌ "Not a GLM configuration (missing api.z.ai or glm model)"
❌ "Missing required fields in settings.json"
```

---

### 6. Backup/Restore Механизм (Defensive Implementation)

**Функции**:
- `backup_system_settings()` (glm-launch.sh:205-276)
- `restore_system_settings()` (glm-launch.sh:278-351)

**Что бэкапится**:
```
✅ BACKUP:  ~/.claude/settings.json (системный файл)
❌ НЕ BACKUP: ./.claude/settings.json (проектный - остается неизменным)
```

**Когда выполняется**:
```
┌─────────────────────────────────────────────────────────────┐
│              BACKUP/RESTORE LIFECYCLE                       │
└─────────────────────────────────────────────────────────────┘

1. PRE-LAUNCH: backup_system_settings()
   └─> Создает backup ~/.claude/settings.json → ~/.claude/.settings.backup.$$
   └─> Persistent copy → ~/.claude/.backups/settings-[timestamp].json
   └─> Rotation: keep last 3 backups

2. CONTAINER RUNS:
   └─> Использует ./.claude/settings.json (проектный GLM)
   └─> ~/.claude/ доступен для OAuth/history (read/write)

3. POST-EXIT: restore_system_settings()
   └─> Восстанавливает ~/.claude/settings.json из backup
   └─> Если auto-created: создает ./.claude/settings.json.dkrbkp
   └─> Cleanup: удаляет temporary backups
```

**Triple-Layer Safety**:
- **Layer 1**: Pre-backup validation (JSON, disk space, permissions)
- **Layer 2**: Atomic operations (mv instead of cp)
- **Layer 3**: Emergency backup (если restore fails)

**Подробности**: См. [DEFENSIVE_BACKUP_RESTORE_PLAN.md](./DEFENSIVE_BACKUP_RESTORE_PLAN.md)

---

### 7. Container Behavior

**Volume Mounts**:
```bash
# Host → Container mapping
~/.claude/          →  /root/.claude/         (read/write для OAuth/history)
./                  →  /workspace/            (project directory)
```

**Claude Code Priority** (внутри контейнера):
```
1. /workspace/.claude/settings.json   ← PRIMARY (GLM project config)
2. /root/.claude/settings.json        ← FALLBACK (system config, ignored для API)
```

**После выхода из контейнера**:
- ✅ `~/.claude/settings.json` восстановлен defensive restore
- ✅ `./.claude/settings.json` остается неизменным (проектный config)
- ✅ OAuth tokens сохранены в `~/.claude/` (shared между host и container)

---

## 🔐 P9: Secrets Management (NEW в v2.0)

### 8. API Key Loading (Priority Chain)

**Проблема**: Токен API не должен храниться в Git, но должен быть доступен при запуске.

**Решение**: Цепочка приоритетов с 4 источниками.

```
┌─────────────────────────────────────────────────────────────┐
│              API KEY SOURCE PRIORITY                         │
└─────────────────────────────────────────────────────────────┘

Priority 1: Environment Variable (CI/CD, runtime override)
   └─> $GLM_API_KEY или $ANTHROPIC_AUTH_TOKEN
   ✅ Использование: export GLM_API_KEY=your_key

Priority 2: Secrets File (local development) ← РЕКОМЕНДУЕТСЯ
   └─> secrets/.env (GLM_API_KEY=...)
   ✅ Использование: echo "GLM_API_KEY=key" > secrets/.env

Priority 3: Existing Settings (backward compatibility)
   └─> ./.claude/settings.json (ANTHROPIC_AUTH_TOKEN field)
   ⚠️  Только если ключ уже был в файле

Priority 4: Interactive Prompt (first-time setup) ← НОВОЕ
   └─> Запрос у пользователя + автосохранение в secrets/.env
   ✅ Использование: просто запустите ./glm-launch.sh
```

**Функция**: `load_api_secret()` (glm-launch.sh:205-311)

**Особенности**:
- ✅ **Interactive mode**: Если терминал интерактивный (`-t 0 && -t 1`) и ключ не найден → prompt
- ✅ **Validation**: Минимум 32 символа (Z.AI keys)
- ✅ **Auto-save**: Ключ сохраняется в `secrets/.env` с правами 600
- ✅ **Security**: Ключ никогда не логируется (только источник)

**Пример интерактивного режима**:
```
[INFO] 🔑 API key not found. First-time setup required.

   Get your API key from: https://z.ai/settings/api-keys

   Enter your GLM API key: _
```

---

### 9. API Key Injection

**После получения** ключа из любого источника, он инъектируется в `.claude/settings.json`.

**Функция**: `inject_api_key_to_settings()` (glm-launch.sh:313-358)

**Алгоритм**:
```
┌─────────────────────────────────────────────────────────────┐
│              INJECTION WORKFLOW                              │
└─────────────────────────────────────────────────────────────┘

1. Check existing settings.json
   └─> Если ключ уже совпадает → skip (optimization)

2. Load template (.claude/settings.template.json)
   └─> Если не существует → create minimal template

3. Inject using jq (atomic operation)
   └─> jq --arg token "$api_key" '.ANTHROPIC_AUTH_TOKEN = $token'

4. Atomic move
   └─> mv temp → settings.json
   └─> chmod 600

5. Success
   └─> log "✅ API key injected into settings.json"
```

**Преимущества**:
- ✅ **Atomic**: Нет риска повреждения файла
- ✅ **Template-based**: Сохраняет другие настройки из template
- ✅ **Idempotent**: Безопасно запускать многократно

---

### 10. Secrets Folder Structure

```
secrets/
├── .gitkeep              # Сохранение структуры в Git
├── .env.example          # Template с инструкциями (tracked)
└── .env                  # Реальный API ключ (gitignored)
```

**Формат secrets/.env**:
```bash
# GLM API Key Configuration
GLM_API_KEY=your_actual_key_here
```

**Защита в .gitignore**:
```gitignore
# P9: Secrets Management
secrets/.env              # Real secrets (ignored)
secrets/.env.*            # Any .env variants (ignored)
secrets/*.key             # Key files (ignored)
secrets/*.token           # Token files (ignored)
!secrets/.env.example     # Template (tracked)
!secrets/.gitkeep         # Structure (tracked)
```

**Важно**: Исключения (`!`) должны идти ПОСЛЕ общих правил.

---

### 11. Integration with P8

**P9 интегрируется с P8** следующим образом:

```
┌─────────────────────────────────────────────────────────────┐
│              P9 + P8 WORKFLOW                                │
└─────────────────────────────────────────────────────────────┘

1. P9: load_api_secret()
   └─> Получает ключ из secure source

2. P9: inject_api_key_to_settings()
   └─> Создает/обновляет ./.claude/settings.json

3. P8: validate_glm_settings()
   └─> Валидирует созданный файл (включая токен)

4. P8: backup_system_settings()
   └─> Бэкапит системный файл

5. Container: Использует инъектированный токен
```

**Ключевое отличие**:
- **P8**: Управляет lifecycle `settings.json` (backup/restore)
- **P9**: Управляет содержимым токена в `settings.json` (load/inject)

---

### 12. Security Best Practices

**DO ✅**:
- Используйте `secrets/.env` для локальной разработки
- Используйте переменные окружения в CI/CD
- Регулярно ротируйте ключи
- Проверяйте права 600 на файлы с секретами

**DON'T ❌**:
- Никогда не коммитьте `secrets/.env` в Git
- Не храните ключи в shell history
- Не используйте один ключ для всех окружений
- Не логируйте значение ключа

**Recovery** (если ключ потерян):
```bash
# Вариант 1: Интерактивный запрос
rm -f secrets/.env .claude/settings.json
./glm-launch.sh  # Скрипт запросит новый ключ

# Вариант 2: Ручное создание
echo "GLM_API_KEY=new_key" > secrets/.env
chmod 600 secrets/.env
```

---

## 🚀 P10: Onboarding Bypass (RESEARCHED в v2.1)

### 13. Исследование Обхода Onboarding

**⚠️ КРИТИЧЕСКИЙ ВЫВОД:** После комплексных исследований установлено, что **полный обход onboarding без авторизации на anthropic.com НЕВОЗМОЖЕН** по архитектурным причинам Claude Code.

**📋 Полный отчет:** [P10 Onboarding Bypass Research](./P10_ONBOARDING_BYPASS_RESEARCH.md) - Результаты исследований, методология, рекомендации

**Краткие выводы:**

| Аспект | Результат |
|--------|-----------|
| **Обход onboarding** | ❌ **Невозможен** - OAuth токен обязателен |
| **`hasCompletedOnboarding: true`** | ⚠️ Недостаточно - нужен `oauthAccount` |
| **Z.AI API** | ✅ Работает, но требует onboarding |
| **Рекомендация** | ✅ Улучшить пользовательский процесс onboarding |

**Почему обход невозможен:**

```
┌─────────────────────────────────────────────────────────────┐
│         АРХИТЕКТУРА АВТОРИЗАЦИИ CLAUDE CODE                  │
└─────────────────────────────────────────────────────────────┘

1. Onboarding (ОБЯЗАТЕЛЬНЫЙ)
   ├── Создает oauthAccount в ~/.claude.json
   ├── Требует авторизации на claude.ai
   └── Получает OAuth токен

2. Приоритет аутентификации
   ├── Приоритет 1: OAuth токен (oauthAccount)
   ├── Приоритет 2: ANTHROPIC_API_KEY
   └── Приоритет 3: ANTHROPIC_AUTH_TOKEN (gateway)

3. Z.AI использует стандартный onboarding
   └── Создает OAuth аккаунт автоматически
```

**Решение:** Улучшенный пользовательский процесс onboarding

```bash
# setup-claude-for-new-user.sh
echo "🚀 Настройка Claude Code для Z.AI..."
echo ""
echo "⚠️  Claude Code требует ОДНОКРАТНОЙ авторизации на Anthropic."
echo "✅ После авторизации:"
echo "   • Z.AI API будет работать через api.z.ai"
echo "   • Не нужно платить Anthropic (используется Z.AI ключ)"
```

**Функция в glm-launch.sh:**

```bash
setup_first_time_user() {
    local claude_json="$HOME/.claude/.claude.json"

    # Проверка: первый ли это запуск
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
        log_info "В браузере откроется окно авторизации..."
        sleep 3

        return 0
    fi

    log_success "✅ Claude Code уже авторизован"
    return 0
}
```

**Связанные документы:**
- 📋 [P10 Onboarding Bypass Research](./P10_ONBOARDING_BYPASS_RESEARCH.md) - Полный отчет об исследованиях
- 🧪 [P10 Experimental Testing Plan](./EXPERIMENTAL_P10_TESTING_PLAN.md) - План систематического тестирования
- 📋 [UAT Plan P10](./uat/P10_onboarding_bypass_uat.md) - План пользовательского тестирования

**Источники:**
- [Z.AI Claude Code Integration](https://docs.z.ai/scenario-example/develop-tools/claude)
- [Claude Code LLM Gateway Configuration](https://code.claude.com/docs/en/llm-gateway)
- [A developer's guide to settings.json in Claude Code](https://www.eesel.ai/en/blog/settings-json-claude-code)
- [JSON Schema for settings.json](https://json.schemastore.org/claude-code-settings.json)

---

## 📂 P12+B: Current-First Architecture (NEW в v1.2)

**Создано**: 2026-01-16
**Статус**: ✅ IMPLEMENTED
**UAT**: [P12 Workspace Independence](./uat/P12_workspace_independence_uat.md)

### Концепция

**Current-First Architecture** — текущая директория ВСЕГДА является корнем проекта для Claude Code.

**Ключевое изменение:**
- **Раньше:** glm-docker-tools монтировался как `/workspace`
- **Теперь:** Текущая папка монтируется как `/Users/.../current-project`

### Переменные

```
┌─────────────────────────────────────────────────────────────┐
│              P12+B ARCHITECTURE VARIABLES                    │
└─────────────────────────────────────────────────────────────┘

PROJECT_ROOT        → $(pwd)                          # Текущая папка
GLM_LAUNCHER_DIR    → Где лежит glm-launch.sh        # Утилита
WORKSPACE           → $(pwd)                          # Совпадает с PROJECT_ROOT
```

### Volume Mapping

```bash
# P12+B: Один volume вместо двух
-v "$PROJECT_ROOT:$PROJECT_ROOT:cached"  # Реальный путь!
-w "$PROJECT_ROOT"                         # Working directory
```

**Результат:**
- Контейнер видит: `/Users/username/coding/projects/test-project`
- Claude Code memory: `/Users/username/coding/projects/test-project/CLAUDE.md`
- Любая папка = отдельный проект

### Priority Chain: Settings & Secrets

```
Priority 1: Current directory (PROJECT_ROOT/.claude/settings.json)
Priority 2: Launcher directory (GLM_LAUNCHER_DIR/.claude/settings.json)
Priority 3: Home directory (~/.claude/settings.json)
```

### Priority Chain: Template

```
Priority 1: Current directory template
Priority 2: Launcher directory template (fallback)
Priority 3: Hardcoded configuration
```

### Functions

```bash
# Найти утилиту (где glm-launch.sh)
find_launcher_dir() {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
}

# Найти проект (текущая папка)
find_project_root() {
    echo "$(pwd)"
}
```

### Known Limitations

**Path Display:**
- Docker требует абсолютные пути
- Показывается: `/Users/username/...` вместо `~/...`
- Это intentional для reproducibility

**Документация:** [README.md - Known Limitations](../README.md#-known-limitations)

---

## 🚀 P13: Shell Aliases (NEW в v1.2)

**Создано**: 2026-01-16
**Статус**: ✅ IMPLEMENTED
**UAT**: [P13 Shell Aliases](./uat/P13_shell_aliases_uat.md)

### Концепция

**Shell Aliases** — запуск `glm` из любой папки на системе без монтирования glm-docker-tools как проекта.

### Команды

```bash
glm              # Стандартный запуск (auto-delete)
glm-debug        # Debug режим (persistent + shell)
glm-no-del       # No-delete режим (persistent)
glm-help         # Справка
```

### Architecture: Hybrid Fallback

```
Level 1: GLM_PROJECT_ROOT (env var) - highest priority
Level 2: Hardcoded path from installation
Level 3: Upward search (fallback)
```

### Files

```
scripts/glm-aliases.sh      # Shell functions
scripts/setup-aliases.sh    # Auto-installation
```

### Installation

```bash
cd ~/coding/projects/glm-docker-tools
./scripts/setup-aliases.sh --install

# Auto-detects shell (zsh/bash) and installs to:
# Zsh:  /usr/local/share/zsh/site-functions/glm
# Bash: ~/.local/share/bash-completion/completions/glm
```

### Shell Detection

```bash
# P13: Uses $SHELL (login shell) instead of subprocess
detect_shell() {
    local user_shell="${SHELL:-}"
    basename "$user_shell"  # zsh, bash, etc.
}
```

### Integration с P12+B

```bash
# glm-aliases.sh находит glm-launch.sh
_glm_find_project_root() {
    # Level 2: Hardcoded installation path
    local installed_path="__GLM_INSTALLED_PATH__"  # Replaced by setup

    # Запускает glm-launch.sh из glm-docker-tools
    "$installed_path/glm-launch.sh" "$@"
}

# glm-launch.sh использует CURRENT directory as project
PROJECT_ROOT="$(pwd)"  # P12+B: Current-First
```

### Usage

```bash
# Работает из ЛЮБОЙ папки
cd ~/coding/projects/random-project
glm

# PROJECT_ROOT = /Users/.../random-project
# GLM_LAUNCHER_DIR = /Users/.../glm-docker-tools
```

---

## 🔄 Последовательность Выполнения

### Полный Lifecycle Script

```
┌─────────────────────────────────────────────────────────────┐
│              SCRIPT EXECUTION FLOW                          │
└─────────────────────────────────────────────────────────────┘

1. check_dependencies()
   └─> Docker, disk space, versions

2. [P9] load_api_secret()
   └─> Загружает API ключ (env → file → existing → interactive)
   └─> ❌ FAIL → exit 1

3. [P9] inject_api_key_to_settings()
   └─> Инъектирует ключ в ./.claude/settings.json
   └─> Создает template если отсутствует

4. [P10] set_onboarding_flag() (если CLAUDE_SKIP_ONBOARDING=true)
   └─> Устанавливает hasCompletedOnboarding: true в ~/.claude/.claude.json
   └─> Создает бэкап перед модификацией
   └─> Graceful degradation при ошибке

5. [P8] validate_glm_settings("./.claude/settings.json")
   └─> Проверяет GLM configuration (включая токен)
   └─> ❌ FAIL → exit 1

6. [P8] backup_system_settings()
   └─> Бэкапит ~/.claude/settings.json
   └─> Persistent copy + rotation

7. run_claude()
   └─> Запускает Docker container
   └─> Claude Code использует ./.claude/settings.json (с инъектированным токеном)

8. [P8] cleanup() / restore_system_settings()
   └─> Восстанавливает ~/.claude/settings.json
   └─> Бэкапит ./.claude/settings.json.dkrbkp (если auto-created)
```

---

## 📋 Cheat Sheet

### Для Пользователя

**Настройка API ключа (P9)** ← РЕКОМЕНДУЕТСЯ:
```bash
# Вариант 1: Интерактивный (самый простой)
./glm-launch.sh  # Скрипт запросит ключ автоматически

# Вариант 2: Secrets file (локальная разработка)
mkdir -p secrets
echo "GLM_API_KEY=your_key" > secrets/.env
chmod 600 secrets/.env

# Вариант 3: Environment variable (CI/CD)
export GLM_API_KEY=your_key
./glm-launch.sh
```

**Настройка GLM в проекте (Legacy)**:
```bash
# Устаревший способ - используйте P9 secrets management вместо этого
cp ./.claude/settings.template.json ./.claude/settings.json
nano ./.claude/settings.json  # Заменить YOUR_GLM_API_KEY_HERE
```

**Проверка конфигурации**:
```bash
# Валидация
jq empty ./.claude/settings.json && echo "✅ JSON valid"

# Проверка GLM маркеров
grep -E "api\.z\.ai|glm-[0-9]" ./.claude/settings.json && echo "✅ GLM config"

# Проверка всех полей
jq -e '.ANTHROPIC_BASE_URL, .ANTHROPIC_MODEL, .ANTHROPIC_AUTH_TOKEN' \
  ./.claude/settings.json && echo "✅ All fields present"
```

**Recovery**:
```bash
# Восстановить из последней сессии
cp ~/.claude/.settings.last_session ~/.claude/settings.json

# Восстановить из persistent backup
ls -lt ~/.claude/.backups/
cp ~/.claude/.backups/settings-20251230-120000.json ~/.claude/settings.json
```

---

### Для Разработчика

**Ключевые файлы**:
- `glm-launch.sh:138-166` - [P8] validate_glm_settings()
- `glm-launch.sh:169-202` - [P8] auto_create_project_settings()
- `glm-launch.sh:205-311` - [P9] load_api_secret()
- `glm-launch.sh:313-358` - [P9] inject_api_key_to_settings()
- `glm-launch.sh:492-557` - [P10] set_onboarding_flag()
- `glm-launch.sh:360-433` - [P8] backup_system_settings()
- `glm-launch.sh:435-507` - [P8] restore_system_settings()
- `.claude/settings.template.json` - template для GLM config
- `secrets/.env` - API ключ (gitignored)
- `secrets/.env.example` - template для секретов + P10 config

**Модификация логики**:
1. Обновить код в `glm-launch.sh`
2. Обновить **ЭТОТ ДОКУМЕНТ** (docs/SCRIPT_LOGIC.md)
3. Обновить UAT plan (docs/uat/P8_settings_isolation_uat.md)
4. Обновить defensive plan (docs/DEFENSIVE_BACKUP_RESTORE_PLAN.md)
5. Запустить полный UAT

---

## 🔗 Связанные Документы

- **[CLAUDE.md](../CLAUDE.md)** - Главная инструкция (ссылается на этот документ)
- **[Secrets Management Guide](./SECRETS_MANAGEMENT.md)** - [P9] Полное руководство по управлению секретами
- **[P9 UAT Plan](./uat/P9_secrets_management_uat.md)** - [P9] Testing procedures
- **[P10 UAT Plan](./uat/P10_onboarding_bypass_uat.md)** - [P10] Testing procedures
- **[P8 UAT Plan](./uat/P8_settings_isolation_uat.md)** - [P8] Testing procedures
- **[Defensive Backup/Restore Plan](./DEFENSIVE_BACKUP_RESTORE_PLAN.md)** - [P8] Implementation details
- **[Recovery Guide](./RECOVERY.md)** - Manual recovery procedures

---

## 📝 История Изменений

| Версия | Дата | Изменения |
|--------|------|-----------|
| 2.0 | 2026-01-14 | **P9: Secrets Management** - Добавлена цепочка приоритетов загрузки API ключа, интерактивный запрос, secrets folder, integration with P8 |
| 1.0 | 2025-12-30 | **P8: Settings Isolation** - Initial release, фиксация критической логики backup/restore механизма |

---

**Статус**: 🔴 **ACTIVE - ОБЯЗАТЕЛЬНОЕ ПРОЧТЕНИЕ**
