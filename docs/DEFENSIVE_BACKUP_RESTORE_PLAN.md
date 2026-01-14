# План Реализации: Defensive Backup/Restore для P8

> **Статус**: 📋 ПЛАНИРОВАНИЕ
> **Приоритет**: 🔴 CRITICAL
> **Время**: ~30-45 минут
> **Дата**: 2025-12-30

---

## 🎯 Цель

Реализовать надежный механизм backup/restore для `~/.claude/settings.json` с максимальной защитой от data loss при работе с GLM контейнером.

---

## 📊 Контекст

**Проблема**: Текущий backup/restore код (glm-launch.sh:205-231) не имеет:
- Pre-backup validation
- Post-backup verification
- Error handling для cp/mv операций
- Recovery механизма при failures

**Риск**: 2-5% случаев могут привести к потере production config (Sonnet Pro).

**Решение**: Defensive backup/restore с triple-layer safety.

---

## 📋 План Реализации

### Phase 1: Подготовка (5 минут)

**Задачи**:
1. Создать backup текущей версии `glm-launch.sh`
2. Создать test environment для валидации
3. Подготовить rollback процедуру

**Команды**:
```bash
# Backup текущей версии
cp glm-launch.sh glm-launch.sh.backup-before-defensive

# Создать test directory
mkdir -p /tmp/defensive_test
```

**Критерий завершения**: Backup файл создан и доступен для rollback.

---

### Phase 2: Реализация backup_system_settings() (10 минут)

**Текущий код** (строки 205-213):
```bash
backup_system_settings() {
    if [[ ! -f "$CLAUDE_HOME/settings.json" ]]; then
        return 0
    fi

    local backup_file="$CLAUDE_HOME/.settings.backup.$$"
    cp "$CLAUDE_HOME/settings.json" "$backup_file"  # ❌ Unchecked
    echo "$backup_file"
}
```

**Новый defensive код**:
```bash
backup_system_settings() {
    if [[ ! -f "$CLAUDE_HOME/settings.json" ]]; then
        return 0  # No settings to backup
    fi

    # Layer 1: Pre-backup validation

    # Validate source JSON structure
    if ! jq empty "$CLAUDE_HOME/settings.json" 2>/dev/null; then
        log_error "❌ Source settings.json corrupted, cannot backup"
        log_error "   File: $CLAUDE_HOME/settings.json"
        return 1
    fi

    # Check disk space (minimum 1MB = 1024KB)
    local available=$(df -k "$CLAUDE_HOME" | awk 'NR==2 {print $4}')
    if [[ $available -lt 1024 ]]; then
        log_error "❌ Insufficient disk space for backup (need 1MB, have ${available}KB)"
        return 1
    fi

    # Check write permissions
    if [[ ! -w "$CLAUDE_HOME" ]]; then
        log_error "❌ No write permission to $CLAUDE_HOME"
        return 1
    fi

    # Layer 2: Atomic backup with verification

    local backup_file="$CLAUDE_HOME/.settings.backup.$$"

    # Atomic copy
    if ! cp "$CLAUDE_HOME/settings.json" "$backup_file"; then
        log_error "❌ Failed to create backup"
        return 1
    fi

    # Verify backup integrity (JSON validation)
    if ! jq empty "$backup_file" 2>/dev/null; then
        log_error "❌ Backup corrupted after creation"
        rm -f "$backup_file"
        return 1
    fi

    # Verify file size matches
    local orig_size=$(stat -f%z "$CLAUDE_HOME/settings.json" 2>/dev/null || stat -c%s "$CLAUDE_HOME/settings.json" 2>/dev/null)
    local backup_size=$(stat -f%z "$backup_file" 2>/dev/null || stat -c%s "$backup_file" 2>/dev/null)

    if [[ $backup_size -ne $orig_size ]]; then
        log_error "❌ Backup size mismatch (original: ${orig_size}B, backup: ${backup_size}B)"
        rm -f "$backup_file"
        return 1
    fi

    # Layer 3: Backup rotation (keep last 3)

    local backup_dir="$CLAUDE_HOME/.backups"
    mkdir -p "$backup_dir"

    # Copy verified backup to persistent location
    local timestamp=$(date +%Y%m%d-%H%M%S)
    cp "$backup_file" "$backup_dir/settings-$timestamp.json"

    # Rotate old backups (keep last 3)
    ls -t "$backup_dir"/settings-*.json 2>/dev/null | tail -n +4 | xargs -r rm -f 2>/dev/null || true

    log_success "✅ Backup created and verified: $backup_file"
    log_info "   Persistent backup: $backup_dir/settings-$timestamp.json"

    echo "$backup_file"
    return 0
}
```

