# CLAUDE.md

> 🏠 [Home](./README.md) > **Project Instructions**

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
□ UAT completed and user approved (MANDATORY for all features)
```

### User Acceptance Testing (UAT) - MANDATORY

**CRITICAL REQUIREMENT:** All features MUST include User Acceptance Testing.

**See:** [Feature Implementation with UAT Methodology](./docs/FEATURE_IMPLEMENTATION_WITH_UAT.md)

**Key Principles:**
- **Test Plan First:** UAT plan created BEFORE coding
- **ONE-AT-A-TIME:** User executes steps sequentially
- **User Validation:** AI never assumes - user confirms
- **Complete Test Pyramid:** Unit → Integration → E2E → UAT

**Definition of Done includes:**
- [ ] UAT test plan created and approved
- [ ] All UAT steps executed by user
- [ ] User provided output for each step
- [ ] AI validated each step
- [ ] User explicitly approved: "UAT PASSED"

**Lesson from P1:** `--dry-run` validates script logic but NEVER launches containers or tests real functionality. Without UAT, features may work in isolation but fail in production.

## 📚 REQUIRED READING

### Essential Documentation (Must Read)
1. **[Feature Implementation with UAT](./docs/FEATURE_IMPLEMENTATION_WITH_UAT.md)** - **MANDATORY** methodology for all features with User Acceptance Testing (CRITICAL - read FIRST!)
2. **[Claude Code settings](https://code.claude.com/docs/en/settings.md)** - Complete configuration reference
3. **[Identity and Access Management](https://code.claude.com/docs/en/iam.md)** - Authentication, authorization, and access controls
4. **[Connect Claude Code to tools via MCP](https://code.claude.com/docs/en/mcp.md)** - Model Context Protocol integration
5. **[Plugins](https://code.claude.com/docs/en/plugins.md)** - Plugin system architecture and usage
6. **[GLM Coding Plan Configuration](./docs/Claude-Code-GLM.md)** - Z.AI API integration and authentication setup (IMPORTANT for current project)
7. **[Docker Authentication Research](./DOCKER_AUTHENTICATION_RESEARCH.md)** - Comprehensive analysis of Claude Code authentication in Docker containers (CRITICAL for container deployment)

### Critical Settings Sections (from local [Claude-Code-settings.md](./docs/Claude-Code-settings.md))
- **Settings files hierarchy** - Understanding precedence (Managed > CLI > Local > Shared > User)
- **Permission settings** - Configuring tool access and security restrictions
- **Sandbox settings** - Filesystem and network isolation for bash commands
- **Settings precedence** - How different configuration levels interact
- **Environment variables** - Available configuration options
- **Tools available to Claude** - Understanding Claude's capabilities and permissions

### Key Documentation Topics (from local [Claude-Code-Docs.md](./docs/Claude-Code-Docs.md))
- **[Set up Claude Code](https://code.claude.com/docs/en/setup.md)** - Installation and authentication
- **[CLI reference](https://code.claude.com/docs/en/cli-reference.md)** - Complete command-line interface reference
- **[Common workflows](https://code.claude.com/docs/en/common-workflows.md)** - Typical usage patterns
- **[Hooks reference](https://code.claude.com/docs/en/hooks.md)** - Custom command execution
- **[Subagents](https://code.claude.com/docs/en/sub-agents.md)** - Creating specialized AI assistants

## Project Overview

This is a documentation repository for Claude Code configuration and setup. The repository contains reference documentation and settings for working with Claude Code effectively.

## Repository Structure

### 📁 Documentation Organization

**Root Documentation:**
- [`README.md`](./README.md) - **🏠 Main Project Hub** - Quick start and navigation center
- [`SECURITY.md`](./SECURITY.md) - **🔐 Critical Security Guidelines** - Mandatory security practices
- [`CLAUDE.md`](./CLAUDE.md) - **📋 Current File** - Project methodology and expert guidance
- [`DOCKER_AUTHENTICATION_RESEARCH.md`](./DOCKER_AUTHENTICATION_RESEARCH.md) - **🔬 Research** - Authentication analysis and findings
- [`PRACTICAL_EXPERIMENTS_PLAN.md`](./PRACTICAL_EXPERIMENTS_PLAN.md) - **🧪 Validation** - Experiment procedures and validation
- [`SESSION_HANDOFF.md`](./SESSION_HANDOFF.md) - **📋 Handoff** - Session status and next steps

**docs/ Directory - Organized Documentation:**
- [`docs/Claude-Code-Docs.md`](./docs/Claude-Code-Docs.md) - **📖 External Docs Index** - Claude Code official documentation
- [`docs/Claude-Code-GLM.md`](./docs/Claude-Code-GLM.md) - **🌐 Z.AI Integration** - GLM API configuration guide
- [`docs/Claude-Code-settings.md`](./docs/Claude-Code-settings.md) - **⚙️ Settings Reference** - Complete configuration reference
- [`docs/USAGE_GUIDE.md`](./docs/USAGE_GUIDE.md) - **📚 Usage Manual** - Daily operations and workflows
- [`docs/EXPERT_ANALYSIS.md`](./docs/EXPERT_ANALYSIS.md) - **🔍 Technical Analysis** - Deep technical insights
- [`docs/system-instruction.md`](./docs/system-instruction.md) - **🤖 AI Instructions** - System prompts and methodologies

**Configuration Files:**
- [`Dockerfile`](./Dockerfile) - **🐳 Container Definition** - Docker image configuration
- [`docker-compose.yml`](./docker-compose.yml) - **📦 Orchestration** - Multi-container setup
- [`claude-launch.sh`](./claude-launch.sh) - **🚀 Launcher Script** - Container deployment script

**scripts/ Directory - Utilities:**
- [`scripts/test-claude.sh`](./scripts/test-claude.sh) - **🧪 Testing** - Claude Code functionality tests
- [`scripts/debug-mapping.sh`](./scripts/debug-mapping.sh) - **🔧 Debugging** - Volume mapping diagnostics
- [`scripts/ai-assistant.zsh`](./scripts/ai-assistant.zsh) - **🤖 AI Assistant** - Automation scripts

**Templates and Examples:**
- [`.claude/settings.template.json`](./.claude/settings.template.json) - **📝 Configuration Template** - Safe settings template
- [`examples/`](./examples/) - **💡 Example Files** - Sample configurations

## Key Configuration

This repository uses custom model configuration with GLM models instead of default Anthropic models:
- Default model: glm-4.6
- Haiku model: glm-4.5-air
- Custom API endpoint: https://api.z.ai/api/anthropic
- Extended thinking enabled by default
- External editor: nano (configured in settings template)

### Container Lifecycle Management

The project supports three container lifecycle modes via the launcher script:

```bash
# Standard mode (auto-delete) - recommended for daily use
./glm-launch.sh

