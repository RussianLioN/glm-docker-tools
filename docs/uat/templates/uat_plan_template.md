# UAT Test Plan: [Feature Name]

> 📋 **UAT Plan** | [Home](../../../README.md) > [UAT Methodology](../../FEATURE_IMPLEMENTATION_WITH_UAT.md) > **[Feature Name]**

**Feature ID:** [P1, P2, etc.]
**Status:** [Planning / In Progress / Completed]
**Created:** [Date]
**Last Updated:** [Date]

---

## Feature Overview

### User Story
As a [user type], I want [goal] so that [benefit].

### Acceptance Criteria
- [ ] Criterion 1: Specific, measurable outcome
- [ ] Criterion 2: Specific, measurable outcome
- [ ] Criterion 3: Specific, measurable outcome

### Success Metrics
- Metric 1: [How to measure]
- Metric 2: [How to measure]

---

## Test Environment

### Requirements
- **OS:** [macOS / Linux / Windows]
- **Docker:** [version required]
- **Shell:** [bash / zsh / fish]
- **Disk Space:** [minimum required]
- **Network:** [requirements]

### Prerequisites
- [ ] Docker daemon is running
- [ ] Current directory is project root
- [ ] No running containers from previous tests
- [ ] Backup of critical data completed (if applicable)

---

## Test Scenarios

### Scenario 1: [Happy Path - Primary Use Case]

**Objective:** Verify [what this scenario tests]

**Scope:**
- Tests: [what functionality]
- Validates: [what acceptance criteria]

**Steps:**
1. [Setup step]
2. [Action step]
3. [Validation step]

**Expected Result:**
[Detailed description of successful outcome]

**Validation:**
- [ ] Check 1
- [ ] Check 2
- [ ] Check 3

---

### Scenario 2: [Error Handling]

**Objective:** Verify [what error handling is tested]

**Scope:**
- Tests: [error condition]
- Validates: [graceful failure, error messages]

**Steps:**
1. [Setup error condition]
2. [Trigger error]
3. [Verify handling]

**Expected Result:**
[What should happen when error occurs]

**Validation:**
- [ ] Error message is clear and helpful
- [ ] System fails gracefully
- [ ] No data corruption
- [ ] Recovery is possible

---

### Scenario 3: [Edge Case]

**Objective:** Verify [what edge case is tested]

**Scope:**
- Tests: [boundary condition]
- Validates: [behavior at limits]

**Steps:**
1. [Setup edge condition]
2. [Execute action]
3. [Verify behavior]

**Expected Result:**
[What should happen at edge case]

**Validation:**
- [ ] Behavior is consistent
- [ ] No unexpected errors
- [ ] Performance is acceptable

---

## UAT Execution Steps (ONE-AT-A-TIME)

### Step 1: [First Test Step]
[Link to detailed step documentation]

**Quick Summary:**
- Command: `[command]`
- Expected: [brief expected result]
- Validates: [what this proves]

---

### Step 2: [Second Test Step]
[Link to detailed step documentation]

**Quick Summary:**
- Command: `[command]`
- Expected: [brief expected result]
- Validates: [what this proves]

---

### Step 3: [Third Test Step]
[Link to detailed step documentation]

**Quick Summary:**
- Command: `[command]`
- Expected: [brief expected result]
- Validates: [what this proves]

---

## Definition of Done

Feature is complete when ALL items are checked:

### Code
- [ ] Implementation complete
- [ ] Code follows conventions
- [ ] Error handling implemented
- [ ] Logging added

### Testing - Automated
- [ ] Unit tests passing
- [ ] Integration tests passing
- [ ] E2E tests passing

### Testing - UAT
- [ ] All UAT steps executed
- [ ] User provided output for each step
- [ ] All success criteria met
- [ ] Edge cases validated

### Documentation
- [ ] Feature documented
- [ ] README updated
- [ ] CHANGELOG updated

### User Acceptance
- [ ] User explicitly states: "Feature works as expected"
- [ ] User explicitly states: "UAT completed successfully"
- [ ] User explicitly states: "Approved for production"

---

## Rollback Plan

If UAT fails:

### Immediate Actions
1. [First action to take]
2. [Second action to take]

### Recovery Steps
1. [How to restore previous state]
2. [How to clean up failed changes]

### Rollback Command
```bash
[command to revert changes]
```

---

## Results

**UAT Execution Date:** [Date]
**Executed By:** [User]
**Status:** [Passed / Failed / In Progress]

### Test Results Summary
- Scenario 1: [Pass/Fail] - [Notes]
- Scenario 2: [Pass/Fail] - [Notes]
- Scenario 3: [Pass/Fail] - [Notes]

### Issues Found
1. [Issue description] - [Resolution]
2. [Issue description] - [Resolution]

### User Approval
- [ ] User approves feature for production
- **Approval Date:** [Date]
- **Signature:** [User confirmation]

---

**🤖 Generated with [Claude Code](https://claude.com/claude-code)**
