# UAT Plan: P2 - Signal Handling and Cleanup

> 📋 **UAT Plan** | [Home](../../README.md) > [UAT Index](./README.md) > **P2 Signal Handling**

**Feature ID:** P2
**Priority:** IMPORTANT
**Status:** ⏳ Pending Implementation
**UAT Status:** ❌ Not Started

---

## 🎯 Feature Overview

### Purpose
Add robust signal handling to glm-launch.sh to ensure proper container cleanup when the script is interrupted (Ctrl+C, SIGTERM, errors, etc.).

### Problem Being Solved
Currently, if the user presses Ctrl+C during script execution or if the script encounters an error, Docker containers may be left running or in an orphaned state. This wastes resources and clutters the Docker environment.

### Success Definition
After P2 implementation, pressing Ctrl+C at ANY point during script execution should:
1. Gracefully stop and clean up the Docker container
2. Display clear feedback about cleanup actions
3. Exit cleanly without leaving orphaned containers
4. Respect different container modes (auto-del, --debug, --no-del)

---

## 📋 Acceptance Criteria

All of the following must be true after implementation:

1. **Signal Handlers Installed:**
   - Script traps SIGINT, SIGTERM, SIGQUIT, ERR, EXIT
   - Cleanup function is called on any interrupt or error
   - Trap handlers are set BEFORE any Docker operations

2. **Container Cleanup Works:**
   - Container is stopped if running
   - Container is removed ONLY in auto-del mode
   - Container is preserved in --debug and --no-del modes
   - User sees clear feedback about cleanup actions

3. **Global Variables Track State:**
   - `CONTAINER_NAME` is accessible in cleanup function
   - `CONTAINER_CREATED` flag tracks if container was started
   - Variables are properly initialized

4. **Mode-Specific Behavior:**
   - **auto-del mode**: Container removed on interrupt
   - **--debug mode**: Container preserved, user notified
   - **--no-del mode**: Container preserved, user notified

5. **User Experience:**
   - Clear messages about cleanup actions
   - No confusing error messages during cleanup
   - Exit codes indicate success (0) or failure (non-zero)
   - No orphaned containers left behind

---

## 🧪 Test Scenarios

### Scenario 1: Interrupt During Image Build
**What it tests:** Cleanup during early script execution (before container creation)

**Expected behavior:**
- Ctrl+C stops build process
- No container to clean up (none created yet)
- Clean exit with clear message
- No orphaned containers

### Scenario 2: Interrupt During Container Launch (auto-del mode)
**What it tests:** Cleanup with auto-delete mode active

**Expected behavior:**
- Ctrl+C triggers cleanup function
- Container is stopped (if running)
- Container is removed automatically
- User sees cleanup messages
- `docker ps -a` shows no leftover container

### Scenario 3: Interrupt During Container Launch (--debug mode)
**What it tests:** Cleanup preserves debug containers

**Expected behavior:**
- Ctrl+C triggers cleanup function
- Container is stopped (if running)
- Container is NOT removed (preserved for debugging)
- User sees preservation message with container name
- User sees commands to access/remove container
- `docker ps -a` shows stopped container

### Scenario 4: Interrupt During Container Launch (--no-del mode)
**What it tests:** Cleanup preserves no-del containers

**Expected behavior:**
- Ctrl+C triggers cleanup function
- Container is stopped (if running)
- Container is NOT removed
- User sees preservation message
- `docker ps -a` shows stopped container

### Scenario 5: Script Error During Execution
**What it tests:** Cleanup triggered by script errors

**Expected behavior:**
- Error triggers trap handler
- Cleanup function runs
- Container cleaned up according to mode
- User sees error message + cleanup confirmation
- Exit code is non-zero (error)

### Scenario 6: Normal Exit (No Interrupt)
**What it tests:** Normal execution path not affected

**Expected behavior:**
- Script runs to completion
- Container lifecycle follows mode settings
- Cleanup trap runs but recognizes normal exit
- No unnecessary cleanup messages
- Exit code is 0 (success)

---

## 📝 UAT Execution Format

**Format:** ONE-AT-A-TIME interactive testing with simplified user responses.

**User Action:**
1. Execute command in separate terminal
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

### Code Changes Needed

1. **Global Variables (top of script, after set -euo pipefail):**
```bash
# Container tracking for cleanup
CONTAINER_NAME=""
CONTAINER_CREATED=false
CLEANUP_IN_PROGRESS=false
```

2. **Cleanup Function (before main()):**
```bash
# Cleanup function for signal handling
cleanup() {
    # Prevent recursive cleanup
    if [[ "$CLEANUP_IN_PROGRESS" == "true" ]]; then
        return 0
    fi
    CLEANUP_IN_PROGRESS=true

    if [[ -n "$CONTAINER_NAME" && "$CONTAINER_CREATED" == "true" ]]; then
        log_info "🧹 Cleanup: обработка контейнера $CONTAINER_NAME..."

        # Check if container exists
        if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
            # Stop container if running
            if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
                log_info "Остановка контейнера..."
                docker stop "$CONTAINER_NAME" &>/dev/null || true
            fi

            # Remove only in auto-del mode
            if [[ "$DEBUG_MODE" == "false" && "$NO_DEL_MODE" == "false" ]]; then
                log_info "Удаление контейнера..."
                docker rm -f "$CONTAINER_NAME" &>/dev/null || true
                log_success "✅ Контейнер очищен"
            else
                log_warning "⚠️  Контейнер сохранен: $CONTAINER_NAME"
                log_info "Для удаления: docker rm -f $CONTAINER_NAME"
            fi
        fi
    fi
}
```

