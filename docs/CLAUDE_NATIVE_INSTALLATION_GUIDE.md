# Руководство по установке Claude Code (Нативная версия)

> 📚 **Справочная Документация** | [Home](../README.md) > [Documentation Index](./index.md) > **Native Installation Guide**

**Версия документа:** 2.0
**Дата создания:** 30 января 2026
**Последнее обновление:** 30 января 2026
**Статус:** Stable
**Авторы:** Technical Documentation Team
**Рецензенты:** DevOps Team, AI/ML Engineering

***

## 📋 Metadata

| Параметр | Значение |
| :-- | :-- |
| **Target Audience** | Developers, DevOps Engineers, System Administrators |
| **Estimated Time** | Quick Start: 10 минут; Full Setup: 30-90 минут |
| **Difficulty Level** | Beginner to Advanced |
| **Prerequisites** | Terminal access, Internet connection, Admin rights (optional) |
| **Supported Platforms** | macOS 10.15+, Linux (Debian/Ubuntu/Alpine), Docker |


***

## 📑 Содержание

1. [Введение](#1-%D0%B2%D0%B2%D0%B5%D0%B4%D0%B5%D0%BD%D0%B8%D0%B5)
2. [Системные требования](#2-%D1%81%D0%B8%D1%81%D1%82%D0%B5%D0%BC%D0%BD%D1%8B%D0%B5-%D1%82%D1%80%D0%B5%D0%B1%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D1%8F)
3. [Quick Start (Быстрый старт)](#3-quick-start-%D0%B1%D1%8B%D1%81%D1%82%D1%80%D1%8B%D0%B9-%D1%81%D1%82%D0%B0%D1%80%D1%82)
4. [Decision Tree (Выбор метода установки)](#4-decision-tree-%D0%B2%D1%8B%D0%B1%D0%BE%D1%80-%D0%BC%D0%B5%D1%82%D0%BE%D0%B4%D0%B0-%D1%83%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B8)
5. [Универсальная процедура резервного копирования](#5-%D1%83%D0%BD%D0%B8%D0%B2%D0%B5%D1%80%D1%81%D0%B0%D0%BB%D1%8C%D0%BD%D0%B0%D1%8F-%D0%BF%D1%80%D0%BE%D1%86%D0%B5%D0%B4%D1%83%D1%80%D0%B0-%D1%80%D0%B5%D0%B7%D0%B5%D1%80%D0%B2%D0%BD%D0%BE%D0%B3%D0%BE-%D0%BA%D0%BE%D0%BF%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D1%8F)
6. [Миграция с NPM на нативную версию](#6-%D0%BC%D0%B8%D0%B3%D1%80%D0%B0%D1%86%D0%B8%D1%8F-%D1%81-npm-%D0%BD%D0%B0-%D0%BD%D0%B0%D1%82%D0%B8%D0%B2%D0%BD%D1%83%D1%8E-%D0%B2%D0%B5%D1%80%D1%81%D0%B8%D1%8E)
7. [Чистая установка на macOS](#7-%D1%87%D0%B8%D1%81%D1%82%D0%B0%D1%8F-%D1%83%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0-%D0%BD%D0%B0-macos)
8. [Установка на Linux](#8-%D1%83%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0-%D0%BD%D0%B0-linux)
9. [Установка в Docker](#9-%D1%83%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0-%D0%B2-docker)
10. [Процедура восстановления из бэкапа](#10-%D0%BF%D1%80%D0%BE%D1%86%D0%B5%D0%B4%D1%83%D1%80%D0%B0-%D0%B2%D0%BE%D1%81%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BB%D0%B5%D0%BD%D0%B8%D1%8F-%D0%B8%D0%B7-%D0%B1%D1%8D%D0%BA%D0%B0%D0%BF%D0%B0)
11. [Автоматизация установки](#11-%D0%B0%D0%B2%D1%82%D0%BE%D0%BC%D0%B0%D1%82%D0%B8%D0%B7%D0%B0%D1%86%D0%B8%D1%8F-%D1%83%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B8)
12. [Проверка и диагностика](#12-%D0%BF%D1%80%D0%BE%D0%B2%D0%B5%D1%80%D0%BA%D0%B0-%D0%B8-%D0%B4%D0%B8%D0%B0%D0%B3%D0%BD%D0%BE%D1%81%D1%82%D0%B8%D0%BA%D0%B0)
13. [FAQ (Часто задаваемые вопросы)](#13-faq-%D1%87%D0%B0%D1%81%D1%82%D0%BE-%D0%B7%D0%B0%D0%B4%D0%B0%D0%B2%D0%B0%D0%B5%D0%BC%D1%8B%D0%B5-%D0%B2%D0%BE%D0%BF%D1%80%D0%BE%D1%81%D1%8B)
14. [Глоссарий](#14-%D0%B3%D0%BB%D0%BE%D1%81%D1%81%D0%B0%D1%80%D0%B8%D0%B9)
15. [Дополнительные ресурсы](#15-%D0%B4%D0%BE%D0%BF%D0%BE%D0%BB%D0%BD%D0%B8%D1%82%D0%B5%D0%BB%D1%8C%D0%BD%D1%8B%D0%B5-%D1%80%D0%B5%D1%81%D1%83%D1%80%D1%81%D1%8B)

***

## 1. Введение

### 1.1 О Claude Code

Claude Code — AI-ассистент для разработки от Anthropic, работающий в командной строке и IDE. Предоставляет возможности:

- Генерация и редактирование кода
- Навигация по кодовой базе
- Отладка и исправление ошибок
- Автоматизация рутинных задач
- Интеграция с внешними сервисами через MCP (Model Context Protocol)


### 1.2 Варианты установки

| Метод | Статус | Описание | Рекомендация |
| :-- | :-- | :-- | :-- |
| **Нативная установка** | ✅ Recommended | Standalone бинарник с автообновлениями | **Используйте этот метод** |
| **NPM-версия** | ⚠️ Deprecated | Требует Node.js, устаревшая | Только для legacy проектов |
| **Docker** | ✅ Supported | Контейнеризованная версия | Для изолированных сред |

### 1.3 Преимущества нативной версии

- ✅ **Автоматические обновления** в фоне
- ✅ **Независимость от Node.js** — не требует npm/nvm
- ✅ **Лучшая производительность** — особенно на ARM64 (Apple Silicon)
- ✅ **Меньший размер** — ~180MB vs ~300MB+ с Node.js
- ✅ **Официальная поддержка** — приоритет в исправлении багов

***

## 2. Системные требования

### 2.1 macOS

| Компонент | Минимум | Рекомендуется |
| :-- | :-- | :-- |
| **Версия ОС** | macOS 10.15 Catalina | macOS 13+ Ventura |
| **Процессор** | Intel x64 / Apple Silicon M1+ | Apple Silicon M3+ |
| **RAM** | 4GB | 8GB+ |
| **Диск** | 500MB свободно | 2GB+ |
| **Сеть** | Интернет для установки | Стабильное соединение |

### 2.2 Linux

| Компонент | Минимум | Рекомендуется |
| :-- | :-- | :-- |
| **Дистрибутив** | Debian 11, Ubuntu 20.04 LTS | Debian 12, Ubuntu 24.04 LTS |
| **Архитектура** | x86_64, ARM64 | x86_64 |
| **C Library** | glibc 2.31+ или musl 1.2+ | glibc 2.35+ |
| **RAM** | 4GB | 8GB+ |
| **Диск** | 500MB свободно | 2GB+ |

### 2.3 Docker

| Компонент | Требование |
| :-- | :-- |
| **Docker Engine** | 20.10+ |
| **Podman** | 3.0+ (альтернатива) |
| **Base Image** | debian:bookworm-slim, ubuntu:22.04, alpine:3.18 |

### 2.4 Зависимости

**Обязательные:**

- `curl` или `wget` — для скачивания
- `bash` или `zsh` — для установочного скрипта

**Рекомендуемые:**

- `git` — для работы с репозиториями
- `ripgrep` (`rg`) — для быстрого поиска
- `jq` — для парсинга JSON (опционально)

***

## 3. Quick Start (Быстрый старт)

### 3.1 Для нетерпеливых (5 минут)

**macOS:**

```bash
# Установка одной командой
curl -fsSL https://claude.ai/install.sh | bash

# Перезагрузить shell
source ~/.zshrc

# Проверить
claude --version
```

**Linux (Debian/Ubuntu):**

```bash
# Установка
curl -fsSL https://claude.ai/install.sh | bash

# Перезагрузить shell
source ~/.bashrc

# Проверить
claude --version
```

**⚠️ Внимание для пользователей Apple Silicon (M1/M2/M3):**
Если после установки видите предупреждение `CPU lacks AVX support` — перейдите к разделу [7.3 Ручная установка ARM64](#73-%D1%80%D1%83%D1%87%D0%BD%D0%B0%D1%8F-%D1%83%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0-arm64-100-%D0%B3%D0%B0%D1%80%D0%B0%D0%BD%D1%82%D0%B8%D1%8F).

***

### 3.2 Миграция с NPM (10 минут)

```bash
# 1. Сохранить настройки
cp -r ~/.claude ~/.claude.json ~/claude-backup-$(date +%Y%m%d-%H%M%S)/

# 2. Удалить NPM-версию
npm uninstall -g @anthropic-ai/claude-code

# 3. Установить нативную версию
curl -fsSL https://claude.ai/install.sh | bash

# 4. Проверить
claude doctor
```


***

## 4. Decision Tree (Выбор метода установки)

```
┌─────────────────────────────────────┐
│  Какая у вас операционная система?  │
└──────────┬──────────────────────────┘
           │
    ┌──────┴──────┐
    │             │
  macOS        Linux / Docker
    │             │
    │             └──→ Debian/Ubuntu? ──→ [Раздел 8.1]
    │                  Alpine (musl)? ──→ [Раздел 8.2]
    │                  Docker?       ──→ [Раздел 9]
    │
  Apple Silicon (M1/M2/M3)?
    │
 ┌──┴──┐
Да    Нет (Intel)
 │      │
 │      └──→ Автоматическая установка [Раздел 7.1]
 │
У вас есть NPM-версия?
 │
┌┴─┐
Да Нет
│   │
│   └──→ Чистая установка [Раздел 7.2]
│
└──→ Видите ли вы предупреждение AVX после установки?
     │
   ┌─┴─┐
  Да  Нет
   │    │
   │    └──→ Установка корректна ✅
   │
   └──→ Ручная установка ARM64 [Раздел 7.3]
```


***

## 5. Универсальная процедура резервного копирования

### 5.1 Что сохраняется в бэкапе

Claude Code хранит данные в двух местах:

**`~/.claude.json`** (Главный конфигурационный файл):

```json
{
  "auth": {
    "accessToken": "...",  // OAuth токен
    "refreshToken": "..."
  },
  "mcp": {
    "servers": {           // MCP-серверы
      "filesystem": {...},
      "brave-search": {...}
    }
  },
  "settings": {            // Пользовательские настройки
    "model": "claude-sonnet-4-5",
    "permissionMode": "default"
  },
  "cache": {...}           // Кэш для производительности
}
```

**`~/.claude/`** (Директория с данными):

```
~/.claude/
├── agents/              # Кастомные агенты
│   └── reviewer.json
├── skills/              # Пользовательские навыки (slash-команды)
│   └── /deploy
├── hooks/               # Pre/post хуки для автоматизации
│   ├── pre-commit.sh
│   └── post-success.sh
├── plans/               # Сохраненные планы выполнения
├── sessions/            # История сессий
│   └── uuid-session-id/
├── downloads/           # Временные файлы установщика (можно не бэкапить)
└── settings/            # Дополнительные настройки
```

**Project-level конфигурация** (в каждом проекте):

```
your-project/
├── .claude/
│   ├── CLAUDE.md        # Инструкции для Claude
│   ├── hooks/           # Project-specific хуки
│   └── settings.json    # Project-specific настройки
└── .claudeignore        # Игнорируемые файлы
```


***

### 5.2 Процедура бэкапа (все платформы)

**Шаг 1: Создание бэкапа**

⏱️ **Время:** 1-2 минуты
📦 **Размер:** обычно 10-100 MB

```bash
# Создать директорию для бэкапа с временной меткой
BACKUP_DIR=~/claude-backup-$(date +%Y%m%d-%H%M%S)
mkdir -p "$BACKUP_DIR"

# Бэкап user-level конфигурации
cp ~/.claude.json "$BACKUP_DIR/" 2>/dev/null || echo "~/.claude.json не найден (OK для первой установки)"
cp -r ~/.claude "$BACKUP_DIR/" 2>/dev/null || echo "~/.claude/ не найдена (OK для первой установки)"

# Создать manifest файл с метаданными
cat > "$BACKUP_DIR/backup-manifest.json" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "hostname": "$(hostname)",
  "platform": "$(uname -s)",
  "architecture": "$(uname -m)",
  "claude_version": "$(claude --version 2>/dev/null || echo 'not installed')",
  "backup_dir": "$BACKUP_DIR"
}
EOF

echo "✅ Бэкап создан: $BACKUP_DIR"
ls -lh "$BACKUP_DIR"
```

**Ожидаемый вывод:**

```
~/.claude.json не найден (OK для первой установки)
✅ Бэкап создан: /Users/username/claude-backup-20260130-102245
total 24
-rw-r--r--  1 user  staff   245B Jan 30 10:22 backup-manifest.json
drwxr-xr-x  5 user  staff   160B Jan 30 10:22 .claude
-rw-r--r--  1 user  staff   2.1K Jan 30 10:22 .claude.json
```


***

**Шаг 2: Проверка целостности бэкапа**

⏱️ **Время:** <1 минута

```bash
# Функция проверки бэкапа
verify_backup() {
  local backup_dir="$1"
  
  echo "🔍 Проверка бэкапа: $backup_dir"
  
  # Проверка существования директории
  if [[ ! -d "$backup_dir" ]]; then
    echo "❌ Директория бэкапа не найдена"
    return 1
  fi
  
  # Проверка manifest
  if [[ ! -f "$backup_dir/backup-manifest.json" ]]; then
    echo "⚠️  Manifest не найден (бэкап создан вручную?)"
  else
    echo "✅ Manifest найден"
    cat "$backup_dir/backup-manifest.json"
  fi
  
  # Проверка файлов
  local files_found=0
  
  if [[ -f "$backup_dir/.claude.json" ]]; then
    echo "✅ Файл .claude.json найден ($(du -h "$backup_dir/.claude.json" | cut -f1))"
    files_found=$((files_found + 1))
  fi
  
  if [[ -d "$backup_dir/.claude" ]]; then
    echo "✅ Директория .claude/ найдена ($(du -sh "$backup_dir/.claude" | cut -f1))"
    echo "   Содержимое:"
    ls -la "$backup_dir/.claude" | grep -v "^total" | awk '{print "   - " $9}'
    files_found=$((files_found + 1))
  fi
  
  if [[ $files_found -eq 0 ]]; then
    echo "⚠️  Бэкап пустой (это OK для первой установки)"
  else
    echo "✅ Бэкап содержит $files_found компонент(а)"
  fi
  
  return 0
}

# Запустить проверку
verify_backup "$BACKUP_DIR"
```

**Ожидаемый вывод (успешный бэкап):**

```
🔍 Проверка бэкапа: /Users/username/claude-backup-20260130-102245
✅ Manifest найден
{
  "timestamp": "2026-01-30T07:22:45Z",
  "hostname": "MacBook-Air",
  "platform": "Darwin",
  "architecture": "arm64",
  "claude_version": "2.1.7",
  "backup_dir": "/Users/username/claude-backup-20260130-102245"
}
✅ Файл .claude.json найден (2.1K)
✅ Директория .claude/ найдена (8.5M)
   Содержимое:
   - agents
   - hooks
   - sessions
   - settings
✅ Бэкап содержит 2 компонент(а)
```


***

**Шаг 3 (Опционально): Бэкап project-level конфигурации**

⏱️ **Время:** зависит от количества проектов

```bash
# Найти все .claude/ директории в проектах
find ~/projects -type d -name ".claude" 2>/dev/null | while read -r project_claude; do
  project_dir=$(dirname "$project_claude")
  project_name=$(basename "$project_dir")
  
  echo "📁 Найден проект: $project_name"
  
  # Скопировать в бэкап
  mkdir -p "$BACKUP_DIR/projects/$project_name"
  cp -r "$project_claude" "$BACKUP_DIR/projects/$project_name/"
  
  # Также скопировать .claudeignore если есть
  if [[ -f "$project_dir/.claudeignore" ]]; then
    cp "$project_dir/.claudeignore" "$BACKUP_DIR/projects/$project_name/"
  fi
  
  echo "   ✅ Сохранено в бэкап"
done

echo "✅ Project-level конфигурации сохранены"
```


***

### 5.3 Автоматический бэкап-скрипт

Сохраните как `~/bin/claude-backup.sh`:

```bash
#!/bin/bash
# Claude Code Backup Script v1.0

set -euo pipefail

# Конфигурация
BACKUP_ROOT="${CLAUDE_BACKUP_ROOT:-$HOME/claude-backups}"
MAX_BACKUPS="${CLAUDE_MAX_BACKUPS:-5}"  # Хранить последние 5 бэкапов
INCLUDE_PROJECTS="${CLAUDE_BACKUP_PROJECTS:-false}"

# Создать директорию
BACKUP_DIR="$BACKUP_ROOT/backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "🔄 Создание бэкапа Claude Code..."

# Бэкап user-level
[[ -f ~/.claude.json ]] && cp ~/.claude.json "$BACKUP_DIR/"
[[ -d ~/.claude ]] && cp -r ~/.claude "$BACKUP_DIR/"

# Manifest
cat > "$BACKUP_DIR/backup-manifest.json" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "hostname": "$(hostname)",
  "platform": "$(uname -s)",
  "architecture": "$(uname -m)",
  "claude_version": "$(claude --version 2>/dev/null || echo 'N/A')"
}
EOF

# Project-level (опционально)
if [[ "$INCLUDE_PROJECTS" == "true" ]]; then
  find ~/projects -type d -name ".claude" 2>/dev/null | while read -r pc; do
    pn=$(basename "$(dirname "$pc")")
    mkdir -p "$BACKUP_DIR/projects/$pn"
    cp -r "$pc" "$BACKUP_DIR/projects/$pn/"
  done
fi

# Очистка старых бэкапов
ls -dt "$BACKUP_ROOT"/backup-* 2>/dev/null | tail -n +$((MAX_BACKUPS + 1)) | xargs rm -rf

echo "✅ Бэкап создан: $BACKUP_DIR"
echo "📊 Размер: $(du -sh "$BACKUP_DIR" | cut -f1)"
```

**Использование:**

```bash
# Сделать исполняемым
chmod +x ~/bin/claude-backup.sh

# Запустить
~/bin/claude-backup.sh

# С project-level конфигурациями
CLAUDE_BACKUP_PROJECTS=true ~/bin/claude-backup.sh
```


***

## 6. Миграция с NPM на нативную версию

### 6.1 Prerequisites

✅ **Требования:**

- Установлена NPM-версия Claude Code (`@anthropic-ai/claude-code`)
- Доступ к терминалу
- Права на удаление глобальных npm-пакетов
- Интернет-соединение

⏱️ **Общее время:** 15-90 минут (зависит от скорости интернета)

***

### 6.2 Пошаговая инструкция для macOS

#### Шаг 1: Диагностика текущей установки

⏱️ **Время:** 1 минута

```bash
# Проверить текущую установку
claude doctor
```

**Ожидаемый вывод:**

```
 Diagnostics
 └ Currently running: npm-global (2.1.23)
 └ Path: /Users/username/.nvm/versions/node/v22.20.0/bin/node
 └ Invoked: /Users/username/.nvm/versions/node/v22.20.0/bin/claude
 └ Config install method: global
```

Запишите версию (2.1.23 в примере).

***

#### Шаг 2: Резервное копирование

⏱️ **Время:** 2 минуты

Используйте [Раздел 5.2](#52-%D0%BF%D1%80%D0%BE%D1%86%D0%B5%D0%B4%D1%83%D1%80%D0%B0-%D0%B1%D1%8D%D0%BA%D0%B0%D0%BF%D0%B0-%D0%B2%D1%81%D0%B5-%D0%BF%D0%BB%D0%B0%D1%82%D1%84%D0%BE%D1%80%D0%BC%D1%8B).

**✅ Success Criteria:**

- Создана директория `~/claude-backup-YYYYMMDD-HHMMSS`
- Файл `backup-manifest.json` содержит корректные данные
- Проверка `verify_backup` прошла успешно

**❌ Failure Criteria → Действие:**

- Бэкап пустой → Это OK для первой установки, продолжайте
- Ошибка доступа → Проверьте права на `~/.claude`

***

#### Шаг 3: Определение имени npm-пакета

⏱️ **Время:** <1 минута

```bash
# Показать все глобальные npm-пакеты с "claude"
npm list -g | grep -i claude
```

**Ожидаемый вывод (вариант 1):**

```
├── @anthropic-ai/claude-code@2.1.23
```

**Ожидаемый вывод (вариант 2):**

```
├── @anthropic/claude@2.1.23
```

Запишите точное имя пакета.

***

#### Шаг 4: Удаление NPM-версии

⏱️ **Время:** 1 минута

```bash
# Замените на ваше имя пакета из Шага 3
npm uninstall -g @anthropic-ai/claude-code

# Проверить удаление
npm list -g | grep -i claude
```

**Ожидаемый вывод (успех):**

```
removed 3 packages in 204ms
```

Затем grep не должен ничего найти.

**⚠️ Inline Troubleshooting:**

**Проблема:** `npm ERR! code EACCES`
**Решение:**

```bash
# Если используете nvm (рекомендуется)
npm uninstall -g @anthropic-ai/claude-code

# Если НЕ используете nvm (требуется sudo)
sudo npm uninstall -g @anthropic-ai/claude-code
```

**Проблема:** "Package not found"
**Решение:** Проверьте точное имя из Шага 3.

***

#### Шаг 5: Установка нативной версии

⏱️ **Время:** 5-60 минут (зависит от скорости интернета)

**Вариант A: Автоматическая установка (Intel Mac или если уверены)**

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

**Вариант B: Для Apple Silicon (M1/M2/M3) — Рекомендуется**

Переходите к [Раздел 7.3 Ручная установка ARM64](#73-%D1%80%D1%83%D1%87%D0%BD%D0%B0%D1%8F-%D1%83%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0-arm64-100-%D0%B3%D0%B0%D1%80%D0%B0%D0%BD%D1%82%D0%B8%D1%8F).

**Ожидаемый вывод (успех):**

```
Setting up Claude Code...
✔ Claude Code successfully installed!

  Version: 2.1.7
  Location: ~/.local/bin/claude

  Next: Run claude --help to get started

✅ Installation complete!
```

**⚠️ Inline Troubleshooting:**

**Проблема:** Таймаут при скачивании
**Решение:** См. [FAQ 13.3](#133-%D0%BC%D0%B5%D0%B4%D0%BB%D0%B5%D0%BD%D0%BD%D0%B0%D1%8F-%D1%83%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0-%D0%B8%D0%BB%D0%B8-%D1%82%D0%B0%D0%B9%D0%BC%D0%B0%D1%83%D1%82)

**Проблема:** Предупреждение AVX на Apple Silicon
**Решение:** Установлена x64 версия вместо ARM64 → [Раздел 7.3](#73-%D1%80%D1%83%D1%87%D0%BD%D0%B0%D1%8F-%D1%83%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0-arm64-100-%D0%B3%D0%B0%D1%80%D0%B0%D0%BD%D1%82%D0%B8%D1%8F)

***

#### Шаг 6: Проверка установки

⏱️ **Время:** 2 минуты

```bash
# Перезагрузить shell
source ~/.zshrc  # или ~/.bashrc

# Проверить архитектуру (КРИТИЧНО для Apple Silicon!)
file ~/.local/bin/claude

# Проверить версию
claude --version

# Запустить диагностику
claude doctor
```

**Ожидаемый вывод (успех для Apple Silicon):**

```
/Users/username/.local/bin/claude: Mach-O 64-bit executable arm64

2.1.7

 Diagnostics
 └ Currently running: native (2.1.7)
 └ Path: /Users/username/.local/bin/claude
 └ Config install method: native
 
 Updates
 └ Auto-updates: enabled
```

**✅ Success Criteria:**

- `file` показывает `arm64` (для Apple Silicon) или `x86_64` (для Intel)
- НЕТ предупреждения AVX
- `claude doctor` показывает `native` installation method
- `Auto-updates: enabled`

**❌ Failure Criteria → Действие:**

- `file` показывает `x86_64` на Apple Silicon → [Раздел 7.3](#73-%D1%80%D1%83%D1%87%D0%BD%D0%B0%D1%8F-%D1%83%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0-arm64-100-%D0%B3%D0%B0%D1%80%D0%B0%D0%BD%D1%82%D0%B8%D1%8F)
- Предупреждение AVX → Неправильная архитектура → [Раздел 7.3](#73-%D1%80%D1%83%D1%87%D0%BD%D0%B0%D1%8F-%D1%83%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0-arm64-100-%D0%B3%D0%B0%D1%80%D0%B0%D0%BD%D1%82%D0%B8%D1%8F)
- `command not found: claude` → Проверьте PATH: `echo $PATH | grep .local/bin`

***

#### Шаг 7: Очистка

⏱️ **Время:** <1 минута

```bash
# Удалить временные файлы установщика
rm -rf /tmp/claude-* ~/.cache/claude-code 2>/dev/null

# Удалить частично скачанные файлы (если были проблемы)
rm -rf ~/.claude/downloads/claude-* 2>/dev/null

echo "✅ Очистка завершена"
```

**Опционально (через несколько дней):**

```bash
# Удалить бэкап, если всё работает стабильно
rm -rf ~/claude-backup-YYYYMMDD-HHMMSS
```


***

### 6.3 Пошаговая инструкция для Linux

Процедура аналогична macOS, но с особенностями:

#### Различия для Linux:

**Шаг 4 (Удаление NPM):**

```bash
# Если используете nvm
npm uninstall -g @anthropic-ai/claude-code

# Если системная установка npm
sudo npm uninstall -g @anthropic-ai/claude-code
```

**Шаг 5 (Установка):**

```bash
# Скрипт автоматически определит:
# - Debian/Ubuntu → linux-x64 или linux-arm64
# - Alpine → linux-x64-musl или linux-arm64-musl

curl -fsSL https://claude.ai/install.sh | bash
```

**Шаг 6 (Проверка архитектуры):**

```bash
file ~/.local/bin/claude

# Ожидаемый вывод для Debian x64:
# ~/.local/bin/claude: ELF 64-bit LSB executable, x86-64

# Ожидаемый вывод для Debian ARM64:
# ~/.local/bin/claude: ELF 64-bit LSB executable, ARM aarch64

# Ожидаемый вывод для Alpine (musl):
# ~/.local/bin/claude: ELF 64-bit LSB executable (musl)
```


***

## 7. Чистая установка на macOS

### 7.1 Автоматическая установка (Intel Mac)

⏱️ **Время:** 5-30 минут

**Prerequisites:**

- macOS 10.15+
- Intel x64 процессор
- Интернет-соединение

```bash
# Установка
curl -fsSL https://claude.ai/install.sh | bash

# Перезагрузить shell
source ~/.zshrc

# Проверить
claude --version
file ~/.local/bin/claude
```

**Success Criteria:**

- `file` показывает `x86_64`
- `claude --version` выводит версию
- Нет ошибок или предупреждений

***

### 7.2 Автоматическая установка (Apple Silicon — с риском)

⚠️ **Предупреждение:** Этот метод может установить x64 версию вместо ARM64 из-за проблемы с автоопределением архитектуры в `bootstrap.sh`.

**Если увидите предупреждение AVX после установки** → переходите к [7.3](#73-%D1%80%D1%83%D1%87%D0%BD%D0%B0%D1%8F-%D1%83%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0-arm64-100-%D0%B3%D0%B0%D1%80%D0%B0%D0%BD%D1%82%D0%B8%D1%8F)

```bash
# Попытка автоматической установки
curl -fsSL https://claude.ai/install.sh | bash

# Проверить архитектуру (ВАЖНО!)
file ~/.local/bin/claude

# Запустить Claude
claude --version
```

**Проверка успеха:**

```bash
# Должно показать arm64, а НЕ x86_64
file ~/.local/bin/claude
# Ожидается: Mach-O 64-bit executable arm64

# НЕ должно быть предупреждения AVX
claude --version
```

**Если установилась x64 версия:**

```bash
# Удалить
rm -f ~/.local/bin/claude

# Использовать ручную установку ARM64 (см. 7.3)
```


***

### 7.3 Ручная установка ARM64 (100% гарантия)

⏱️ **Время:** 10-60 минут (зависит от скорости интернета)

**Prerequisites:**

- macOS 10.15+
- Apple Silicon (M1/M2/M3/M4)
- Интернет-соединение

**Зачем этот метод:**

- ✅ 100% гарантия установки ARM64 версии
- ✅ Обход проблемы автоопределения в `bootstrap.sh`
- ✅ Проверка архитектуры ДО установки
- ✅ Избегание замены бинарника после скачивания (GitHub Issue \#13617)

***

#### Шаг 1: Проверка системы

```bash
# Проверить, что iTerm2 (если используете) не в Rosetta
sysctl sysctl.proc_translated
# Должно вернуть: 0 ✅

# Проверить архитектуру системы
uname -m
# Должно вернуть: arm64 ✅

# Проверить архитектуру терминала
arch
# Должно вернуть: arm64 ✅
```

**⚠️ Inline Troubleshooting:**

**Проблема:** `sysctl.proc_translated: 1`
**Решение:** iTerm2 работает в Rosetta

1. Finder → Приложения → iTerm.app → Get Info (⌘I)
2. Убедитесь, что **НЕ отмечено** "Open using Rosetta"
3. Перезапустить iTerm2
4. Проверить снова: `sysctl sysctl.proc_translated` должно быть `0`

***

#### Шаг 2: Получение актуальной версии

⏱️ **Время:** <1 минута

```bash
# Получить номер stable версии
CLAUDE_VERSION=$(curl -fsSL https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/stable)

echo "📦 Будет установлена версия: $CLAUDE_VERSION"
```

**Ожидаемый вывод:**

```
📦 Будет установлена версия: 2.1.7
```


***

#### Шаг 3: Скачивание ARM64 бинарника

⏱️ **Время:** 5-60 минут (размер ~174 MB, зависит от скорости)

```bash
# Скачать ARM64 версию напрямую
curl -fsSL -o /tmp/claude-arm64 \
  "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${CLAUDE_VERSION}/darwin-arm64/claude"

echo "✅ Скачивание завершено"
ls -lh /tmp/claude-arm64
```

**Ожидаемый вывод:**

```
✅ Скачивание завершено
-rw-r--r--  1 user  wheel   174M Jan 30 10:45 /tmp/claude-arm64
```

**⚠️ Inline Troubleshooting:**

**Проблема:** Очень медленное скачивание (<100 KB/s)
**Решение:** См. [FAQ 13.3](#133-%D0%BC%D0%B5%D0%B4%D0%BB%D0%B5%D0%BD%D0%BD%D0%B0%D1%8F-%D1%83%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0-%D0%B8%D0%BB%D0%B8-%D1%82%D0%B0%D0%B9%D0%BC%D0%B0%D1%83%D1%82)

**Проблема:** Таймаут или ошибка 404
**Решение:**

```bash
# Проверить доступность сервера
curl -I https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/stable

# Если недоступен → использовать VPN или подождать
```


***

#### Шаг 4: Проверка архитектуры бинарника (КРИТИЧНО!)

⏱️ **Время:** <1 минута

```bash
# Проверить архитектуру скачанного файла
file /tmp/claude-arm64
```

**Ожидаемый вывод (ПРАВИЛЬНО):**

```
/tmp/claude-arm64: Mach-O 64-bit executable arm64
```

**❌ НЕПРАВИЛЬНЫЙ вывод:**

```
/tmp/claude-arm64: Mach-O 64-bit executable x86_64
```

**Если показывает x86_64 → ОСТАНОВИТЕСЬ:**

```bash
# Удалить неправильный файл
rm /tmp/claude-arm64

# Проверить URL — возможно, ошибка в команде
echo "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${CLAUDE_VERSION}/darwin-arm64/claude"

# URL должен содержать /darwin-arm64/, а НЕ /darwin-x64/
```


***

#### Шаг 5: Установка

⏱️ **Время:** 1-2 минуты

```bash
# Сделать исполняемым
chmod +x /tmp/claude-arm64

# Запустить установщик
/tmp/claude-arm64 install stable
```

**Ожидаемый вывод:**

```
✔ Claude Code successfully installed!

  Version: 2.1.7
  Location: ~/.local/bin/claude

  Next: Run claude --help to get started
```

**⚠️ Inline Troubleshooting:**

**Проблема:** "Permission denied"
**Решение:**

```bash
chmod +x /tmp/claude-arm64
/tmp/claude-arm64 install stable
```

**Проблема:** "Installation failed"
**Решение:**

```bash
# Проверить логи
/tmp/claude-arm64 install stable --debug

# Проверить ~/.local/bin доступен
mkdir -p ~/.local/bin
```


***

#### Шаг 6: Финальная проверка

⏱️ **Время:** 1 минута

```bash
# Перезагрузить shell
source ~/.zshrc

# Проверить архитектуру установленной версии
file ~/.local/bin/claude

# Проверить версию (НЕ должно быть предупреждения AVX!)
claude --version

# Полная диагностика
claude doctor
```

**Ожидаемый вывод (УСПЕХ ✅):**

```
/Users/username/.local/bin/claude: Mach-O 64-bit executable arm64

2.1.7

 Diagnostics
 └ Currently running: native (2.1.7)
 └ Path: /Users/username/.local/bin/claude
 └ Config install method: native

 Updates
 └ Auto-updates: enabled
 └ Auto-update channel: stable
```

**✅ Success Criteria (ВСЕ должны выполняться):**

- ✅ `file ~/.local/bin/claude` показывает `arm64`
- ✅ НЕТ предупреждения `CPU lacks AVX support`
- ✅ `claude doctor` показывает `native` installation
- ✅ `Auto-updates: enabled`

***

#### Шаг 7: Очистка

```bash
# Удалить временный файл
rm /tmp/claude-arm64

echo "✅ Установка ARM64 завершена успешно!"
```


***

## 8. Установка на Linux

### 8.1 Debian/Ubuntu (glibc)

⏱️ **Время:** 10-30 минут

**Prerequisites:**

- Debian 11+ или Ubuntu 20.04 LTS+
- Архитектура: x86_64 или ARM64
- Права sudo (для установки зависимостей)
- Интернет

***

#### Шаг 1: Установка зависимостей

```bash
# Обновить список пакетов
sudo apt update

# Установить обязательные зависимости
sudo apt install -y curl ca-certificates

# Установить рекомендуемые зависимости
sudo apt install -y git ripgrep jq

echo "✅ Зависимости установлены"
```


***

#### Шаг 2: Установка Claude Code

```bash
# Автоматическая установка (определит платформу)
curl -fsSL https://claude.ai/install.sh | bash

# Перезагрузить shell
source ~/.bashrc  # или ~/.zshrc если используете zsh
```

**Скрипт автоматически определит:**

- OS: Linux
- Архитектура: `x86_64` → `linux-x64` или `aarch64` → `linux-arm64`
- C library: glibc (стандартная для Debian/Ubuntu)

**Ожидаемый вывод:**

```
Setting up Claude Code...
✔ Claude Code successfully installed!

  Version: 2.1.7
  Location: ~/.local/bin/claude
```


***

#### Шаг 3: Проверка

```bash
# Проверить архитектуру
file ~/.local/bin/claude

# Для x86_64 ожидается:
# ~/.local/bin/claude: ELF 64-bit LSB executable, x86-64, dynamically linked

# Для ARM64 ожидается:
# ~/.local/bin/claude: ELF 64-bit LSB executable, ARM aarch64, dynamically linked

# Проверить версию
claude --version

# Диагностика
claude doctor
```


***

### 8.2 Alpine Linux (musl)

⏱️ **Время:** 10-30 минут

**Prerequisites:**

- Alpine Linux 3.16+
- Архитектура: x86_64 или ARM64
- Интернет

***

#### Шаг 1: Установка зависимостей

```bash
# Установить необходимые пакеты
apk add --no-cache curl ca-certificates bash git ripgrep

echo "✅ Зависимости установлены"
```


***

#### Шаг 2: Установка Claude Code

```bash
# Автоматическая установка
# Скрипт определит musl и установит linux-x64-musl или linux-arm64-musl
curl -fsSL https://claude.ai/install.sh | bash

# Перезагрузить shell
source ~/.profile
```


***

#### Шаг 3: Проверка

```bash
# Проверить, что используется musl версия
file ~/.local/bin/claude
ldd ~/.local/bin/claude

# Должно показать musl в зависимостях
```


***

## 9. Установка в Docker

### 9.1 Простой Dockerfile (Debian-based)

⏱️ **Время:** 5-15 минут

**Файл:** `Dockerfile`

```dockerfile
FROM debian:bookworm-slim

# Metadata
LABEL maintainer="your-email@example.com"
LABEL description="Claude Code in Docker container"
LABEL version="1.0"

# Установить зависимости
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    git \
    ripgrep \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Создать пользователя (НЕ запускать как root)
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd -g ${USER_GID} claude && \
    useradd -m -u ${USER_UID} -g claude -s /bin/bash claude

# Переключиться на пользователя
USER claude
WORKDIR /home/claude

# Установить Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash

# Добавить в PATH
ENV PATH="/home/claude/.local/bin:${PATH}"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD claude --version || exit 1

# По умолчанию запускать interactive session
CMD ["claude"]
```

**Сборка и запуск:**

```bash
# Сборка
docker build -t claude-code:latest .

# Запуск interactive session
docker run -it --rm \
  -v $(pwd):/workspace \
  -w /workspace \
  claude-code:latest

# Запуск с сохранением настроек
docker run -it --rm \
  -v $(pwd):/workspace \
  -v ~/.claude:/home/claude/.claude \
  -w /workspace \
  claude-code:latest
```


***

### 9.2 Multi-platform Dockerfile (ARM64 + x64)

⏱️ **Время:** 10-20 минут

**Файл:** `Dockerfile.multiarch`

```dockerfile
FROM debian:bookworm-slim

# Build arguments
ARG TARGETARCH
ARG CLAUDE_VERSION=stable

# Metadata
LABEL multi-arch="true"
LABEL platforms="linux/amd64,linux/arm64"

# Установить зависимости
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    git \
    ripgrep \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Создать пользователя
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd -g ${USER_GID} claude && \
    useradd -m -u ${USER_UID} -g claude -s /bin/bash claude

USER claude
WORKDIR /home/claude

# Скачать правильную версию для архитектуры
RUN PLATFORM="linux-${TARGETARCH}" && \
    VERSION=$(curl -fsSL https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${CLAUDE_VERSION}) && \
    echo "📦 Installing Claude Code ${VERSION} for ${PLATFORM}" && \
    curl -fsSL -o /tmp/claude \
      "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${VERSION}/${PLATFORM}/claude" && \
    chmod +x /tmp/claude && \
    /tmp/claude install stable && \
    rm /tmp/claude

ENV PATH="/home/claude/.local/bin:${PATH}"

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD claude --version || exit 1

CMD ["claude"]
```

**Сборка для разных платформ:**

```bash
# Для текущей платформы
docker build -f Dockerfile.multiarch -t claude-code:latest .

# Для конкретной платформы
docker build --platform=linux/amd64 -f Dockerfile.multiarch -t claude-code:amd64 .
docker build --platform=linux/arm64 -f Dockerfile.multiarch -t claude-code:arm64 .

# Multi-platform build (требуется buildx)
docker buildx build --platform=linux/amd64,linux/arm64 \
  -f Dockerfile.multiarch \
  -t your-registry/claude-code:latest \
  --push .
```


***

### 9.3 Docker Compose

**Файл:** `docker-compose.yml`

```yaml
version: '3.8'

services:
  claude-code:
    image: claude-code:latest
    build:
      context: .
      dockerfile: Dockerfile
      args:
        USER_UID: 1000
        USER_GID: 1000
    
    # Монтировать workspace и настройки
    volumes:
      - ./workspace:/workspace
      - ~/.claude:/home/claude/.claude:ro  # read-only для безопасности
    
    working_dir: /workspace
    
    # Interactive terminal
    stdin_open: true
    tty: true
    
    # Environment variables
    environment:
      - CLAUDE_MODEL=claude-sonnet-4-5
      - CLAUDE_PERMISSION_MODE=default
    
    # Resource limits
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
        reservations:
          memory: 2G
    
    # Health check
    healthcheck:
      test: ["CMD", "claude", "--version"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 5s
```

**Использование:**

```bash
# Запуск
docker-compose up -d

# Подключиться к сессии
docker-compose exec claude-code claude

# Просмотр логов
docker-compose logs -f

# Остановка
docker-compose down
```


***

### 9.4 Проверка Docker установки

```bash
# Проверить архитектуру внутри контейнера
docker run --rm claude-code:latest file /home/claude/.local/bin/claude

# Для AMD64 ожидается:
# /home/claude/.local/bin/claude: ELF 64-bit LSB executable, x86-64

# Для ARM64 ожидается:
# /home/claude/.local/bin/claude: ELF 64-bit LSB executable, ARM aarch64

# Проверить версию
docker run --rm claude-code:latest claude --version

# Проверить health status
docker inspect --format='{{.State.Health.Status}}' <container_id>
# Ожидается: healthy
```


***

## 10. Процедура восстановления из бэкапа

### 10.1 Когда нужно восстановление

- ⚠️ Неудачная установка/миграция
- ⚠️ Потеря настроек после обновления
- ⚠️ Случайное удаление `~/.claude/`
- ⚠️ Переход на новую машину
- ⚠️ Откат к предыдущей конфигурации

***

### 10.2 Полное восстановление

⏱️ **Время:** 2-5 минут

**Prerequisites:**

- Существующий бэкап из [Раздела 5](#5-%D1%83%D0%BD%D0%B8%D0%B2%D0%B5%D1%80%D1%81%D0%B0%D0%BB%D1%8C%D0%BD%D0%B0%D1%8F-%D0%BF%D1%80%D0%BE%D1%86%D0%B5%D0%B4%D1%83%D1%80%D0%B0-%D1%80%D0%B5%D0%B7%D0%B5%D1%80%D0%B2%D0%BD%D0%BE%D0%B3%D0%BE-%D0%BA%D0%BE%D0%BF%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D1%8F)
- Claude Code установлен (хотя бы базово)

***

#### Шаг 1: Остановить Claude Code

```bash
# Убедиться, что нет активных сессий
pkill -f claude || true

echo "✅ Процессы Claude остановлены"
```


***

#### Шаг 2: Проверка бэкапа

```bash
# Указать путь к вашему бэкапу
BACKUP_DIR=~/claude-backup-20260130-102245

# Проверить существование
if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "❌ Бэкап не найден: $BACKUP_DIR"
  exit 1
fi

# Показать содержимое
echo "📁 Содержимое бэкапа:"
ls -la "$BACKUP_DIR"

# Показать manifest (если есть)
if [[ -f "$BACKUP_DIR/backup-manifest.json" ]]; then
  echo ""
  echo "📄 Manifest:"
  cat "$BACKUP_DIR/backup-manifest.json"
fi
```

**Ожидаемый вывод:**

```
📁 Содержимое бэкапа:
total 24
drwxr-xr-x   5 user  staff   160 Jan 30 10:22 .
drwxr-xr-x  50 user  staff  1600 Jan 30 11:00 ..
-rw-r--r--   1 user  staff   245 Jan 30 10:22 backup-manifest.json
drwxr-xr-x   5 user  staff   160 Jan 30 10:22 .claude
-rw-r--r--   1 user  staff  2145 Jan 30 10:22 .claude.json

📄 Manifest:
{
  "timestamp": "2026-01-30T07:22:45Z",
  "hostname": "MacBook-Air",
  ...
}
```


***

#### Шаг 3: Создать бэкап текущего состояния (safety net)

```bash
# На случай, если что-то пойдет не так
SAFETY_BACKUP=~/claude-safety-backup-$(date +%Y%m%d-%H%M%S)
mkdir -p "$SAFETY_BACKUP"

cp ~/.claude.json "$SAFETY_BACKUP/" 2>/dev/null || true
cp -r ~/.claude "$SAFETY_BACKUP/" 2>/dev/null || true

echo "✅ Safety backup создан: $SAFETY_BACKUP"
```


***

#### Шаг 4: Восстановление

```bash
# Удалить текущие настройки
rm -f ~/.claude.json
rm -rf ~/.claude

# Восстановить из бэкапа
if [[ -f "$BACKUP_DIR/.claude.json" ]]; then
  cp "$BACKUP_DIR/.claude.json" ~/.claude.json
  echo "✅ Восстановлен ~/.claude.json"
fi

if [[ -d "$BACKUP_DIR/.claude" ]]; then
  cp -r "$BACKUP_DIR/.claude" ~/.claude
  echo "✅ Восстановлена ~/.claude/"
fi

# Установить правильные права доступа
chmod 600 ~/.claude.json 2>/dev/null || true
chmod -R 755 ~/.claude 2>/dev/null || true

echo "✅ Восстановление завершено"
```


***

#### Шаг 5: Проверка

```bash
# Проверить файлы
ls -la ~/.claude.json ~/.claude/

# Запустить Claude Code
claude --version

# Проверить сессии (если были)
claude doctor

# Попробовать продолжить последнюю сессию
claude --continue
```

**✅ Success Criteria:**

- Файлы восстановлены
- `claude --version` работает
- Предыдущие сессии видны в `claude doctor`
- MCP-серверы работают (если были настроены)

***

### 10.3 Частичное восстановление (только определенные компоненты)

#### Восстановить только MCP-серверы

```bash
# Извлечь MCP конфигурацию из бэкапа
jq '.mcp' "$BACKUP_DIR/.claude.json" > /tmp/mcp-config.json

# Объединить с текущей конфигурацией
jq --slurpfile mcp /tmp/mcp-config.json '.mcp = $mcp[0]' ~/.claude.json > /tmp/merged.json
mv /tmp/merged.json ~/.claude.json

echo "✅ MCP-серверы восстановлены"
```


***

#### Восстановить только агентов

```bash
# Восстановить custom agents
if [[ -d "$BACKUP_DIR/.claude/agents" ]]; then
  mkdir -p ~/.claude/agents
  cp -r "$BACKUP_DIR/.claude/agents/"* ~/.claude/agents/
  echo "✅ Агенты восстановлены"
fi
```


***

#### Восстановить только хуки

```bash
# Восстановить hooks
if [[ -d "$BACKUP_DIR/.claude/hooks" ]]; then
  mkdir -p ~/.claude/hooks
  cp -r "$BACKUP_DIR/.claude/hooks/"* ~/.claude/hooks/
  chmod +x ~/.claude/hooks/*.sh 2>/dev/null || true
  echo "✅ Хуки восстановлены"
fi
```


***

### 10.4 Восстановление на новой машине

⏱️ **Время:** 10-20 минут

```bash
# 1. Установить Claude Code на новой машине
curl -fsSL https://claude.ai/install.sh | bash

# 2. Скопировать бэкап на новую машину (например, через scp)
scp -r old-machine:~/claude-backup-20260130-102245 ~/

# 3. Восстановить настройки
BACKUP_DIR=~/claude-backup-20260130-102245
cp "$BACKUP_DIR/.claude.json" ~/.claude.json
cp -r "$BACKUP_DIR/.claude" ~/.claude

# 4. Перезапустить shell
source ~/.zshrc  # или ~/.bashrc

# 5. Проверить
claude doctor
```


***

## 11. Автоматизация установки

### 11.1 Bash-скрипт для автоматической установки

**Файл:** `install-claude-automated.sh`

```bash
#!/bin/bash
# Automated Claude Code Installation Script v2.0
# Supports: macOS (Intel/Apple Silicon), Linux (Debian/Ubuntu/Alpine)

set -euo pipefail

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функции логирования
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Конфигурация
BACKUP_ENABLED="${CLAUDE_BACKUP:-true}"
FORCE_ARM64="${CLAUDE_FORCE_ARM64:-false}"
INSTALL_METHOD="${CLAUDE_INSTALL_METHOD:-auto}"  # auto, manual

# Определение платформы
detect_platform() {
  local os=$(uname -s | tr '[:upper:]' '[:lower:]')
  local arch=$(uname -m)
  
  case "$arch" in
    x86_64|amd64) arch="x64" ;;
    arm64|aarch64) arch="arm64" ;;
    *) log_error "Unsupported architecture: $arch"; exit 1 ;;
  esac
  
  # Проверка musl на Linux
  if [[ "$os" == "linux" ]]; then
    if ldd /bin/ls 2>&1 | grep -q musl; then
      echo "${os}-${arch}-musl"
    else
      echo "${os}-${arch}"
    fi
  else
    echo "${os}-${arch}"
  fi
}

# Создание бэкапа
create_backup() {
  if [[ "$BACKUP_ENABLED" != "true" ]]; then
    log_info "Backup disabled, skipping"
    return 0
  fi
  
  log_info "Creating backup..."
  
  local backup_dir=~/claude-backup-$(date +%Y%m%d-%H%M%S)
  mkdir -p "$backup_dir"
  
  [[ -f ~/.claude.json ]] && cp ~/.claude.json "$backup_dir/"
  [[ -d ~/.claude ]] && cp -r ~/.claude "$backup_dir/"
  
  cat > "$backup_dir/backup-manifest.json" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "hostname": "$(hostname)",
  "platform": "$(detect_platform)",
  "script_version": "2.0"
}
EOF
  
  log_info "Backup created: $backup_dir"
  echo "$backup_dir"
}

# Удаление NPM-версии
remove_npm_version() {
  if ! command -v npm &>/dev/null; then
    log_info "npm not found, skipping removal"
    return 0
  fi
  
  log_info "Checking for NPM version..."
  
  local npm_package=$(npm list -g 2>/dev/null | grep -E '@anthropic.*claude' | head -1 | awk '{print $1}' || true)
  
  if [[ -z "$npm_package" ]]; then
    log_info "No NPM version found"
    return 0
  fi
  
  log_info "Found NPM package: $npm_package"
  log_info "Removing NPM version..."
  
  npm uninstall -g "$npm_package" || {
    log_warn "Failed to uninstall, trying with sudo..."
    sudo npm uninstall -g "$npm_package"
  }
  
  log_info "NPM version removed"
}

# Установка (автоматическая)
install_automatic() {
  log_info "Starting automatic installation..."
  
  curl -fsSL https://claude.ai/install.sh | bash
  
  log_info "Automatic installation completed"
}

# Установка (ручная для ARM64)
install_manual_arm64() {
  log_info "Starting manual ARM64 installation..."
  
  local version=$(curl -fsSL https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/stable)
  log_info "Installing version: $version"
  
  log_info "Downloading ARM64 binary..."
  curl -fsSL -o /tmp/claude-arm64 \
    "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/darwin-arm64/claude"
  
  log_info "Verifying architecture..."
  local file_type=$(file /tmp/claude-arm64)
  
  if ! echo "$file_type" | grep -q "arm64"; then
    log_error "Downloaded binary is not ARM64: $file_type"
    rm /tmp/claude-arm64
    exit 1
  fi
  
  log_info "Installing..."
  chmod +x /tmp/claude-arm64
  /tmp/claude-arm64 install stable
  rm /tmp/claude-arm64
  
  log_info "Manual ARM64 installation completed"
}

# Проверка установки
verify_installation() {
  log_info "Verifying installation..."
  
  # Reload shell
  if [[ -f ~/.zshrc ]]; then
    source ~/.zshrc
  elif [[ -f ~/.bashrc ]]; then
    source ~/.bashrc
  fi
  
  # Проверка команды
  if ! command -v claude &>/dev/null; then
    log_error "claude command not found in PATH"
    log_error "Check if ~/.local/bin is in your PATH"
    exit 1
  fi
  
  # Проверка архитектуры
  local binary_path=$(which claude)
  local file_info=$(file "$binary_path")
  log_info "Binary: $binary_path"
  log_info "Architecture: $file_info"
  
  # Проверка версии
  local version=$(claude --version 2>&1 | head -1)
  log_info "Version: $version"
  
  # Проверка предупреждения AVX (для macOS ARM64)
  if [[ "$(uname -s)" == "Darwin" ]] && [[ "$(uname -m)" == "arm64" ]]; then
    if echo "$version" | grep -q "AVX"; then
      log_error "AVX warning detected! Wrong architecture installed (x64 instead of arm64)"
      log_error "Binary info: $file_info"
      exit 1
    fi
  fi
  
  log_info "✅ Installation verified successfully"
}

# Главная функция
main() {
  log_info "=== Claude Code Automated Installation ==="
  log_info "Platform: $(detect_platform)"
  log_info "Backup: $BACKUP_ENABLED"
  log_info "Install method: $INSTALL_METHOD"
  
  # 1. Создать бэкап
  if [[ "$BACKUP_ENABLED" == "true" ]]; then
    BACKUP_DIR=$(create_backup)
    log_info "Backup location: $BACKUP_DIR"
  fi
  
  # 2. Удалить NPM-версию
  remove_npm_version
  
  # 3. Установить
  if [[ "$INSTALL_METHOD" == "manual" ]] || [[ "$FORCE_ARM64" == "true" ]]; then
    if [[ "$(uname -s)" == "Darwin" ]] && [[ "$(uname -m)" == "arm64" ]]; then
      install_manual_arm64
    else
      log_warn "Manual ARM64 installation requested but not on macOS ARM64"
      log_warn "Falling back to automatic installation"
      install_automatic
    fi
  else
    install_automatic
  fi
  
  # 4. Проверить
  verify_installation
  
  log_info "=== Installation Complete ==="
  log_info "Run 'claude --help' to get started"
}

# Запуск
main "$@"
```

**Использование:**

```bash
# Сделать исполняемым
chmod +x install-claude-automated.sh

# Запуск с дефолтными настройками
./install-claude-automated.sh

# Без бэкапа
CLAUDE_BACKUP=false ./install-claude-automated.sh

# Принудительная ручная установка ARM64
CLAUDE_FORCE_ARM64=true ./install-claude-automated.sh

# Только автоматическая установка (без удаления NPM)
CLAUDE_INSTALL_METHOD=auto ./install-claude-automated.sh
```


***

### 11.2 GitHub Actions Workflow

**Файл:** `.github/workflows/setup-claude-code.yml`

```yaml
name: Setup Claude Code

on:
  workflow_dispatch:
  push:
    branches: [main]

jobs:
  setup-macos:
    runs-on: macos-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Install Claude Code
        run: |
          curl -fsSL https://claude.ai/install.sh | bash
          echo "$HOME/.local/bin" >> $GITHUB_PATH
      
      - name: Verify Installation
        run: |
          claude --version
          file ~/.local/bin/claude
      
      - name: Run Claude Code
        run: |
          claude -p "Generate a hello world in Python" > output.py
          cat output.py
  
  setup-linux:
    runs-on: ubuntu-latest
    
    steps:
      - name: Install Dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y curl ca-certificates git ripgrep
      
      - name: Install Claude Code
        run: |
          curl -fsSL https://claude.ai/install.sh | bash
          echo "$HOME/.local/bin" >> $GITHUB_PATH
      
      - name: Verify Installation
        run: |
          claude --version
          file ~/.local/bin/claude
          
      - name: Run Test
        run: |
          claude -p "Echo 'CI test successful'"
```


***

## 12. Проверка и диагностика

### 12.1 Базовая проверка

```bash
# Версия
claude --version

# Полная диагностика
claude doctor

# Путь к бинарнику
which claude

# Архитектура
file $(which claude)
```


***

### 12.2 Детальная диагностика

**Скрипт:** `claude-diagnostic.sh`

```bash
#!/bin/bash
# Claude Code Diagnostic Script

echo "=== Claude Code Diagnostics ==="
echo ""

# 1. Версия
echo "📦 Version:"
claude --version 2>&1 || echo "❌ claude command not found"
echo ""

# 2. Путь
echo "📍 Location:"
which claude || echo "❌ Not in PATH"
echo ""

# 3. Архитектура
echo "🔧 Architecture:"
if command -v claude &>/dev/null; then
  file $(which claude)
fi
echo ""

# 4. Installation method
echo "💿 Installation Method:"
claude doctor 2>&1 | grep "Currently running" || echo "❌ Cannot determine"
echo ""

# 5. Auto-updates
echo "🔄 Auto-updates:"
claude doctor 2>&1 | grep -A3 "Updates" || echo "❌ Cannot determine"
echo ""

# 6. Конфигурация
echo "⚙️  Configuration:"
if [[ -f ~/.claude.json ]]; then
  echo "✅ ~/.claude.json exists ($(du -h ~/.claude.json | cut -f1))"
else
  echo "⚠️  ~/.claude.json not found"
fi

if [[ -d ~/.claude ]]; then
  echo "✅ ~/.claude/ exists ($(du -sh ~/.claude | cut -f1))"
  echo "   Contents:"
  ls -1 ~/.claude | sed 's/^/   - /'
else
  echo "⚠️  ~/.claude/ not found"
fi
echo ""

# 7. PATH
echo "🛤️  PATH check:"
if echo "$PATH" | grep -q ".local/bin"; then
  echo "✅ ~/.local/bin in PATH"
else
  echo "❌ ~/.local/bin NOT in PATH"
fi
echo ""

# 8. Платформа
echo "💻 Platform:"
echo "   OS: $(uname -s)"
echo "   Arch: $(uname -m)"
if [[ "$(uname -s)" == "Darwin" ]]; then
  echo "   Rosetta: $(sysctl sysctl.proc_translated 2>/dev/null | awk '{print $2}')"
fi
echo ""

# 9. MCP Servers
echo "🔌 MCP Servers:"
if [[ -f ~/.claude.json ]]; then
  if command -v jq &>/dev/null; then
    jq -r '.mcp.servers | keys[]' ~/.claude.json 2>/dev/null || echo "   No MCP servers configured"
  else
    echo "   (install jq for detailed info)"
  fi
else
  echo "   No configuration file"
fi
echo ""

echo "=== End Diagnostics ==="
```

**Запуск:**

```bash
chmod +x claude-diagnostic.sh
./claude-diagnostic.sh
```


***

## 13. FAQ (Часто задаваемые вопросы)

### 13.1 Общие вопросы

**Q: В чем разница между NPM и нативной версией?**

A:

- **NPM-версия:** Требует Node.js, устаревшая (deprecated), размер установки больше
- **Нативная версия:** Standalone бинарник, автообновления, лучшая производительность, рекомендуется

**Q: Можно ли использовать обе версии одновременно?**

A: Нет, будет конфликт. Используйте только одну версию.

**Q: Как переключиться с stable на latest канал?**

A:

```bash
# Установить latest
claude install latest

# Проверить
claude doctor | grep "Auto-update channel"
```

**Q: Как полностью удалить Claude Code?**

A:

```bash
# Удалить бинарник
rm -f ~/.local/bin/claude

# Удалить настройки (ОСТОРОЖНО! Потеряете все данные)
rm -f ~/.claude.json
rm -rf ~/.claude

# Удалить бэкапы
rm -rf ~/claude-backup-*
```


***

### 13.2 Проблемы с архитектурой (macOS)

**Q: Почему на Apple Silicon установилась x64 версия?**

A: Известная проблема (GitHub Issue \#4749). Скрипт `bootstrap.sh` может неправильно определить архитектуру в pipe. Используйте [ручную установку ARM64](#73-%D1%80%D1%83%D1%87%D0%BD%D0%B0%D1%8F-%D1%83%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0-arm64-100-%D0%B3%D0%B0%D1%80%D0%B0%D0%BD%D1%82%D0%B8%D1%8F).

**Q: Как проверить, что установлена правильная архитектура?**

A:

```bash
file ~/.local/bin/claude

# Для Apple Silicon должно быть: arm64
# Для Intel Mac должно быть: x86_64
```

**Q: Что делать с предупреждением AVX на M1/M2/M3?**

A: Это означает, что установлена x64 версия. Удалите и переустановите ARM64 версию:

```bash
rm -f ~/.local/bin/claude
# Затем используйте Раздел 7.3
```


***

### 13.3 Медленная установка или таймаут

**Q: Установка очень медленная (скорость <100 KB/s). Что делать?**

A:

1. **VPN:** Используйте VPN с сервером в EU/US
2. **Альтернативный интернет:** Попробуйте мобильный интернет
3. **Ночная установка:** Оставьте установку на ночь (~1-2 часа)
4. **Проверка сети:**
```bash
# Проверить доступность Google Cloud Storage
curl -I --connect-timeout 10 https://storage.googleapis.com

# Если недоступен → используйте VPN
```

**Q: Установка зависает на "Setting up Claude Code..."**

A:

1. Проверьте сетевую активность (мониторинг из нашего опыта)
2. Подождите до 90 минут при медленном интернете
3. Если реально зависла (нет сетевой активности 10+ минут):
```bash
# Прервать (Ctrl+C)
# Очистить
rm -rf /tmp/claude-* ~/.claude/downloads/claude-*

# Попробовать снова
```


***

### 13.4 Проблемы с PATH

**Q: После установки `command not found: claude`**

A: ~/.local/bin не в PATH. Добавьте:

```bash
# Для zsh (macOS по умолчанию)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Для bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Проверить
which claude
```


***

### 13.5 Docker

**Q: Docker контейнер скачивает не ту архитектуру**

A: Используйте `ARG TARGETARCH` в Dockerfile:

```dockerfile
ARG TARGETARCH
RUN PLATFORM="linux-${TARGETARCH}" && \
    curl ... "${PLATFORM}/claude"
```

Или явно указывайте платформу:

```bash
docker build --platform=linux/arm64 -t claude-code:arm64 .
```

**Q: Как передать API ключ в Docker контейнер?**

A:

```bash
docker run -it --rm \
  -e ANTHROPIC_API_KEY=your-key \
  -v $(pwd):/workspace \
  claude-code:latest
```


***

### 13.6 MCP и настройки

**Q: Как сохранить MCP-серверы при миграции?**

A: Они автоматически сохраняются в `~/.claude.json` при бэкапе ([Раздел 5](#5-%D1%83%D0%BD%D0%B8%D0%B2%D0%B5%D1%80%D1%81%D0%B0%D0%BB%D1%8C%D0%BD%D0%B0%D1%8F-%D0%BF%D1%80%D0%BE%D1%86%D0%B5%D0%B4%D1%83%D1%80%D0%B0-%D1%80%D0%B5%D0%B7%D0%B5%D1%80%D0%B2%D0%BD%D0%BE%D0%B3%D0%BE-%D0%BA%D0%BE%D0%BF%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D1%8F)).

**Q: Как вручную скопировать MCP конфигурацию?**

A:

```bash
# Экспорт
jq '.mcp' ~/.claude.json > mcp-backup.json

# Импорт на новой машине
jq --slurpfile mcp mcp-backup.json '.mcp = $mcp[0]' ~/.claude.json > temp.json
mv temp.json ~/.claude.json
```


***

## 14. Глоссарий

| Термин | Определение |
| :-- | :-- |
| **ARM64** | 64-битная ARM архитектура (Apple Silicon M1/M2/M3, AWS Graviton) |
| **x86_64** | 64-битная Intel/AMD архитектура (стандартные процессоры) |
| **Apple Silicon** | ARM-процессоры Apple (M1, M2, M3, M4) |
| **Rosetta 2** | Эмулятор x86_64 на Apple Silicon для запуска Intel-приложений |
| **glibc** | GNU C Library — стандартная C библиотека для Linux |
| **musl** | Легковесная C библиотека (используется в Alpine Linux) |
| **MCP** | Model Context Protocol — протокол для интеграции Claude с внешними сервисами |
| **Natively** | Запуск приложения в родной архитектуре процессора (без эмуляции) |
| **Universal Binary** | macOS бинарник, содержащий код для обеих архитектур (Intel + ARM) |
| **AVX** | Advanced Vector Extensions — инструкции процессора для векторных операций |
| **Bootstrap** | Установочный скрипт, определяющий платформу и запускающий установку |
| **Manifest** | JSON-файл с метаданными о доступных версиях и контрольных суммах |


***

## 15. Дополнительные ресурсы

### 15.1 Официальная документация

- **Главная страница:** https://code.claude.com
- **Документация:** https://code.claude.com/docs
- **Setup Guide:** https://code.claude.com/docs/en/setup
- **Troubleshooting:** https://code.claude.com/docs/en/troubleshooting
- **Settings Reference:** https://code.claude.com/docs/en/settings


### 15.2 GitHub

- **Issues:** https://github.com/anthropics/claude-code/issues
- **Известные проблемы архитектуры:**
    - Issue \#4749: Architecture Mismatch on Apple Silicon
    - Issue \#13617: ARM64 Binary Replaced
    - Issue \#15975: AVX warning + performance issues


### 15.3 Сообщество

- **Reddit:** r/ClaudeAI, r/ClaudeCode
- **Discord:** Anthropic Community Server
- **Twitter:** @AnthropicAI


### 15.4 Релизы

- **Stable версия:** https://storage.googleapis.com/.../stable
- **Latest версия:** https://storage.googleapis.com/.../latest
- **Manifest:** https://storage.googleapis.com/.../manifest.json

***

## 🔗 Связанные документы проекта

### Основная документация glm-docker-tools:
- **[🏠 Главная](../README.md)** - Quick start и навигация проекта
- **[📋 Сводки сессий](../SESSIONS.md)** - История всех сессий
- **[🔧 Script Logic](./SCRIPT_LOGIC.md)** - Логика работы скриптов v2.1
- **[🐳 Docker Authentication](../DOCKER_AUTHENTICATION_RESEARCH.md)** - Аутентификация в Docker

### Конфигурация:
- **[🌐 GLM API Integration](./Claude-Code-GLM.md)** - Настройка GLM API
- **[⚙️ Settings Reference](./Claude-Code-settings.md)** - Полная конфигурация
- **[📝 Settings Template Guide](./SETTINGS_TEMPLATE_GUIDE.md)** - Шаблон настроек

### Docker-специфично:
- **[🔄 Container Lifecycle](./CONTAINER_LIFECYCLE_MANAGEMENT.md)** - Режимы контейнера
- **[🗺️ Docker Mapping Diagram](./DOCKER_MAPPING_DIAGRAM.md)** - Схема volume mapping

**См. также:** [Полный индекс документации](./index.md)

---

## Changelog документа

| Версия | Дата | Изменения |
| :-- | :-- | :-- |
| 1.1 | 2026-01-30 | Добавлены хлебные крошки и связанные документы glm-docker-tools |
| 1.0 | 2026-01-30 | Первая версия |

---

**Статус документа**: Stable
**Дата**: 2026-01-30
**Связь с проектом**: [glm-docker-tools](https://github.com/RussianLioN/glm-docker-tools)

