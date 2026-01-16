# UAT Test Plan: P13 - Shell Aliases for Universal Access

> 📋 **Feature**: P13 - Shell-функции для удобного запуска (⭐ ВАЖНАЯ ВАЖНОСТЬ)
>
> **Version**: 2.0 (Hybrid AI-User Testing)
> **Status**: Ready for Execution
> **Created**: 2026-01-16

---

## User Story

**As a** разработчик, работающий над проектом
**I want** запускать Claude Code из любой директории простыми командами (glm, glm-debug)
**So that** мне не нужно помнить полный путь к скрипту или переходить в корень проекта

---

## Acceptance Criteria

- [ ] **AC1**: Команда `glm` работает из любой директории проекта
- [ ] **AC2**: Команда `glm-debug` запускает debug режим с `--debug` флагом
- [ ] **AC3**: Команда `glm-no-del` запускает persistent режим с `--no-del` флагом
- [ ] **AC4**: Все аргументы glm-launch.sh работают через алиасы (10 аргументов)
- [ ] **AC5**: Понятные сообщения об ошибках при запуске вне проекта
- [ ] **AC6**: Алиасы работают в обеих оболочках (bash/zsh)
- [ ] **AC7**: Алиасы не модифицируют ~/.zshrc (требование пользователя)

---

## Test Environment

- **OS**: macOS (Darwin 25.3.0)
- **Shell**: zsh 5.9 (primary), bash 4.4 (fallback)
- **Docker**: Engine v29.1.3
- **Project**: glm-docker-tools
- **Image**: glm-docker-tools:latest

---

## Prerequisites

- [ ] P12 завершён (Workspace Independence работает)
- [ ] `glm-launch.sh` корректно определяет PROJECT_ROOT
- [ ] Docker daemon запущен
- [ ] API ключ настроен (secrets/.env)

---

## Test Scenarios

### AI-Automated Tests (70-80%) - Выполняет AI

#### [AI-AUTO] Check 1: File Structure Validation

**What AI Checks:**
- `scripts/glm-aliases.sh` exists
- `scripts/setup-aliases.sh` exists
- Contains all required functions: `_glm_find_project_root`, `_glm`, `glm`, `glm-debug`, `glm-no-del`, `glm-help`

**Automation:**
```bash
grep -E "^(glm|glm-debug|glm-no-del|glm-help|_glm_find_project_root|_glm)\(" scripts/glm-aliases.sh
```

**Success Criteria:**
- All 6 functions found
- Exit code 0

---

#### [AI-AUTO] Check 2: Function Syntax Validation

**What AI Checks:**
- POSIX-compliant syntax (no bashisms)
- Valid in both bash and zsh

**Automation:**
```bash
bash -n scripts/glm-aliases.sh && zsh -n scripts/glm-aliases.sh && echo "Syntax OK"
```

**Success Criteria:**
- Both shells pass syntax check
- Exit code 0

---

#### [AI-AUTO] Check 3: find_project_root Duplication

**What AI Checks:**
- `_glm_find_project_root` exists in aliases file
- Uses same markers as glm-launch.sh

**Automation:**
```bash
grep -A 25 "_glm_find_project_root" scripts/glm-aliases.sh
```

**Success Criteria:**
- Checks `.git`, `glm-launch.sh`, or `Dockerfile`
- Searches upward with while loop
- Returns 0 on success, 1 on failure

---

#### [AI-AUTO] Check 4: Argument Passing

**What AI Checks:**
- Functions use `"$@"` for argument passing
- All launcher arguments documented in help

**Automation:**
```bash
grep -E '(\-h|\-w|\-i|\-t|\-b|\-\-dry-run|\-\-debug|\-\-no-del|\-\-ci)' scripts/glm-aliases.sh
```

**Success Criteria:**
- Documentation mentions all 10 arguments
- `"$@"` used in function calls

---

#### [AI-AUTO] Check 5: Setup Script Validation

**What AI Checks:**
- setup-aliases.sh exists and is executable
- Contains install functions for both zsh and bash
- Has prerequisite checks

**Automation:**
```bash
grep -E "(install_zsh|install_bash|check_prerequisites)" scripts/setup-aliases.sh
```

**Success Criteria:**
- All 3 functions found
- Exit code 0

---

