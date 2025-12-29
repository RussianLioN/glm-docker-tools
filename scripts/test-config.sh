#!/bin/bash
# Тестовый скрипт для проверки конфигурации Claude

echo "=== Тест конфигурации Claude ==="

# Установка переменных перед загрузкой
export CLAUDE_STATE_DIR="$HOME/.claude"
echo "Установили CLAUDE_STATE_DIR: $CLAUDE_STATE_DIR"

# Загрузка основной конфигурации
source /Users/s060874gmail.com/coding/projects/claude-code-docker-tools/ai-assistant.zsh 2>/dev/null

echo "После загрузки ai-assistant.zsh: $CLAUDE_STATE_DIR"

# Принудительное переопределение после загрузки
export CLAUDE_STATE_DIR="$HOME/.claude"
echo "Принудительно установили: $CLAUDE_STATE_DIR"

# Тест Docker volume mapping
echo "=== Тест Docker volume mapping ==="
docker run --rm \
  -v "$CLAUDE_STATE_DIR":/root/.claude \
  -e CLAUDE_CONFIG_DIR=/root/.claude \
  glm-docker-tools:latest \
  ls -la /root/.claude/history.jsonl 2>/dev/null || echo "Тест завершен"

echo "=== Конец теста ==="