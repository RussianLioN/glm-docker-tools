# P5: Enhanced Logging - UAT Plan

**Feature ID**: P5
**Feature Name**: Enhanced Logging (Structured Logging & Metrics)
**Priority**: MEDIUM
**Complexity**: Medium
**Estimated Implementation**: ~45 minutes

---

## 📋 Feature Overview

### Problem Statement
Current logging is console-only with no persistence or structure:
- No log files for post-mortem analysis
- No metrics for monitoring and observability
- Difficult to debug issues after they occur
- No production monitoring capabilities

### Solution
Add structured logging and metrics tracking:
- **JSON logging** to `${CLAUDE_HOME}/glm-launch.log` - structured logs with timestamps
- **Metrics tracking** to `${CLAUDE_HOME}/metrics.jsonl` - JSONL format for easy parsing
- **Key events logged**: container start, launch mode, image, exit code, duration

### Affected Files
1. `glm-launch.sh` - add logging functions and integrate with run_claude()

### Success Criteria
- ✅ JSON log file created and populated
- ✅ Metrics file created with valid JSONL format
- ✅ Timestamps in ISO 8601 format (UTC)
- ✅ Key metrics logged (start, mode, image, exit, duration)
- ✅ No impact on console output (existing UX preserved)
- ✅ No errors or performance degradation

---

## 🎯 Acceptance Criteria

### Functional Requirements
1. **JSON Logging Function**: `log_json(level, message)` writes to log file
2. **Metrics Function**: `log_metric(metric, value)` writes to metrics file
3. **Timestamp Format**: ISO 8601 UTC format (YYYY-MM-DDTHH:MM:SSZ)
4. **File Locations**:
   - Logs: `${CLAUDE_HOME}/glm-launch.log`
   - Metrics: `${CLAUDE_HOME}/metrics.jsonl`
5. **Key Metrics Tracked**:
   - `container_start` - container name
   - `launch_mode` - autodel/debug/nodebug
   - `docker_image` - image name
   - `exit_code` - container exit code
   - `duration_seconds` - launch duration
6. **Valid JSON**: All log entries are valid JSON objects
7. **JSONL Format**: Each line in metrics file is valid JSON

### Non-Functional Requirements
1. **Performance**: Logging adds <100ms overhead
2. **Reliability**: Logging failures don't break script execution
3. **Storage**: Log rotation not required (files append-only)
4. **Privacy**: No sensitive data logged (API keys, passwords)
5. **Compatibility**: Works with P1-P4 features

---

## 🧪 UAT Test Scenarios

### Scenario 1: JSON Logging Function
**Objective**: Verify log_json() function creates valid JSON log entries

**Test Steps**:
1. Call `log_json "INFO" "Test message"`
2. Verify log file created at `${CLAUDE_HOME}/glm-launch.log`
3. Verify log entry is valid JSON
4. Verify timestamp, level, and message fields present

**Expected Outcome**:
- Log file exists
- Entry format: `{"timestamp":"2025-12-29T12:00:00Z","level":"INFO","message":"Test message"}`
- Timestamp is valid ISO 8601 UTC
- JSON parses correctly

---

### Scenario 2: Metrics Tracking Function
**Objective**: Verify log_metric() function creates valid JSONL entries

**Test Steps**:
1. Call `log_metric "test_metric" "test_value"`
2. Verify metrics file created at `${CLAUDE_HOME}/metrics.jsonl`
3. Verify entry is valid JSON
4. Verify timestamp, metric, and value fields present

**Expected Outcome**:
- Metrics file exists
- Entry format: `{"timestamp":"2025-12-29T12:00:00Z","metric":"test_metric","value":"test_value"}`
- JSONL format (one JSON per line)
- All lines parse as valid JSON

---

### Scenario 3: Integration with Container Launch
**Objective**: Verify metrics logged during actual container launch

**Test Steps**:
1. Run `./glm-launch.sh --dry-run`
2. Check metrics file for expected entries
3. Verify all key metrics present
4. Verify metric values match launch parameters

**Expected Outcome**:
- `container_start` metric with container name
- `launch_mode` metric shows "autodel"
- `docker_image` metric shows "glm-docker-tools:latest"
- Exit code and duration logged (if applicable)
- All values accurate

---