**Изменения**:
- ✅ Pre-validation: JSON, disk space, permissions
- ✅ Error handling для cp операции
- ✅ Post-validation: JSON integrity, file size
- ✅ Backup rotation: keep last 3
- ✅ Explicit logging: success/failure

**Критерий завершения**: Функция заменена, синтаксис проверен (`bash -n`).

---

### Phase 3: Реализация restore_system_settings() (10 минут)

**Текущий код** (строки 216-231):
```bash
restore_system_settings() {
    local backup_file="$1"

    if [[ -z "$backup_file" || ! -f "$backup_file" ]]; then
        return 0
    fi

    # Restore system settings
    cp "$backup_file" "$CLAUDE_HOME/settings.json"  # ❌ Unchecked
    rm -f "$backup_file"  # ❌ Удаляет даже если cp failed

    # Backup project settings if auto-created
    if [[ "$SETTINGS_AUTO_CREATED" == "true" && -f "./.claude/settings.json" ]]; then
        cp "./.claude/settings.json" "./.claude/settings.json.dkrbkp"
    fi
}
```

**Новый defensive код**:
```bash
restore_system_settings() {
    local backup_file="$1"

    if [[ -z "$backup_file" || ! -f "$backup_file" ]]; then
        log_info "ℹ️  No backup to restore"
        return 0
    fi

    # Layer 1: Pre-restore validation

    # Validate backup before restore
    if ! jq empty "$backup_file" 2>/dev/null; then
        log_error "❌ Backup file corrupted, cannot restore"
        log_error "   Backup location: $backup_file"
        log_error "   💡 Manual recovery: cp $backup_file $CLAUDE_HOME/settings.json"
        return 1
    fi

    # Layer 2: Atomic restore with emergency backup

    # Create temporary restore for testing
    local temp_restore="$CLAUDE_HOME/.settings.restore.tmp.$$"
    if ! cp "$backup_file" "$temp_restore"; then
        log_error "❌ Failed to create temporary restore"
        return 1
    fi

    # Create emergency backup of current settings (in case restore fails)
    local emergency_backup="$CLAUDE_HOME/.settings.emergency.$$"
    if [[ -f "$CLAUDE_HOME/settings.json" ]]; then
        cp "$CLAUDE_HOME/settings.json" "$emergency_backup" 2>/dev/null || true
    fi

    # Atomic restore (mv is atomic on same filesystem)
    if ! mv "$temp_restore" "$CLAUDE_HOME/settings.json"; then
        log_error "❌ Failed to restore settings"

        # Attempt emergency recovery
        if [[ -f "$emergency_backup" ]]; then
            log_warning "⚠️  Attempting emergency recovery..."
            if mv "$emergency_backup" "$CLAUDE_HOME/settings.json" 2>/dev/null; then
                log_success "✅ Emergency recovery successful"
            else
                log_error "❌ Emergency recovery failed"
                log_error "   💡 Manual recovery needed: $backup_file or $emergency_backup"
            fi
        fi
        return 1
    fi

    log_success "✅ System settings restored: $CLAUDE_HOME/settings.json"

    # Layer 3: Cleanup and archival

    # Keep backup for emergency recovery (don't delete immediately)
    local safe_backup="$CLAUDE_HOME/.settings.last_session"
    if ! mv "$backup_file" "$safe_backup" 2>/dev/null; then
        # If move fails, at least try to remove temp backup
        rm -f "$backup_file" 2>/dev/null || true
    fi

    # Remove emergency backup (restore succeeded)
    rm -f "$emergency_backup" 2>/dev/null || true

    # Backup project settings if auto-created
    if [[ "$SETTINGS_AUTO_CREATED" == "true" && -f "./.claude/settings.json" ]]; then
        if cp "./.claude/settings.json" "./.claude/settings.json.dkrbkp" 2>/dev/null; then
            log_info "   Project settings backed up: ./.claude/settings.json.dkrbkp"
        fi
    fi

    return 0
}
```