# Debug mode - persistent container with shell access for troubleshooting
./glm-launch.sh --debug

# No-del mode - persistent container for long-term tasks
./glm-launch.sh --no-del
```

**Debug Workflow**:
1. Launch with `./glm-launch.sh --debug`
2. Work in Claude Code normally
3. After exiting Claude, get shell access automatically
4. Investigate issues with `docker exec -it claude-debug bash`
5. Exit shell when finished

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
- `Dockerfile.fixed` - Enhanced container version with additional fixes
- `claude-launch.sh` - Launcher script with proper volume mapping
- `docker-compose.yml` - Container orchestration configuration
- `.claude/settings.json` - Project-specific authentication configuration

**Critical Finding**: Authorization persistence depends on **volume mapping identity** rather than container names or images

**Docker Version Management**:
- Always document differences between Docker variants
- Maintain change logs for container modifications
- Test both versions before deployment

---

## 🔗 Related Documentation

### Essential Reading
- **🔐 [Security Guidelines](./SECURITY.md)** - Mandatory security practices and procedures
- **🏠 [Project Hub](./README.md)** - Quick start guide and complete navigation
- **🔬 [Authentication Research](./DOCKER_AUTHENTICATION_RESEARCH.md)** - Deep analysis of Docker authentication

### Configuration & Setup
- **🌐 [Z.AI API Integration](./docs/Claude-Code-GLM.md)** - GLM API setup and configuration
- **⚙️ [Settings Reference](./docs/Claude-Code-settings.md)** - Complete configuration documentation
- **📝 [Settings Template Guide](./docs/SETTINGS_TEMPLATE_GUIDE.md)** - Ready-to-use configuration with nano editor
- **🔄 [Container Lifecycle Management](./docs/CONTAINER_LIFECYCLE_MANAGEMENT.md)** - **NEW** - Container modes (--debug, --no-del, auto-delete)
- **📝 [Configuration Template](./.claude/settings.template.json)** - Safe settings template

### Advanced Topics
- **🧪 [Feature Implementation with UAT](./docs/FEATURE_IMPLEMENTATION_WITH_UAT.md)** - **NEW** **MANDATORY** - Complete UAT methodology with templates
- **📋 [UAT Plans & Templates](./docs/uat/)** - **NEW** - UAT test plans and execution templates
- **🏆 [Expert Consensus Review](./docs/EXPERT_CONSENSUS_REVIEW.md)** - **NEW** 11-expert panel review with 7 critical improvements
- **📝 [Implementation Plan](./docs/IMPLEMENTATION_PLAN.md)** - **NEW** Detailed roadmap for all improvements
- **🧪 [Experiments Plan](./PRACTICAL_EXPERIMENTS_PLAN.md)** - Validation procedures and testing
- **🔍 [Expert Analysis](./docs/EXPERT_ANALYSIS.md)** - Technical deep-dive and insights
- **📋 [Session Handoff](./SESSION_HANDOFF.md)** - Project status and next steps

### Quick Links
- **[Docker Architecture](./docs/DOCKER_MAPPING_DIAGRAM.md)** - Container architecture diagrams
- **[Usage Guide](./docs/USAGE_GUIDE.md)** - Daily operations and workflows
- **[Testing Scripts](./scripts/)** - Utilities and validation tools

## 📁 Backup and Archive Management

### Backup Policy
- **`.bak` files** - Automatic backups created during major edits
- **Archive directory** - Long-term storage of deprecated documents
- **Version tracking** - Maintain history of significant changes

### Working with Backups
```bash
# List all backup files
find . -name "*.bak" -type f