### User-Practical Tests (20-30%) - Выполняет Пользователь

#### [USER-PRACTICAL] Test 1: Установка алиасов

**User Action:**
```bash
cd ~/coding/projects/glm-docker-tools
./scripts/setup-aliases.sh --install
```

**What to Verify:**
1. Setup script detects shell correctly (zsh)
2. Installation completes without errors
3. Success message with instructions shown

**Success Criteria:**
- ✅ Installation successful
- ✅ Message about restarting shell or running exec command
- ✅ No errors about permissions

**User Response:**
Reply "PASS" or "FAIL" with installation output.

---

#### [USER-PRACTICAL] Test 2: Запуск из корня проекта

**User Action:**
```bash
cd ~/coding/projects/glm-docker-tools
# After installation (or: source ~/.local/share/zsh/site-functions/glm)
glm --help
```

**What to Verify:**
1. `glm` command is recognized
2. Help message from glm-launch.sh is displayed
3. No "command not found" errors

**Success Criteria:**
- ✅ `glm` command works
- ✅ Help message displayed
- ✅ No errors

**User Response:**
Reply "PASS" or "FAIL" with command output.

---

#### [USER-PRACTICAL] Test 3: Запуск из поддиректории проекта

**User Action:**
```bash
cd ~/coding/projects/glm-docker-tools/docs
glm-help
```

**What to Verify:**
1. `glm` command works from subdirectory
2. Aliases help is displayed (not glm-launch.sh help)
3. Project root is found automatically

**Success Criteria:**
- ✅ Aliases help displayed
- ✅ No "project root not found" errors
- ✅ Working from subdirectory

**User Response:**
Reply "PASS" or "FAIL" with command output.

---

#### [USER-PRACTICAL] Test 4: Debug режим

**User Action:**
```bash
cd ~/coding/projects/glm-docker-tools
glm-debug --help
```

**What to Verify:**
1. `glm-debug` command is recognized
2. Help shows `--debug` flag is passed
3. Arguments are correctly prepended

**Success Criteria:**
- ✅ `glm-debug` works
- ✅ Debug flag is passed to launcher
- ✅ Help message includes debug info

**User Response:**
Reply "PASS" or "FAIL" with command output.

---

#### [USER-PRACTICAL] Test 5: No-del режим

**User Action:**
```bash
cd ~/coding/projects/glm-docker-tools
glm-no-del --help
```

**What to Verify:**
1. `glm-no-del` command is recognized
2. Help shows `--no-del` flag is passed
3. Arguments are correctly prepended

**Success Criteria:**
- ✅ `glm-no-del` works
- ✅ No-del flag is passed to launcher
- ✅ Help message includes no-del info

**User Response:**
Reply "PASS" or "FAIL" with command output.

---

#### [USER-PRACTICAL] Test 6: Запуск вне проекта (ошибка)

**User Action:**
```bash
cd /tmp
glm
```

**What to Verify:**
1. Clear error message about project not found
2. Helpful fix suggestions
3. No crash or confusing errors

**Expected Output:**
```
❌ GLM: Project root not found

💡 To fix:
   1. Navigate into your project directory
   2. Or use full path: ~/path/to/glm-docker-tools/glm-launch.sh
```

**Success Criteria:**
- ✅ Error message is clear and helpful
- ✅ Fix suggestions are actionable
- ✅ No cryptic errors

**User Response:**
Reply "PASS" or "FAIL" with error output.

---

#### [USER-PRACTICAL] Test 7: Все аргументы работают

**User Action:**
```bash
cd ~/coding/projects/glm-docker-tools
glm -w ~/other/project -i custom:tag --test --dry-run
```

**What to Verify:**
1. All arguments are passed through to glm-launch.sh
2. Dry-run shows correct docker command
3. Workspace and image arguments are applied

**Success Criteria:**
- ✅ All 4 arguments work (-w, -i, --test, --dry-run)
- ✅ Dry-run output shows correct values
- ✅ No argument parsing errors

**User Response:**
Reply "PASS" or "FAIL" with command output.

---

#### [USER-PRACTICAL] Test 8: Универсальный доступ (из другого проекта)

**User Action:**
```bash
cd ~/coding/projects/other-project  # Different project
glm --help
```

