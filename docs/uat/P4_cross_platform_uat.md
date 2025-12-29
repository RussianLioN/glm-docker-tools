# P4: Cross-platform Compatibility - UAT Plan

**Feature ID**: P4
**Feature Name**: Cross-platform Compatibility
**Priority**: MEDIUM
**Complexity**: Low
**Estimated Implementation**: ~30 minutes

---

## 📋 Feature Overview

### Problem Statement
Current code uses macOS-specific `stat` commands (`stat -f%z`, `stat -f%Sm`) that fail on Linux/WSL:
- `stat -f%z` (macOS) → `stat -c%s` (Linux) - file size
- `stat -f%Sm` (macOS) → `stat -c%y` (Linux) - modification time

This breaks functionality on Linux systems.

### Solution
Create platform-aware helper functions that detect OS and use correct commands:
- `get_file_size()` - cross-platform file size
- `get_file_mtime()` - cross-platform modification time

### Affected Files
1. `glm-launch.sh` - 2 usages (lines 202, 204)
2. `scripts/debug-mapping.sh` - 3 usages (lines 30, 31, 38)

### Success Criteria
- ✅ Helper functions work on macOS, Linux, and WSL
- ✅ All existing functionality preserved
- ✅ No errors on any platform
- ✅ File size and mtime displayed correctly on all platforms

---

## 🎯 Acceptance Criteria

### Functional Requirements
1. **Platform Detection**: Correctly identify macOS, Linux, WSL, and other Unix variants
2. **File Size**: Return accurate file size in bytes on all platforms
3. **Modification Time**: Return human-readable modification time on all platforms
4. **Error Handling**: Gracefully handle missing files (return "0" for size, "N/A" for time)
5. **Backwards Compatibility**: Existing behavior unchanged on macOS

### Non-Functional Requirements
1. **Performance**: No noticeable performance degradation
2. **Reliability**: Works across Docker Desktop (macOS), native Linux, WSL
3. **Maintainability**: Clean, documented helper functions
4. **Testability**: Functions can be tested independently

---

## 🧪 UAT Test Scenarios

### Scenario 1: Helper Functions Creation
**Objective**: Verify helper functions are created and work correctly

**Test Steps**:
1. Verify `get_file_size()` function exists in glm-launch.sh
2. Verify `get_file_mtime()` function exists in glm-launch.sh
3. Verify functions use `$OSTYPE` for platform detection
4. Verify functions handle all three platforms: darwin, linux, other

**Expected Outcome**:
- Functions created with proper case statement for `$OSTYPE`
- macOS: uses `stat -f%z` and `stat -f%Sm`
- Linux: uses `stat -c%s` and `stat -c%y`
- Other: uses `find` fallback or `ls -l` parsing

---

### Scenario 2: File Size Detection on Current Platform
**Objective**: Verify file size detection works on the current platform (macOS)

**Test Steps**:
1. Run `./glm-launch.sh --test` (should call test_configuration())
2. Check output for history.jsonl file size
3. Manually verify file size matches: `ls -l ~/.claude/history.jsonl`

**Expected Outcome**:
- File size displayed correctly in bytes
- No errors or warnings
- Output matches actual file size

---

### Scenario 3: Debug Script Compatibility
**Objective**: Verify debug-mapping.sh uses platform-aware functions

**Test Steps**:
1. Run `./scripts/debug-mapping.sh`
2. Check "Checking host Claude directory" section
3. Verify file sizes and modification times displayed
4. Check for any `stat` command errors

**Expected Outcome**:
- All file sizes displayed correctly
- Modification times shown in readable format
- No "command not found" or "illegal option" errors

---

### Scenario 4: Container vs Host Detection
**Objective**: Verify script correctly uses different stat commands in container vs host

**Test Steps**:
1. Check host section of debug-mapping.sh output
2. Check container section (inside docker run) output
3. Verify both show correct file sizes
4. Confirm no cross-contamination (host commands in container, vice versa)

**Expected Outcome**:
- Host section uses platform-appropriate commands
- Container section uses Linux commands (stat -c)
- Both sections display identical file sizes
- No errors in either context

---

### Scenario 5: Error Handling - Missing Files
**Objective**: Verify graceful handling of missing files

**Test Steps**:
1. Temporarily rename ~/.claude/history.jsonl
2. Run `./glm-launch.sh --test`
3. Check error handling and fallback values
4. Restore history.jsonl

**Expected Outcome**:
- No crashes or script exits
- File size shows "0" or appropriate message
- Warning logged about missing file
- Script continues normally

---

### Scenario 6: Platform Detection Verification
**Objective**: Verify correct platform detection

**Test Steps**:
1. Check current `$OSTYPE` value: `echo $OSTYPE`
2. Run glm-launch.sh --test and verify correct stat command used
3. Review helper function logic in code
4. Confirm correct case statement branch executed

**Expected Outcome**:
- `$OSTYPE` correctly identifies current platform
- Appropriate stat command selected
- Code branches as expected
- Log output (if any) shows detected platform

---

## 📊 UAT Execution Steps (ONE-AT-A-TIME Format)

### Step 1: Code Review - Helper Functions

**Context**: Verify helper functions are correctly implemented

**Command**:
```bash
grep -A 10 "get_file_size()" glm-launch.sh
grep -A 10 "get_file_mtime()" glm-launch.sh
```