# Restore from backup (if needed)
cp important.md.bak important.md

# Clean old backups (after validation)
find . -name "*.bak" -mtime +30 -delete
```

## 🚀 Next Steps

### If you're new to the project:
1. **Start with [README.md](./README.md)** for project overview and quick start
2. **Read [SECURITY.md](./SECURITY.md)** - security is mandatory
3. **Review [Z.AI API Integration](./docs/Claude-Code-GLM.md)** for API setup

### If you're setting up the environment:
1. **Use [Configuration Template](./.claude/settings.template.json)** as a starting point
2. **Follow [Docker Setup](./README.md#docker-setup)** instructions
3. **Run [Validation Scripts](./scripts/test-claude.sh)** to verify setup

### If you're troubleshooting:
1. **Check [Authentication Research](./DOCKER_AUTHENTICATION_RESEARCH.md)** for common issues
2. **Use [Debug Tools](./scripts/debug-mapping.sh)** for diagnostics
3. **Review [Usage Guide](./docs/USAGE_GUIDE.md)** for operational procedures

### Archive and Research Access
- **[🎯 Project Review](./docs/PROJECT_REVIEW.md)** - Complete project analysis and findings
- **[🔄 Variable Reset Analysis](./docs/EXPERT_OPINION_VARIABLE_RESET.md)** - Environment variable handling
- **[📊 Multi-Container Analysis](./docs/MULTI_CONTAINER_RISK_ANALYSIS.md)** - Container strategy risks
- **[🗂️ Archive Directory](./archive/)** - Historical documents and deprecated files

---

## Important Notes

- **🔒 Security First**: All credential files are excluded from version control - see [SECURITY.md](./SECURITY.md)
- **📁 Repository Purpose**: This is a reference documentation repository, not active development
- **📖 Official Docs**: All content aligns with [official Claude Code documentation](https://code.claude.com/docs/)
- **🎯 Methodology**: Always follow the **EXPERT METHODOLOGY** section for systematic problem-solving
- **🔄 Session Continuity**: Check [SESSION_HANDOFF.md](./SESSION_HANDOFF.md) for current project status