**Изменения**:
- ✅ Pre-validation: JSON integrity
- ✅ Atomic restore: temp → mv (atomic)
- ✅ Emergency backup: создается до restore
- ✅ Recovery logic: если restore failed
- ✅ Safe cleanup: backup сохраняется как `.last_session`
- ✅ Explicit logging: каждый шаг

**Критерий завершения**: Функция заменена, синтаксис проверен.

---

### Phase 4: Обновление .gitignore (2 минуты)

**Добавить новые backup patterns**:
```gitignore
# P8: Defensive Backup/Restore
.claude/.settings.backup.*
.claude/.settings.restore.tmp.*
.claude/.settings.emergency.*
.claude/.settings.last_session
.claude/.backups/
.claude/settings.json.dkrbkp
*.dkrbkp
```

**Критерий завершения**: `.gitignore` обновлен, новые patterns добавлены.

---

### Phase 5: Тестирование (10 минут)

**Test Suite**:

```bash
# Test 1: Happy path
test_backup_restore_happy() {
    # Setup
    echo '{"test":"original"}' > /tmp/test_settings.json
    export CLAUDE_HOME=/tmp

    # Execute
    backup=$(backup_system_settings)
    echo '{"test":"modified"}' > /tmp/test_settings.json
    restore_system_settings "$backup"

    # Verify
    grep -q '"test":"original"' /tmp/test_settings.json
}

# Test 2: Corrupted source
test_backup_corrupted_source() {
    # Setup
    echo 'INVALID JSON' > /tmp/test_settings.json
    export CLAUDE_HOME=/tmp

    # Execute (должен fail)
    ! backup_system_settings
}

# Test 3: Disk full simulation
test_backup_no_space() {
    # Симуляция через mock df
    # (сложно без root, пропустить в MVP)
}

# Test 4: Corrupted backup
test_restore_corrupted_backup() {
    # Setup
    echo 'INVALID JSON' > /tmp/corrupted.backup
    export CLAUDE_HOME=/tmp

    # Execute (должен fail с явной ошибкой)
    ! restore_system_settings "/tmp/corrupted.backup"
}

# Test 5: Emergency recovery
test_restore_emergency_recovery() {
    # Setup
    echo '{"test":"current"}' > /tmp/test_settings.json
    echo '{"test":"backup"}' > /tmp/test.backup
    export CLAUDE_HOME=/tmp

    # Simulate mv failure (сложно, пропустить в MVP)
}

# Test 6: Backup rotation
test_backup_rotation() {
    # Create 4 backups, verify only 3 kept
    export CLAUDE_HOME=/tmp
    mkdir -p /tmp/.backups

    for i in 1 2 3 4; do
        echo '{"test":"'$i'"}' > /tmp/test_settings.json
        backup_system_settings
        sleep 1  # Ensure different timestamps
    done

    # Verify только 3 backup files
    [[ $(ls /tmp/.backups/settings-*.json | wc -l) -eq 3 ]]
}
```

**Критерий завершения**: Минимум 4 теста пройдены (happy path + 3 edge cases).