**What to Verify:**
1. Aliases work from completely different directory
2. GLM project root is found (searching upward)
3. Help is displayed successfully

**Success Criteria:**
- ✅ Aliases work from unrelated project directory
- ✅ Project root is found correctly
- ✅ No "project not found" errors

**User Response:**
Reply "PASS" or "FAIL" with command output.

---

## Edge Cases

### Edge Case 1: Глубокая вложенность

**Scenario:** Пользователь в `~/coding/projects/company/team/project/`

**Expected Behavior:**
- `_glm_find_project_root()` searches upward through all levels
- Finds `glm-docker-tools` at root level
- Launches successfully

**Test:**
```bash
cd ~/coding/projects/company/team/project
glm --help
```

---

### Edge Case 2: Несколько проектов glm-docker-tools

**Scenario:** У пользователя несколько копий glm-docker-tools в разных местах

**Expected Behavior:**
- Finds the FIRST project root encountered when searching upward
- Works correctly with whichever project is found first

**Test:**
```bash
cd ~/projects/copy1/glm-docker-tools/docs
glm --help  # Finds copy1

cd ~/projects/copy2/glm-docker-tools/tests
glm --help  # Finds copy2
```

---

### Edge Case 3: Нет маркеров проекта

**Scenario:** Директория без `.git`, `glm-launch.sh`, или `Dockerfile`

**Expected Behavior:**
- Clear error message
- Suggests using full path to glm-launch.sh
- No crashes

**Test:**
```bash
cd /tmp/empty_folder
glm
```

---

### Edge Case 4: Аргументы с пробелами

**Scenario:** Путь к workspace содержит пробелы

**Expected Behavior:**
- Arguments with spaces are correctly quoted
- Workspace path is properly passed through

**Test:**
```bash
glm -w "~/My Projects/my-project" --test
```

---

## Troubleshooting

### Issue: "command not found: glm"

**Cause:** Aliases not loaded after installation

**Fix:**
```bash
# Zsh
exec zsh

# Bash
exec bash

# Or source directly
source ~/.local/share/bash-completion/completions/glm
```

---

### Issue: "Project root not found" (inside project)

**Cause:** Git not initialized or markers missing

**Fix:**
```bash
# Initialize git if needed
cd ~/coding/projects/glm-docker-tools
git init

# Or use full path
~/coding/projects/glm-docker-tools/glm-launch.sh
```

---

### Issue: Setup script permission denied

**Cause:** No write access to FPATH directory

**Fix:**
```bash
# Option 1: Use sudo
sudo ./scripts/setup-aliases.sh --install

# Option 2: Install to user directory instead
# Edit setup-aliases.sh to use ~/.local/share/zsh/functions
```

---

## Definition of Done

### Code Quality
- [ ] POSIX-compliant syntax
- [ ] No bashisms (works in bash and zsh)
- [ ] Error handling implemented
- [ ] Logging added for debugging

### Testing - AI-Automated
- [ ] All 5 AI-AUTO checks PASSED
- [ ] Syntax validation PASSED (bash + zsh)
- [ ] Function structure validated
- [ ] Argument passing verified

### Testing - User-Practical
- [ ] Installation successful
- [ ] All 8 USER-PRACTICAL tests PASSED
- [ ] Edge cases tested
- [ ] Works in both bash and zsh

### Documentation
- [ ] UAT test plan created
- [ ] README.md updated with alias instructions
- [ ] SCRIPT_LOGIC.md updated with P13 logic
- [ ] Help messages are clear

### Version Control
- [ ] Changes committed with descriptive message
- [ | Commit includes UAT results summary
- [ | Pushed to remote repository

### User Acceptance
- [ ] User explicitly states: "P13 UAT PASSED"
- [ ] All functionality works as expected

---

## Execution Log

| Date | Test | Result | Notes |
|------|------|--------|-------|
| 2026-01-16 | Plan created | ✅ | Ready for execution |
| | | | |
| | | | |

---

**Status**: ✅ Ready for AI-Automated Checks + User-Practical Tests
**Next Step**: Execute AI-Automated checks (Phase 1 of UAT)

**Expert Panel**: 13/13 unanimous approval
**Confidence Level**: 95%+
**Estimated Time**: 30-45 min (AI-auto) + 10-15 min (User-practical)
