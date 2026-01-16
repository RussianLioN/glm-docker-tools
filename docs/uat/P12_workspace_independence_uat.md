# UAT Test Plan: P12 - Workspace Independence

> 📋 **Feature**: P12 - Workspace Independence (⚠️ КРИТИЧЕСКАЯ ВАЖНОСТЬ)
>
> **Version**: 2.0 (Hybrid AI-User Testing)
> **Status**: Ready for Execution
> **Created**: 2026-01-16

---

## User Story

**As a** разработчик, работающий над проектом
**I want** запускать Claude Code из любой директории проекта (не только из корня)
**So that** я могу работать в поддиректориях (`src/components/`, `docs/`, etc.) и иметь доступ ко всем файлам проекта

---

## Acceptance Criteria

- [ ] **AC1**: Скрипт можно запустить из любой директории проекта (корень, поддиректория, вне проекта)
- [ ] **AC2**: Автоматическое определение корня проекта (по маркерам: `.git`, `glm-launch.sh`, `Dockerfile`)
- [ ] **AC3**: Корректное маппинг:
  - `PROJECT_ROOT` → `/workspace` (весь проект)
  - `WORKSPACE` (текущая папка) → `/workspace/current` (текущая папка)
- [ ] **AC4**: Доступ к файлам всего проекта через `/workspace/`
- [ ] **AC5**: Доступ к файлам текущей директории через `/workspace/current/`

---

## Test Environment

- **OS**: macOS (Darwin 25.3.0)
- **Docker**: Engine v29.1.3
- **Shell**: bash
- **Project**: glm-docker-tools
- **Image**: glm-docker-tools:latest

---

## Prerequisites

- [ ] Docker daemon запущен
- [ ] Образ `glm-docker-tools:latest` существует
- [ ] API ключ настроен (secrets/.env)
- [ ] Находитесь в проекте `glm-docker-tools`

---

## Test Scenarios

### AI-Automated Tests (70-80%) - Выполняет AI

#### [AI-AUTO] Check 1: Code Structure Validation

**What AI Checks:**
- Функция `find_project_root()` существует в `glm-launch.sh`
- Функция использует маркеры проекта (`.git`, `glm-launch.sh`, `Dockerfile`)
- Корректный поиск вверх по директориям

**Automation:**
```bash
grep -A 30 "find_project_root()" glm-launch.sh
```

**Success Criteria:**
- Функция найдена (grep exit code 0)
- Использует `while [[ "$current_dir" != "/" ]]` для поиска вверх
- Проверяет маркеры: `.git`, `glm-launch.sh`, или `Dockerfile`

---

#### [AI-AUTO] Check 2: Variable Usage Verification

**What AI Checks:**
- Переменная `PROJECT_ROOT` объявлена и используется
- `WORKSPACE` остается как текущая директория
- Volume mapping использует обе переменные

**Automation:**
```bash
grep -E "PROJECT_ROOT|WORKSPACE" glm-launch.sh | head -20
```

**Success Criteria:**
- `PROJECT_ROOT` объявлена (не закомментирована)
- `PROJECT_ROOT="$(find_project_root)"`
- `WORKSPACE="${WORKSPACE:-$(pwd)}"`
- Volume mapping: `-v "$PROJECT_ROOT:/workspace:cached"`
- Volume mapping: `-v "$WORKSPACE:/workspace/current"`

---

#### [AI-AUTO] Check 3: Working Directory Configuration

**What AI Checks:**
- Рабочая директория в контейнере установлена в `/workspace/current`
- Fallback на `/workspace` если находимся в корне проекта

**Automation:**
```bash
grep -A 5 "WORKSPACE.*current" glm-launch.sh
```

**Success Criteria:**
- Рабочая директория `-w "/workspace/current"` (или подобная логика)
- Логика выбора рабочей директории в зависимости от расположения

---

#### [AI-AUTO] Check 4: Integration Points

**What AI Checks:**
- `find_project_root()` вызывается перед `run_claude()`
- Логирование показывает `PROJECT_ROOT` и `WORKSPACE`

**Automation:**
```bash
grep -B 5 -A 5 "find_project_root" glm-launch.sh
```

**Success Criteria:**
- Функция вызывается в `main()` или перед `run_claude()`
- Логи содержат информацию о проекте и рабочей директории

---

#### [AI-AUTO] Check 5: Syntax Validation

**What AI Checks:**
- shellcheck не находит ошибок (если доступен)
- Базовый синтаксис bash корректен

**Automation:**
```bash
bash -n glm-launch.sh && echo "Syntax OK"
```

**Success Criteria:**
- Нет синтаксических ошибок
- `bash -n` возвращает exit code 0

---

### User-Practical Tests (20-30%) - Выполняет Пользователь

#### [USER-PRACTICAL] Test 1: Запуск из корня проекта

**User Action:**
```bash
cd ~/coding/projects/glm-docker-tools
./glm-launch.sh --dry-run
```

**What to Verify:**
1. `PROJECT_ROOT` указывает на корень проекта
2. `WORKSPACE` совпадает с `PROJECT_ROOT` (мы в корне)
3. Volume mapping содержит `-v "$PROJECT_ROOT:/workspace:cached"`

