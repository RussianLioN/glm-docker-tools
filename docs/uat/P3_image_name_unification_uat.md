# UAT Plan: P3 - Docker Image Name Unification

> 📋 **UAT Plan** | [Home](../../README.md) > [UAT Index](./README.md) > **P3 Image Name Unification**

**Feature ID:** P3
**Priority:** MEDIUM
**Status:** ⏳ Pending Implementation
**UAT Status:** ❌ Not Started

---

## 🎯 Feature Overview

### Purpose
Унифицировать все упоминания Docker image в проекте к единому стандарту: `glm-docker-tools:latest`

### Problem Being Solved
В проекте используется 5+ различных имен Docker образов:
1. `glm-docker-tools:latest` ✅ (текущий стандарт)
2. `anthropic/claude-code:latest` ❌ (неправильно)
3. `claude-code-docker:latest` ❌ (старое имя)
4. `claude-code-tools:latest` ❌ (опечатка в help)
5. Разные варианты в документации

**Последствия**:
- Путаница при использовании разных скриптов
- Попытки использовать несуществующие образы
- Несогласованная документация
- Ошибки при запуске compose/скриптов

### Success Definition
После P3 реализации:
1. ВСЕ скрипты используют `glm-docker-tools:latest`
2. ВСЕ конфигурационные файлы используют `glm-docker-tools:latest`
3. Документация согласована
4. Скрипты запускаются без ошибок "image not found"

---

## 📋 Acceptance Criteria

Все критерии должны быть выполнены:

1. **Скрипты обновлены:**
   - `glm-launch.sh` - help текст использует `glm-docker-tools:latest`
   - `docker-compose.yml` - image: `glm-docker-tools:latest`
   - `scripts/test-claude.sh` - IMAGE=`glm-docker-tools:latest`
   - `scripts/launch-multiple.sh` - IMAGE=`glm-docker-tools:latest`

2. **Поиск не находит старых имен:**
   ```bash
   grep -r "anthropic/claude-code" . --exclude-dir=.git
   grep -r "claude-code-docker:latest" . --exclude-dir=.git
   grep -r "claude-code-tools:latest" . --exclude-dir=.git
   ```
   Результат: только в CHANGELOG/документации истории (допустимо)

3. **Все скрипты запускаются:**
   - `./glm-launch.sh --help` - показывает правильное имя образа
   - `./glm-launch.sh --dry-run` - использует glm-docker-tools:latest
   - `docker-compose config` - показывает glm-docker-tools:latest

4. **Функциональность не нарушена:**
   - Образ собирается корректно
   - Контейнеры запускаются
   - Все три режима (auto-del, debug, no-del) работают

---

## 🧪 Test Scenarios

### Scenario 1: Verify Help Text Consistency
**What it tests:** glm-launch.sh help messages use correct image name

**Expected behavior:**
- Help text shows `glm-docker-tools:latest` (not claude-code-tools)
- Environment variable description shows `glm-docker-tools:latest`
- Examples show `glm-docker-tools:latest`

### Scenario 2: Docker Compose Uses Correct Image
**What it tests:** docker-compose.yml references correct image

**Expected behavior:**
- `docker-compose config` shows `glm-docker-tools:latest`
- No references to `anthropic/claude-code:latest`
- Compose can start services with unified image

### Scenario 3: All Scripts Use Unified Name
**What it tests:** All test/utility scripts use glm-docker-tools:latest

**Expected behavior:**
- `test-claude.sh` uses `glm-docker-tools:latest`
- `launch-multiple.sh` uses `glm-docker-tools:latest`
- Scripts don't fail with "image not found"

### Scenario 4: Search Verification
**What it tests:** No old image names remain in active code

**Expected behavior:**
- grep for old names finds only documentation/changelog references
- No active scripts use old names
- README examples use correct name

### Scenario 5: Functional Test - Image Build
**What it tests:** Image builds and tags correctly

**Expected behavior:**
- `docker build -t glm-docker-tools:latest .` succeeds
- `docker images | grep glm-docker-tools` shows the image
- Tag is exactly `glm-docker-tools:latest`

### Scenario 6: Functional Test - Container Launch
**What it tests:** Containers launch with unified image name

**Expected behavior:**
- `./glm-launch.sh` uses `glm-docker-tools:latest`
- Container starts successfully
- All P1 & P2 functionality works (auto-build, cleanup)

---

## 📝 UAT Execution Format

**Format:** ONE-AT-A-TIME interactive testing with simplified user responses.

**User Action:**
1. Execute command
2. Copy FULL terminal output
3. Paste output in response
4. (Optional) Mention any questions or issues

**AI Action:**
1. Validate output against success criteria automatically
2. Confirm pass/fail
3. Provide next step OR troubleshooting

**NO manual checklists** - AI performs all validation from the provided output.

---

## 🔧 Implementation Requirements

### Files to Update

**1. glm-launch.sh (2 locations)**
- Line 54: Help text `-i, --image` description
- Line 64: Environment variable `CLAUDE_IMAGE` description

**Before:**
```bash
-i, --image IMAGE  Указать Docker образ (по умолчанию: claude-code-tools:latest)
CLAUDE_IMAGE       Docker образ (по умолчанию: claude-code-tools:latest)
```