**Expected Output**:
```bash
get_file_size() {
    local file="$1"
    case "$OSTYPE" in
        darwin*) stat -f%z "$file" 2>/dev/null || echo "0" ;;
        linux*)  stat -c%s "$file" 2>/dev/null || echo "0" ;;
        *)       find "$file" -printf "%s" 2>/dev/null || echo "0" ;;
    esac
}

get_file_mtime() {
    local file="$1"
    case "$OSTYPE" in
        darwin*) stat -f%Sm "$file" 2>/dev/null || echo "N/A" ;;
        linux*)  stat -c%y "$file" 2>/dev/null | cut -d'.' -f1 || echo "N/A" ;;
        *)       ls -l "$file" 2>/dev/null | awk '{print $6, $7, $8}' || echo "N/A" ;;
    esac
}
```

**Success Criteria**:
- ✅ Both functions exist
- ✅ Platform detection via `$OSTYPE`
- ✅ All three cases handled (darwin, linux, fallback)
- ✅ Error handling with `2>/dev/null || echo`

**⏳ WAITING FOR USER - Paste output and I'll validate**

---

### Step 2: Test Configuration - File Size Detection

**Context**: Verify file size detection works on current platform

**Command**:
```bash
./glm-launch.sh --test
```

**Expected Output** (partial):
```
=== Тестирование конфигурации Claude ===
...
[SUCCESS] История чатов найдена (XXXXXX байт)
...
[SUCCESS] ✅ Все тесты пройдены!
```

**Success Criteria**:
- ✅ File size displayed (non-zero number)
- ✅ No stat command errors
- ✅ Test passes successfully

**⏳ WAITING FOR USER - Paste output and I'll validate**

---

### Step 3: Debug Script - Platform Compatibility

**Context**: Verify debug-mapping.sh works with platform-aware functions

**Command**:
```bash
./scripts/debug-mapping.sh 2>&1 | grep -A5 "Checking host Claude directory"
```

**Expected Output**:
```
[INFO] 1. Checking host Claude directory:
Path: /Users/s060874gmail.com/.claude
...
Size: XXXXXX bytes
Modified: YYYY-MM-DD HH:MM:SS
```

**Success Criteria**:
- ✅ File sizes displayed
- ✅ Modification times shown
- ✅ No "illegal option" errors
- ✅ No "command not found" errors

**⏳ WAITING FOR USER - Paste output and I'll validate**

---

### Step 4: Verify Usage Replacement

**Context**: Confirm all old stat usages replaced with helper functions

**Command**:
```bash
# Search for old macOS-specific stat patterns that should be replaced
grep -n "stat -f" glm-launch.sh scripts/debug-mapping.sh 2>/dev/null | grep -v "# macOS:" | head -20
```

**Expected Output**:
```
(empty output or only comments)
```

**Success Criteria**:
- ✅ No direct `stat -f` usage in host code sections
- ✅ All usages replaced with helper functions
- ✅ Container sections (Linux) can still use `stat -c` directly

**⏳ WAITING FOR USER - Paste output and I'll validate**

---

### Step 5: Platform Detection Test

**Context**: Verify correct platform is detected

**Command**:
```bash
echo "Platform: $OSTYPE"
bash -c 'case "$OSTYPE" in darwin*) echo "Detected: macOS";; linux*) echo "Detected: Linux";; *) echo "Detected: Other Unix";; esac'
```

**Expected Output**:
```
Platform: darwin23.0
Detected: macOS
```

**Success Criteria**:
- ✅ `$OSTYPE` shows current platform
- ✅ Detection logic works correctly
- ✅ Appropriate branch selected

**⏳ WAITING FOR USER - Paste output and I'll validate**

---

### Step 6: Integration Test - Full Launch Flow

**Context**: Verify P4 doesn't break existing P1/P2/P3 functionality

**Command**:
```bash
./glm-launch.sh --dry-run
```

**Expected Output**:
```
[INFO] Claude Code Launcher v1.1
[INFO] 🔍 Проверка наличия Docker-образа: glm-docker-tools:latest
[SUCCESS] ✅ Образ найден: glm-docker-tools:latest (ID: ...)
[INFO] Директория готова: /Users/s060874gmail.com/.claude
[INFO] Dry run mode. Команда:
docker run -it --rm --name glm-docker-XXXXXXXXXX ...
```

**Success Criteria**:
- ✅ P1 (image build check) works
- ✅ P2 (cleanup setup) works
- ✅ P3 (unified image name) works
- ✅ P4 (file size checks) work
- ✅ No errors or warnings

**⏳ WAITING FOR USER - Paste output and I'll validate**

---

## ✅ Final Acceptance

After all steps pass:
- [ ] All 6 UAT steps completed successfully
- [ ] Helper functions work on current platform (macOS)
- [ ] No regressions in P1/P2/P3 functionality
- [ ] Code is clean and documented
- [ ] Ready for commit

**User must explicitly approve**: "UAT PASSED" or "APPROVED"

---

## 📝 Notes

### Implementation Details
- Helper functions added early in glm-launch.sh (after logging functions)
- Platform detection via `$OSTYPE` (bash built-in variable)
- Three-way case statement: darwin (macOS), linux (Linux/WSL), fallback (other Unix)
- Error handling preserves existing behavior (return "0" or "N/A" on failure)

### Platform Support Matrix
| Platform | `$OSTYPE` | File Size | Mod Time |
|----------|-----------|-----------|----------|
| macOS | `darwin*` | `stat -f%z` | `stat -f%Sm` |
| Linux | `linux*` | `stat -c%s` | `stat -c%y` |
| WSL | `linux*` | `stat -c%s` | `stat -c%y` |
| Other Unix | other | `find -printf` | `ls -l` parsing |

### Known Limitations
- Date format may differ slightly between platforms (acceptable)
- Fallback commands may not work on very old Unix systems (acceptable)
- Assumes standard GNU/BSD coreutils available (acceptable)

---

**🤖 Generated with [Claude Code](https://claude.com/claude-code)**

**Co-Authored-By:** Claude Sonnet 4.5 <noreply@anthropic.com>