**Success Criteria:**
- ✅ Сообщение `PROJECT_ROOT: /Users/.../glm-docker-tools`
- ✅ Сообщение `WORKSPACE: /Users/.../glm-docker-tools` (совпадает)
- ✅ Volume mapping виден в dry-run выводе

**User Response:**
Reply "PASS" or "FAIL" with dry-run output

---

#### [USER-PRACTICAL] Test 2: Запуск из поддиректории

**User Action:**
```bash
cd ~/coding/projects/glm-docker-tools/docs
../glm-launch.sh --dry-run
```

**What to Verify:**
1. `PROJECT_ROOT` найден (вышел на уровень вверх)
2. `WORKSPACE` указывает на текущую поддиректорию (`docs`)
3. Два volume mapping: корень проекта И текущая директория

**Success Criteria:**
- ✅ `PROJECT_ROOT: /Users/.../glm-docker-tools` (нашел корень)
- ✅ `WORKSPACE: /Users/.../glm-docker-tools/docs` (текущая папка)
- ✅ Volume mapping содержит оба пути

**User Response:**
Reply "PASS" or "FAIL" with dry-run output

---

#### [USER-PRACTICAL] Test 3: Доступ к файлам (реальный запуск)

**User Action:**
```bash
cd ~/coding/projects/glm-docker-tools/docs
../glm-launch.sh
```

Внутри Claude Code выполнить:
```
Read("/workspace/README.md")  # Файл из корня проекта
Read("/workspace/current/IMPLEMENTATION_PLAN.md")  # Файл из текущей папки
```

**What to Verify:**
1. Первый `Read()` успешно читает файл из корня проекта
2. Второй `Read()` успешно читает файл из текущей папки (`docs/`)
3. Оба файла доступны без ошибок

**Success Criteria:**
- ✅ Файл `/workspace/README.md` прочитан успешно
- ✅ Файл `/workspace/current/IMPLEMENTATION_PLAN.md` прочитан успешно
- ✅ Нет ошибок доступа (ENOENT, permission denied)

**User Response:**
Reply "PASS" or "FAIL" with Claude Code output

---

## Edge Cases

### Edge Case 1: Запуск вне проекта

**Scenario:** Пользователь запускает скрипт из `/tmp/`

**Expected Behavior:**
- `find_project_root()` находит проект по `glm-launch.sh` в пути
- `PROJECT_ROOT` установлен корректно
- `WORKSPACE` = `/tmp` (текущая директория)

**Test:**
```bash
cd /tmp
~/coding/projects/glm-docker-tools/glm-launch.sh --dry-run
```

---

### Edge Case 2: Глубокая вложенность

**Scenario:** Пользователь в `src/components/ui/buttons/`

**Expected Behavior:**
- `find_project_root()` поднимается вверх до маркера проекта
- Все файлы проекта доступны через `/workspace/`

**Test:**
```bash
cd ~/coding/projects/glm-docker-tools/src  # Если есть src/
../../glm-launch.sh --dry-run
```

---

### Edge Case 3: Нет маркеров проекта

**Scenario:** Директория без `.git`, `glm-launch.sh`, `Dockerfile`

**Expected Behavior:**
- Fallback на директорию самого скрипта
- Предупреждение пользователю

**Test:**
```bash
mkdir /tmp/test_no_markers
cd /tmp/test_no_markers
~/coding/projects/glm-docker-tools/glm-launch.sh --dry-run
```

---

## Troubleshooting

### Issue: "PROJECT_ROOT not found"

**Cause:** Скрипт не может найти маркеры проекта

**Fix:**
1. Проверьте наличие `.git`, `glm-launch.sh`, или `Dockerfile`
2. Убедитесь, что вы в Git репозитории
3. Проверьте логи отладки

---

### Issue: "Files not accessible in container"

**Cause:** Неверный volume mapping

**Fix:**
1. Проверьте вывод `--dry-run` для volume mapping
2. Убедитесь, что оба пути (PROJECT_ROOT и WORKSPACE) замаплены
3. Проверьте права доступа к файлам

---

## Definition of Done

### Code Quality
- [ ] Код следует конвенциям проекта
- [ ] Нет hardcoded values
- [ ] Error handling реализован
- [ ] Логирование добавлено

### Testing
- [ ] Все AI-Automated проверки PASSED (5/5)
- [ ] Все User-Practical тесты PASSED (3/3)
- [ ] Edge Cases протестированы

### Documentation
- [ ] `docs/SCRIPT_LOGIC.md` обновлен
- [ ] `SESSION_HANDOFF.md` обновлен
- [ ] `README.md` обновлен (если нужно)

### Version Control
- [ ] Changes committed
- [ ] Commit message содержит "P12" и UAT результаты
- [ ] Pushed to remote

### User Acceptance
- [ ] User explicitly states: "P12 UAT PASSED"
- [ ] User approves: "Feature works as expected"

---

## Execution Log

| Date | Test | Result | Notes |
|------|------|--------|-------|
| 2026-01-16 | Plan created | ✅ | Ready for execution |
| | | | |
| | | | |

---

**Status**: ✅ Ready for AI-Automated Checks
**Next Step**: Execute AI-Automated Checks (Phase 1)