---

### Phase 6: Интеграционное Тестирование (5 минут)

**Сценарий**: Реальный запуск GLM контейнера

```bash
# Pre-test: Snapshot current settings
cp ~/.claude/settings.json /tmp/settings_snapshot.json
md5 ~/.claude/settings.json > /tmp/settings_before.md5

# Execute: Run container
./glm-launch.sh
# (работаем в контейнере, затем выходим)

# Post-test: Verify restore
md5 ~/.claude/settings.json > /tmp/settings_after.md5
diff /tmp/settings_before.md5 /tmp/settings_after.md5  # Должны совпадать!

# Verify backups created
ls -la ~/.claude/.backups/  # Должен быть backup
ls -la ./.claude/settings.json.dkrbkp  # Должен существовать
```

**Критерий завершения**: MD5 hash до и после идентичны.

---

### Phase 7: Документация (3 минуты)

**Создать Recovery Guide**:

`docs/RECOVERY.md`:
```markdown
# Recovery Guide: Восстановление Настроек Claude Code

## Автоматическое Восстановление

При нормальном выходе из контейнера настройки восстанавливаются автоматически.

## Ручное Восстановление

Если restore failed, используйте эти шаги:

### Шаг 1: Найти последний backup
ls -lt ~/.claude/.backups/settings-*.json

### Шаг 2: Восстановить вручную
cp ~/.claude/.backups/settings-TIMESTAMP.json ~/.claude/settings.json

### Шаг 3: Проверить целостность
jq empty ~/.claude/settings.json

### Шаг 4: Перезапустить Claude Code
claude-code
```

**Критерий завершения**: Recovery guide создан и доступен.

---

## 📊 Risks & Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Backup rotation удаляет слишком много | LOW | MEDIUM | Keep 3 (достаточно для recovery) |
| Emergency backup занимает место | LOW | LOW | Auto-cleanup после успешного restore |
| jq не установлен в контейнере | LOW | HIGH | ✅ Уже добавлен в Dockerfile |
| Сломается существующий функционал | MEDIUM | HIGH | Тщательное тестирование Phase 5-6 |

---

## ✅ Критерии Успеха

1. ✅ Все тесты Phase 5 пройдены (4+/6)
2. ✅ Интеграционный тест Phase 6 пройден (MD5 match)
3. ✅ Синтаксис bash проверен (`bash -n glm-launch.sh`)
4. ✅ Backup rotation работает (keep 3)
5. ✅ Recovery guide создан
6. ✅ `.gitignore` обновлен
7. ✅ Rollback процедура готова

---

## 🔄 Rollback Процедура

Если что-то пойдет не так:

```bash
# Восстановить предыдущую версию
cp glm-launch.sh.backup-before-defensive glm-launch.sh

# Удалить новые backup файлы (опционально)
rm -rf ~/.claude/.backups/
rm -f ~/.claude/.settings.backup.*
rm -f ~/.claude/.settings.emergency.*
rm -f ~/.claude/.settings.last_session
```

---

## 📅 Timeline

| Phase | Время | Кумулятивно |
|-------|-------|-------------|
| Phase 1: Подготовка | 5 мин | 5 мин |
| Phase 2: backup_system_settings() | 10 мин | 15 мин |
| Phase 3: restore_system_settings() | 10 мин | 25 мин |
| Phase 4: .gitignore | 2 мин | 27 мин |
| Phase 5: Тестирование | 10 мин | 37 мин |
| Phase 6: Интеграция | 5 мин | 42 мин |
| Phase 7: Документация | 3 мин | 45 мин |

**Итого**: ~45 минут

---

## 🎯 Next Steps

После завершения плана:
1. Commit изменений
2. Обновить SESSION_HANDOFF.md
3. Создать UAT план для P8 v2.0
4. User acceptance testing

---

**Статус**: 📋 READY FOR REVIEW
