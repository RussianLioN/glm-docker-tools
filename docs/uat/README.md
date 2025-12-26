# User Acceptance Testing (UAT) Plans

> 📋 **UAT Index** | [Home](../../README.md) > [UAT Methodology](../FEATURE_IMPLEMENTATION_WITH_UAT.md) > **UAT Plans**

This directory contains User Acceptance Testing (UAT) plans for all project features.

---

## 📚 Methodology

**REQUIRED READING:** [Feature Implementation with UAT Methodology](../FEATURE_IMPLEMENTATION_WITH_UAT.md)

**Core Principle:** *"Test Plan First, Code Second, User Validation Always"*

---

## 📁 Directory Structure

```
uat/
├── README.md                           # This file
├── templates/                          # UAT templates
│   ├── uat_step_template.md           # Individual step template
│   ├── uat_plan_template.md           # Complete plan template
│   └── acceptance_criteria_template.md # Acceptance criteria template
├── P1_automatic_build_uat.md          # P1 UAT plan (pending)
├── P2_signal_handling_uat.md          # P2 UAT plan (pending)
└── P3_image_unification_uat.md        # P3 UAT plan (pending)
```

---

## 🎯 Available UAT Plans

### Phase 1 (CRITICAL)

| Feature | Plan | Status | UAT Status |
|---------|------|--------|------------|
| P1: Automatic Docker Image Build | ~~[P1 UAT Plan](./P1_automatic_build_uat.md)~~ | ✅ Complete | ✅ UAT PASSED (2025-12-26) |

### Phase 2 (IMPORTANT)

| Feature | Plan | Status | UAT Status |
|---------|------|--------|------------|
| P2: Signal Handling | [P2 UAT Plan](./P2_signal_handling_uat.md) | ✅ Complete | ✅ UAT PASSED (2025-12-26) |

### Phase 3 (MEDIUM)

| Feature | Plan | Status | UAT Status |
|---------|------|--------|------------|
| P3: Image Name Unification | [P3 UAT Plan](./P3_image_unification_uat.md) | ⏳ Pending | ❌ Not Started |

---

## 🚀 Quick Start - Running UAT

### For Users (Testers)

1. **Read the UAT Methodology:**
   - [Feature Implementation with UAT](../FEATURE_IMPLEMENTATION_WITH_UAT.md)
   - Understand the ONE-AT-A-TIME format
   - Prepare a separate terminal window

2. **Select a UAT Plan:**
   - Choose from available plans above
   - Open the plan document
   - Review prerequisites

3. **Execute UAT Steps:**
   - Follow steps ONE at a time
   - Execute commands in separate terminal
   - Copy FULL output after each step
   - Send output to AI for validation
   - Wait for confirmation before next step

4. **Complete UAT:**
   - All steps must be completed
   - All success criteria must be met
   - Provide explicit approval

### For AI (Claude)

1. **Before Starting UAT:**
   - Ensure code is complete
   - All unit tests passed
   - All integration tests passed
   - UAT plan is prepared

2. **During UAT:**
   - Present ONE step at a time
   - Use template from `templates/uat_step_template.md`
   - Wait for user response
   - Validate output against success criteria
   - Document results

3. **After UAT:**
   - Collect all results
   - Create execution log
   - Update feature status
   - Create commit with UAT results

---

## 📋 Templates

### Creating a New UAT Plan

1. Copy `templates/uat_plan_template.md`
2. Rename to `[Feature_ID]_[feature_name]_uat.md`
3. Fill in all sections:
   - Feature overview
   - Acceptance criteria
   - Test scenarios
   - UAT execution steps
4. Get user approval of plan BEFORE implementation
5. Link from this README

### Creating a UAT Step

1. Copy `templates/uat_step_template.md`
2. Fill in step details:
   - Context and prerequisites
   - Exact command
   - Expected output
   - Success criteria
   - Troubleshooting
3. Use ONE-AT-A-TIME format
4. Include explicit "WAITING FOR USER" marker

---

## 🔍 UAT Execution Logs

Execution logs are stored in `.uat-logs/` (git-ignored):
```
.uat-logs/
├── 2025-12-26_P1_execution.md         # P1 execution log
├── 2025-12-26_P1_results.json         # Structured results
└── README.md                           # Log format
```

**Note:** Logs contain user-specific data and are NOT committed to git.

---

## ✅ UAT Status Legend

| Symbol | Status | Description |
|--------|--------|-------------|
| ✅ | Completed | UAT passed, user approved |
| 🔄 | In Progress | UAT execution ongoing |
| ⏳ | Pending | Waiting to start |
| ❌ | Not Started | UAT plan not created yet |
| 🚫 | Failed | UAT failed, needs fixes |
| ⏸️ | Blocked | Waiting for dependencies |

---

## 🔗 Related Documentation

- **[UAT Methodology](../FEATURE_IMPLEMENTATION_WITH_UAT.md)** - Complete methodology
- **[CLAUDE.md](../../CLAUDE.md)** - Project instructions
- **[IMPLEMENTATION_PLAN.md](../IMPLEMENTATION_PLAN.md)** - Implementation roadmap
- **[EXPERT_CONSENSUS_REVIEW.md](../EXPERT_CONSENSUS_REVIEW.md)** - Improvement list

---

## 📝 Contributing

When creating new UAT plans:
1. Use templates from `templates/`
2. Follow methodology in parent document
3. Get user approval before implementation
4. Update this README with new plan
5. Maintain status table

---

**🤖 Generated with [Claude Code](https://claude.com/claude-code)**

**Co-Authored-By:** Claude Sonnet 4.5 <noreply@anthropic.com>