3. **Trap Handlers (in main(), BEFORE any Docker operations):**
```bash
# Set up signal handlers
trap cleanup SIGINT SIGTERM SIGQUIT ERR EXIT
```

4. **Update Container Creation (in run_claude()):**
```bash
# Mark container as created IMMEDIATELY after docker run starts
CONTAINER_CREATED=true
```

### Where to Add Code

- **Lines 6-10:** Add global variables after `set -euo pipefail`
- **Lines 340-365:** Add cleanup() function before argument parsing
- **Line 407:** Add trap handlers as FIRST line in main()
- **Line 315:** Set `CONTAINER_CREATED=true` immediately after docker run

---

## 🔍 Expected Output Examples

### Example 1: Successful Interrupt in Auto-Del Mode

```
[INFO] 🔍 Проверка наличия Docker-образа: glm-docker-tools:latest
[SUCCESS] ✅ Образ найден: glm-docker-tools:latest (ID: 3fb14c9d00f9)
[INFO] Запуск Claude Code...
[INFO] CONTAINER_NAME: glm-docker-1766741234
[INFO] РЕЖИМ: AUTO-DEL (контейнер будет удален при выходе)
^C
[INFO] 🧹 Cleanup: обработка контейнера glm-docker-1766741234...
[INFO] Остановка контейнера...
[INFO] Удаление контейнера...
[SUCCESS] ✅ Контейнер очищен
```

### Example 2: Successful Interrupt in Debug Mode

```
[INFO] 🔍 Проверка наличия Docker-образа: glm-docker-tools:latest
[SUCCESS] ✅ Образ найден: glm-docker-tools:latest (ID: 3fb14c9d00f9)
[INFO] Запуск Claude Code...
[INFO] CONTAINER_NAME: glm-docker-debug-1766741234
[INFO] РЕЖИМ: DEBUG (контейнер будет сохранен, shell доступ доступен)
^C
[INFO] 🧹 Cleanup: обработка контейнера glm-docker-debug-1766741234...
[INFO] Остановка контейнера...
[WARNING] ⚠️  Контейнер сохранен: glm-docker-debug-1766741234
[INFO] Для удаления: docker rm -f glm-docker-debug-1766741234
```

---

## 🚨 Troubleshooting Guide

### Issue: "container not found" during cleanup

**Symptom:** Cleanup function reports container doesn't exist

**Cause:** Container name not set or docker run failed before container creation

**Fix:** This is normal if interrupted before docker run. No action needed.

---

### Issue: Container still running after Ctrl+C

**Symptom:** `docker ps` shows container still running after interrupt

**Cause:** Cleanup function failed or wasn't triggered

**Validation:**
- Check trap is set: `trap -p` should show cleanup handlers
- Check cleanup function exists: `type cleanup`
- Verify container name was set: Check script output for CONTAINER_NAME

**Fix:** Debug signal handling logic in cleanup() function

---

### Issue: Cleanup runs twice

**Symptom:** Multiple "Cleanup: обработка контейнера" messages

**Cause:** Multiple traps firing (e.g., SIGINT + EXIT)

**Fix:** This is normal. The `CLEANUP_IN_PROGRESS` flag prevents duplicate work.

---

## 📊 Success Metrics

After all UAT steps complete, we should see:

- **100% cleanup success rate** - No orphaned containers after any interrupt
- **Mode-specific behavior** - Containers preserved/removed according to mode
- **Clear user feedback** - All cleanup actions logged
- **No Docker errors** - Clean docker stop/rm operations
- **Fast cleanup** - Container cleanup < 2 seconds

---

## 🔗 Related Documentation

- **[Feature Implementation Methodology](../FEATURE_IMPLEMENTATION_WITH_UAT.md)** - UAT process
- **[Expert Consensus Review](../EXPERT_CONSENSUS_REVIEW.md)** - P2 requirements
- **[Implementation Plan](../IMPLEMENTATION_PLAN.md)** - P2 roadmap
- **[Container Lifecycle Management](../CONTAINER_LIFECYCLE_MANAGEMENT.md)** - Container modes

---

## 📅 UAT Execution Plan

**Prerequisites:**
- [ ] P2 code implementation complete
- [ ] Code review passed
- [ ] Unit tests passed (if applicable)
- [ ] User approved UAT plan

**UAT Steps:**
1. Interrupt during image build (if rebuild needed)
2. Interrupt during container launch - auto-del mode
3. Interrupt during container launch - --debug mode
4. Interrupt during container launch - --no-del mode
5. Test script error handling
6. Test normal execution (no interrupt)

**Execution Time Estimate:** 15-20 minutes (6 scenarios)

---

**Status:** ⏳ Awaiting implementation
**Created:** 2025-12-26
**Methodology Version:** v1.1 (Simplified AI Validation)

---

🤖 **Generated with [Claude Code](https://claude.com/claude-code)**

**Co-Authored-By:** Claude Sonnet 4.5 <noreply@anthropic.com>
