# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 🎯 EXPERT METHODOLOGY (REQUIRED)

### Core Principle
**Methodology over Memorization:** Guide systematic problem-solving using Claude Code capabilities. Always direct to authoritative sources.

### Documentation Reference
**Official Hub:** 📚 https://code.claude.com/docs/llms.txt

**Usage:**
- Specific commands/settings → Direct to relevant docs section
- Never reproduce documentation → Link to source
- Format: "See [feature] docs: code.claude.com/docs/[path]"

### Operational Methodology

#### Phase 1: CLASSIFICATION & ANALYSIS

**Assess request:**
```
TYPE: □ SETUP □ ARCHITECTURE □ DEVELOPMENT □ MCP_ECOSYSTEM □ OPTIMIZATION □ PLUGIN_SYSTEM
COMPLEXITY: □ SIMPLE (1-2 files, <30min) □ MODERATE (3-5 files, <2hrs) □ COMPLEX (6+ files, architectural)
TARGET: 95%+ confidence
```

**Analysis includes:**
1. Requirement decomposition into verifiable components
2. Constraint identification (limits, permissions, scope)
3. Approach selection (direct / structured / deep reasoning)
4. Risk assessment with mitigations
5. Documentation mapping

**Output:** Classification, approach rationale, official references, confidence %, success criteria

#### Phase 2: IMPLEMENTATION PLANNING

**Stage format:**
```
## Stage [N]: [Action]
Objective: [What/why]
Actions: [Steps with outcomes]
Validation: [How to verify]
Reference: [Doc link]
Edge Cases: [Scenario → Mitigation]
```

**Wait for confirmation between stages.**

#### Phase 3: IMPLEMENTATION DELIVERY

**Structure:**
```
## File/Config: [name]
Purpose: [Why exists]
Pattern: [Methodology used]
Reference: [Doc section]

[Solution]

Integration: Dependencies, side effects, validation
Troubleshooting: Issue → Fix → Doc link
Rollback: [Reversal steps]
```

### Decision Framework

**Trigger Extended Reasoning when:**
- Multiple solution paths with trade-offs
- Architectural decisions affecting system design
- Custom MCP protocol development
- Security-critical implementations
- Complex debugging

**Configuration Strategy:**
- CLAUDE.md: Include persistent context, conventions, MCP scopes. Exclude changing data, secrets
- Settings files: Use hierarchy (Managed > CLI > Local > Shared > User)
- MCP Servers: Check official registry → Evaluate need → Custom if justified

**Complexity Approach:**
| Level | Method | Docs Focus |
|-------|--------|------------|
| SIMPLE | Direct solution | Quick refs |
| MODERATE | Structured plan + checkpoints | Config guides |
| COMPLEX | Extended reasoning → Phased | Architecture + examples |

### Quality Assurance: 95%+ Standard

**All criteria must be met:**
```
□ Verifiable in docs (code.claude.com reference)
□ Approach validated (official examples/practices)
□ Edge cases addressed (≥2 scenarios + mitigations)
□ Rollback plan exists
□ Success measurable (testable outcomes)
□ Constraints respected (permissions, limits)
```

## 📚 REQUIRED READING

### Essential Documentation (Must Read)
1. **[Claude Code settings](https://code.claude.com/docs/en/settings.md)** - Complete configuration reference
2. **[Identity and Access Management](https://code.claude.com/docs/en/iam.md)** - Authentication, authorization, and access controls
3. **[Connect Claude Code to tools via MCP](https://code.claude.com/docs/en/mcp.md)** - Model Context Protocol integration
4. **[Plugins](https://code.claude.com/docs/en/plugins.md)** - Plugin system architecture and usage
5. **[GLM Coding Plan Configuration](./Claude-Code-GLM.md)** - Z.AI API integration and authentication setup (IMPORTANT for current project)
6. **[Docker Authentication Research](./DOCKER_AUTHENTICATION_RESEARCH.md)** - Comprehensive analysis of Claude Code authentication in Docker containers (CRITICAL for container deployment)

### Critical Settings Sections (from local `Claude-Code-settings.md`)
- **Settings files hierarchy** - Understanding precedence (Managed > CLI > Local > Shared > User)
- **Permission settings** - Configuring tool access and security restrictions
- **Sandbox settings** - Filesystem and network isolation for bash commands
- **Settings precedence** - How different configuration levels interact
- **Environment variables** - Available configuration options
- **Tools available to Claude** - Understanding Claude's capabilities and permissions

### Key Documentation Topics (from local `Claude-Code-Docs.md`)
- **[Set up Claude Code](https://code.claude.com/docs/en/setup.md)** - Installation and authentication
- **[CLI reference](https://code.claude.com/docs/en/cli-reference.md)** - Complete command-line interface reference
- **[Common workflows](https://code.claude.com/docs/en/common-workflows.md)** - Typical usage patterns
- **[Hooks reference](https://code.claude.com/docs/en/hooks.md)** - Custom command execution
- **[Subagents](https://code.claude.com/docs/en/sub-agents.md)** - Creating specialized AI assistants

## Project Overview

This is a documentation repository for Claude Code configuration and setup. The repository contains reference documentation and settings for working with Claude Code effectively.

## Repository Structure

- `Claude-Code-Docs.md` - Comprehensive list of Claude Code documentation topics
- `Claude-Code-settings.md` - Detailed settings reference documentation
- `system-instruction.md` - Expert assistant system prompt for Claude Code consultations
- `claude.bak/settings.json` - Backup settings file with custom API configuration

## Key Configuration

This repository uses custom model configuration with GLM models instead of default Anthropic models:
- Default model: glm-4.6
- Haiku model: glm-4.5-air
- Custom API endpoint: https://api.z.ai/api/anthropic
- Extended thinking enabled by default

## Common Tasks

Since this is a documentation repository, common tasks include:

1. **Updating documentation** - Edit the relevant `.md` files with new information
2. **Managing settings** - Update configuration in the backup settings file
3. **Adding references** - Include new documentation links in `Claude-Code-Docs.md`

## Working with this Repository

- No build tools or package managers are used
- Files are primarily Markdown and JSON configuration
- Focus on clear, accurate documentation for Claude Code usage
- Maintain consistency with official Claude Code documentation

## 🔧 Docker Integration Status

**Current Configuration**: Docker container uses unified Claude config directory with proper timezone
- Host: `~/.claude/` (unified history and authentication)
- Container: `/root/.claude` (direct mapping for consistency)
- Timezone: Synchronized (Europe/Moscow)

**Authentication Architecture**: See [DOCKER_AUTHENTICATION_RESEARCH.md](./DOCKER_AUTHENTICATION_RESEARCH.md) for comprehensive authentication analysis including:
- OAuth token persistence mechanisms
- Volume mapping identity requirements
- Container authorization binding
- Multi-container isolation strategies

**Key Components**:
- `Dockerfile` - Custom image with timezone fix
- `claude-launch.sh` - Launcher script with proper volume mapping
- `docker-compose.yml` - Container orchestration configuration
- `.claude/settings.json` - Project-specific authentication configuration

**Critical Finding**: Authorization persistence depends on **volume mapping identity** rather than container names or images

---

## Important Notes

- The `claude.bak/settings.json` contains sensitive API configuration and should be handled carefully
- This is a reference documentation repository, not an active development project
- All content should align with official Claude Code documentation at code.claude.com/docs
- **Always follow the EXPERT METHODOLOGY section for all tasks**
- **Check active TODOs before starting new work** - link above