### Scenario 4: Multiple Launches - Append Behavior
**Objective**: Verify logs append (don't overwrite) on subsequent launches

**Test Steps**:
1. Note current line count: `wc -l ${CLAUDE_HOME}/metrics.jsonl`
2. Run `./glm-launch.sh --dry-run`
3. Note new line count
4. Verify count increased (not reset)

**Expected Outcome**:
- Line count increases with each launch
- Previous entries preserved
- No data loss
- JSONL format maintained

---

### Scenario 5: Error Handling - Permission Issues
**Objective**: Verify graceful handling if log files can't be written

**Test Steps**:
1. Make ${CLAUDE_HOME} read-only: `chmod -w ${CLAUDE_HOME}`
2. Run `./glm-launch.sh --dry-run`
3. Verify script continues (doesn't crash)
4. Restore permissions: `chmod +w ${CLAUDE_HOME}`

**Expected Outcome**:
- Script completes successfully
- Console output still works
- No crashes or exits
- Warning logged (optional)

---

### Scenario 6: JSON Validity - Parse Test
**Objective**: Verify all log entries are valid JSON

**Test Steps**:
1. Run `./glm-launch.sh --dry-run`
2. Parse log file with jq: `cat ${CLAUDE_HOME}/glm-launch.log | jq -s '.'`
3. Parse metrics file with jq: `cat ${CLAUDE_HOME}/metrics.jsonl | jq -s '.'`
4. Verify no parse errors

**Expected Outcome**:
- Both files parse successfully with jq
- No JSON syntax errors
- All entries well-formed
- Array of objects created

---

### Scenario 7: Timestamp Accuracy
**Objective**: Verify timestamps are recent and in correct timezone (UTC)

**Test Steps**:
1. Note current UTC time: `date -u`
2. Run `./glm-launch.sh --dry-run`
3. Check newest log entry timestamp
4. Verify timestamp is within 1 minute of current UTC time

**Expected Outcome**:
- Timestamp in ISO 8601 format
- Timezone is UTC (Z suffix)
- Time matches current UTC (±1 minute)
- Format: YYYY-MM-DDTHH:MM:SSZ

---

### Scenario 8: Integration Test - P1/P2/P3/P4 Preserved
**Objective**: Verify logging doesn't break existing functionality

**Test Steps**:
1. Run `./glm-launch.sh --dry-run`
2. Verify P1 (image detection) works
3. Verify P2 (cleanup) works
4. Verify P3 (unified image name) works
5. Verify P4 (file size helpers) work
6. Verify console output unchanged

**Expected Outcome**:
- All P1-P4 features work
- Console UX identical
- No new errors or warnings
- Performance unchanged (<100ms overhead)

---

## 📊 UAT Execution Steps (ONE-AT-A-TIME Format)

### Step 1: Verify Logging Functions Exist

**Context**: Check that log_json() and log_metric() functions are implemented

**Command**:
```bash
grep -A 8 "log_json()" glm-launch.sh
grep -A 8 "log_metric()" glm-launch.sh
```

**Expected Output**:
```bash
log_json() {
    local level="$1" message="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local log_file="${CLAUDE_HOME}/glm-launch.log"

    echo "{\"timestamp\":\"$timestamp\",\"level\":\"$level\",\"message\":\"$message\"}" >> "$log_file"
}

log_metric() {
    local metric="$1" value="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local metrics_file="${CLAUDE_HOME}/metrics.jsonl"

    echo "{\"timestamp\":\"$timestamp\",\"metric\":\"$metric\",\"value\":\"$value\"}" >> "$metrics_file"
}
```

**Success Criteria**:
- ✅ Both functions exist
- ✅ UTC timestamp generation (`date -u`)
- ✅ ISO 8601 format string
- ✅ JSON structure correct
- ✅ Append to files (`>>`)

**⏳ WAITING FOR USER - Paste output and I'll validate**

---

### Step 2: Test JSON Logging Function

**Context**: Verify log_json() creates valid JSON entries

**Command**:
```bash
# Clear previous logs (optional)
rm -f ~/.claude/glm-launch.log

# Test logging function
source glm-launch.sh && log_json "INFO" "UAT test message"

# Verify log file
cat ~/.claude/glm-launch.log | tail -1 | jq '.'
```

**Expected Output**:
```json
{
  "timestamp": "2025-12-29T12:00:00Z",
  "level": "INFO",
  "message": "UAT test message"
}
```

**Success Criteria**:
- ✅ Log file created
- ✅ Valid JSON output
- ✅ Timestamp in UTC ISO 8601
- ✅ All fields present

**⏳ WAITING FOR USER - Paste output and I'll validate**

---

### Step 3: Test Metrics Tracking Function

**Context**: Verify log_metric() creates valid JSONL entries

**Command**:
```bash
# Clear previous metrics (optional)
rm -f ~/.claude/metrics.jsonl

# Test metrics function
source glm-launch.sh && log_metric "uat_test" "test_value"

# Verify metrics file
cat ~/.claude/metrics.jsonl | tail -1 | jq '.'
```

**Expected Output**:
```json
{
  "timestamp": "2025-12-29T12:00:00Z",
  "metric": "uat_test",
  "value": "test_value"
}
```

**Success Criteria**:
- ✅ Metrics file created
- ✅ Valid JSON output
- ✅ JSONL format (one JSON per line)
- ✅ All fields present

**⏳ WAITING FOR USER - Paste output and I'll validate**

---

### Step 4: Integration Test - Launch with Metrics

**Context**: Verify metrics logged during actual container launch

**Command**:
```bash
# Note line count before
wc -l ~/.claude/metrics.jsonl 2>/dev/null || echo "0"

# Run launcher
./glm-launch.sh --dry-run

# Check new metrics
tail -5 ~/.claude/metrics.jsonl | jq -r '.metric + ": " + .value'
```

**Expected Output**:
```
container_start: glm-docker-XXXXXXXXXX
launch_mode: autodel
docker_image: glm-docker-tools:latest
```

**Success Criteria**:
- ✅ Line count increased
- ✅ Key metrics present
- ✅ Values match launch parameters
- ✅ JSONL format valid

**⏳ WAITING FOR USER - Paste output and I'll validate**

---

### Step 5: Append Behavior Test

**Context**: Verify logs append (don't overwrite) on subsequent launches

**Command**:
```bash
# First launch
./glm-launch.sh --dry-run
LINES1=$(wc -l < ~/.claude/metrics.jsonl)

# Second launch
./glm-launch.sh --dry-run
LINES2=$(wc -l < ~/.claude/metrics.jsonl)

# Compare
echo "Before: $LINES1 lines, After: $LINES2 lines"
echo "Difference: $((LINES2 - LINES1)) lines added"
```

**Expected Output**:
```
Before: 3 lines, After: 6 lines
Difference: 3 lines added
```

**Success Criteria**:
- ✅ Line count increased (not reset)
- ✅ Previous entries preserved
- ✅ Difference equals number of new metrics

**⏳ WAITING FOR USER - Paste output and I'll validate**

---

### Step 6: JSON Validity - Parse All Entries

**Context**: Verify all log entries are valid JSON

**Command**:
```bash
# Parse log file
cat ~/.claude/glm-launch.log 2>/dev/null | jq -s 'length' && echo "✅ All log entries valid JSON"

# Parse metrics file
cat ~/.claude/metrics.jsonl 2>/dev/null | jq -s 'length' && echo "✅ All metrics entries valid JSON"
```

**Expected Output**:
```
5
✅ All log entries valid JSON
6
✅ All metrics entries valid JSON
```

**Success Criteria**:
- ✅ jq successfully parses all entries
- ✅ No JSON syntax errors
- ✅ Entry count matches expectations

**⏳ WAITING FOR USER - Paste output and I'll validate**

---

### Step 7: Timestamp Validation

**Context**: Verify timestamps are recent and in UTC

**Command**:
```bash
# Current UTC time
echo "Current UTC: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Latest metric timestamp
echo "Latest metric: $(cat ~/.claude/metrics.jsonl | tail -1 | jq -r '.timestamp')"

# Verify format
cat ~/.claude/metrics.jsonl | tail -1 | jq -r '.timestamp' | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$' && echo "✅ Valid ISO 8601 UTC format"
```

**Expected Output**:
```
Current UTC: 2025-12-29T12:00:00Z
Latest metric: 2025-12-29T12:00:00Z
✅ Valid ISO 8601 UTC format
```

**Success Criteria**:
- ✅ Timestamp format is ISO 8601
- ✅ Timezone is UTC (Z suffix)
- ✅ Time is recent (within 1 minute)

**⏳ WAITING FOR USER - Paste output and I'll validate**

---

### Step 8: Integration - P1/P2/P3/P4 Compatibility

**Context**: Verify logging doesn't break existing features

**Command**:
```bash
./glm-launch.sh --dry-run 2>&1 | grep -E "Образ найден|РЕЖИМ|glm-docker-tools:latest"
```

**Expected Output**:
```
[SUCCESS] ✅ Образ найден: glm-docker-tools:latest (ID: ...)
[INFO] РЕЖИМ: AUTO-DEL (контейнер будет удален при выходе)
... glm-docker-tools:latest
```

**Success Criteria**:
- ✅ P1 (image detection) working
- ✅ P2 (cleanup mode) working
- ✅ P3 (unified image name) working
- ✅ Console output unchanged
- ✅ No new errors

**⏳ WAITING FOR USER - Paste output and I'll validate**

---

## ✅ Final Acceptance

After all steps pass:
- [ ] All 8 UAT steps completed successfully
- [ ] JSON logging working correctly
- [ ] Metrics tracking working correctly
- [ ] Integration with launch flow working
- [ ] No regressions in P1-P4
- [ ] Valid JSON/JSONL format
- [ ] Timestamps accurate (UTC)

**User must explicitly approve**: "UAT PASSED" or "APPROVED"

---

## 📝 Notes

### Implementation Details
- Logging functions added after helper functions in glm-launch.sh
- UTC timestamps via `date -u +"%Y-%m-%dT%H:%M:%SZ"`
- Append-only files (no rotation implemented)
- Graceful degradation if logging fails (script continues)

### File Locations
- Logs: `~/.claude/glm-launch.log`
- Metrics: `~/.claude/metrics.jsonl`
- Both git-ignored (user-specific data)

### Metrics Logged
| Metric | When | Value |
|--------|------|-------|
| `container_start` | Before docker run | Container name |
| `launch_mode` | Before docker run | autodel/debug/nodebug |
| `docker_image` | Before docker run | Image name |
| `exit_code` | After docker exit | Exit code number |
| `duration_seconds` | After docker exit | Launch duration |

### Known Limitations
- No log rotation (files grow indefinitely)
- No log levels filtering (all logged)
- No remote logging (local files only)
- Acceptable for current use case

---

**🤖 Generated with [Claude Code](https://claude.com/claude-code)**

**Co-Authored-By:** Claude Sonnet 4.5 <noreply@anthropic.com>