**After:**
```bash
-i, --image IMAGE  Указать Docker образ (по умолчанию: glm-docker-tools:latest)
CLAUDE_IMAGE       Docker образ (по умолчанию: glm-docker-tools:latest)
```

**2. docker-compose.yml (line 8)**

**Before:**
```yaml
image: ${CLAUDE_IMAGE:-anthropic/claude-code:latest}
```

**After:**
```yaml
image: ${CLAUDE_IMAGE:-glm-docker-tools:latest}
```

**3. scripts/test-claude.sh (line 21)**

**Before:**
```bash
IMAGE="${CLAUDE_IMAGE:-anthropic/claude-code:latest}"
```

**After:**
```bash
IMAGE="${CLAUDE_IMAGE:-glm-docker-tools:latest}"
```

**4. scripts/launch-multiple.sh (line 29)**

**Before:**
```bash
IMAGE="${CLAUDE_IMAGE:-claude-code-docker:latest}"
```

**After:**
```bash
IMAGE="${CLAUDE_IMAGE:-glm-docker-tools:latest}"
```

---

## 🔍 Expected Output Examples

### Example 1: Help Text After Fix

```bash
$ ./glm-launch.sh --help

Использование:
    ./glm-launch.sh [OPTIONS] [CLAUDE_ARGS...]

Опции:
    -i, --image IMAGE  Указать Docker образ (по умолчанию: glm-docker-tools:latest)

Переменные окружения:
    CLAUDE_IMAGE       Docker образ (по умолчанию: glm-docker-tools:latest)
```

### Example 2: Docker Compose Config

```bash
$ docker-compose config

services:
  claude-code:
    image: glm-docker-tools:latest
    container_name: claude-code
```

### Example 3: Grep Verification (No Old Names)

```bash
$ grep -r "claude-code-tools:latest" . --exclude-dir=.git --exclude-dir=.uat-logs

# Expected: NO matches in active code
# Only acceptable: matches in CHANGELOG or historical docs
```

---

## 🚨 Troubleshooting Guide

### Issue: "image not found" after changes

**Symptom:** Docker can't find glm-docker-tools:latest

**Cause:** Image not built yet

**Fix:**
```bash
docker build -t glm-docker-tools:latest .
```

**Validation:** `docker images | grep glm-docker-tools`

---

### Issue: docker-compose fails

**Symptom:** `docker-compose up` fails with image error

**Cause:** Compose trying to pull non-existent image

**Fix:** Ensure image is built locally OR set CLAUDE_IMAGE env var

**Validation:**
```bash
docker-compose config  # Should show glm-docker-tools:latest
```

---

### Issue: Old references still found

**Symptom:** grep finds old image names

**Cause:** Not all files updated

**Fix:** Check output carefully - determine if matches are:
- Active code (MUST fix)
- Documentation/CHANGELOG (acceptable if historical)
- Comments explaining old behavior (acceptable)

---

## 📊 Success Metrics

After all UAT steps complete:

- **Files updated**: 4 (glm-launch.sh, docker-compose.yml, 2 scripts)
- **Grep matches**: 0 in active code (only docs/changelog acceptable)
- **Image build success**: 100%
- **Container launch success**: 100%
- **Functionality preserved**: All P1/P2 features work
- **Documentation consistency**: 100%

---

## 🔗 Related Documentation

- **[Expert Consensus Review](../EXPERT_CONSENSUS_REVIEW.md)** - P3 requirements (lines 180-186)
- **[Implementation Plan](../IMPLEMENTATION_PLAN.md)** - P3 roadmap (lines 251-324)
- **[Feature Implementation Methodology](../FEATURE_IMPLEMENTATION_WITH_UAT.md)** - UAT process

---

## 📅 UAT Execution Plan

**Prerequisites:**
- [ ] P3 code changes implemented
- [ ] All 4 files updated
- [ ] User approved UAT plan

**UAT Steps:**
1. Verify help text shows correct image name
2. Verify docker-compose config
3. Verify test scripts use correct image
4. Search verification (grep for old names)
5. Functional test: image build
6. Functional test: container launch with all modes

**Execution Time Estimate:** 10-15 minutes (6 scenarios)

---

## 💡 Design Notes

**Why unify to `glm-docker-tools:latest`?**
1. Already used in main launcher (glm-launch.sh:38)
2. Descriptive name (GLM Docker Tools)
3. Distinguishes from official Anthropic image
4. Consistent with repository name

**What NOT to change:**
- Container names (glm-docker-{timestamp}) - these are runtime, not image names
- Documentation explaining historical context
- CHANGELOG entries
- Comments explaining old behavior

**Backwards Compatibility:**
- CLAUDE_IMAGE env var still allows override
- Users can specify custom image with `-i` flag
- Change is primarily in defaults, not functionality

---

**Status:** ⏳ Awaiting implementation
**Created:** 2025-12-26
**Methodology Version:** v1.1 (Simplified AI Validation)

---

🤖 **Generated with [Claude Code](https://claude.com/claude-code)**

**Co-Authored-By:** Claude Sonnet 4.5 <noreply@anthropic.com>
