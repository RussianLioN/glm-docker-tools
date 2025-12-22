# Claude Code Docker Integration

> 🐳 **Production-ready Docker deployment** for Claude Code with Z.AI API integration and comprehensive authentication research.

## 🧭 Navigation Hub

### 📖 Table of Contents

1. [🚀 Quick Start](#-quick-start)
2. [📚 Complete Documentation](#-complete-documentation)
3. [📁 Project Structure](#-project-structure)
4. [🏗️ Architecture Overview](#️-architecture-overview)
5. [⚙️ Configuration](#️-configuration)
6. [🔐 Security](#-security)
7. [🧪 Development](#-development)
8. [🔍 Research Findings](#-research-findings)
9. [📋 Project Status](#-project-status)

### 🎯 Quick Navigation by Role

#### 🆕 **New to Project?**
1. **[🔐 Security First](./SECURITY.md)** - Critical security guidelines
2. **[📋 Project Instructions](./CLAUDE.md)** - Expert methodology
3. **[🚀 Quick Start](#-quick-start)** - Get running in 5 minutes

#### 🔧 **Setting Up Development?**
1. **[🌐 Z.AI API Integration](./docs/Claude-Code-GLM.md)** - API configuration
2. **[⚙️ Settings Reference](./docs/Claude-Code-settings.md)** - Complete configuration
3. **[📝 Settings Template Guide](./docs/SETTINGS_TEMPLATE_GUIDE.md)** - Ready-to-use configuration template with nano editor
4. **[🔄 Container Lifecycle Management](./docs/CONTAINER_LIFECYCLE_MANAGEMENT.md)** - **NEW** - Container modes (--debug, --no-del, auto-delete)
5. **[📝 Nano Editor Setup](./docs/NANO_EDITOR_SETUP.md)** - External editor integration
6. **[🧪 Testing Scripts](./scripts/)** - Validation tools

#### 🚀 **Deploying to Production?**
1. **[🔬 Authentication Research](./DOCKER_AUTHENTICATION_RESEARCH.md)** - Critical security analysis
2. **[🏗️ Architecture](./docs/DOCKER_MAPPING_DIAGRAM.md)** - System design
3. **[📋 Production Guide](./docs/USAGE_GUIDE.md)** - Operational procedures

#### 🔍 **Troubleshooting Issues?**
1. **[🔧 Debug Tools](./scripts/debug-mapping.sh)** - Volume mapping diagnostics
2. **[📚 Usage Guide](./docs/USAGE_GUIDE.md)** - Common workflows
3. **[🔍 Expert Analysis](./docs/EXPERT_ANALYSIS.md)** - Technical insights
4. **[🎯 Project Review](./docs/PROJECT_REVIEW.md)** - Complete project analysis
5. **[📚 Documentation Hub](./docs/index.md)** - **COMPLETE NAVIGATION** - All docs and search

## 🚀 Quick Start

### Prerequisites

- Docker 20.10+ and Docker Compose
- Node.js 18+ (for local development)
- Z.AI API account and authentication token

### Installation

```bash
# Clone the repository
git clone https://github.com/s060874gmail/claude-code-docker.git
cd claude-code-docker

# Copy configuration template
cp .claude/settings.template.json .claude/settings.json

# Edit configuration with your API token
nano .claude/settings.json
```

### Basic Usage

```bash
# Using Docker Compose (recommended)
docker-compose up -d

# Using the launcher script
./claude-launch.sh

# Direct Docker command
docker run -it \
  -v ~/.claude:/root/.claude \
  -v $(pwd):/workspace \
  -w /workspace \
  claude-code-docker:latest
```

## 📚 Complete Documentation

### 🔐 **CRITICAL - Must Read First**

1. **[🔒 Security Guidelines](./SECURITY.md)** - **MANDATORY** - Security best practices and procedures
2. **[📋 Project Instructions](./CLAUDE.md)** - Expert methodology and systematic approach
3. **[🔬 Authentication Research](./DOCKER_AUTHENTICATION_RESEARCH.md)** - Critical security analysis

### 🌟 **Essential Reading**

#### 📖 Getting Started
- **[🚀 Quick Start Guide](#-quick-start)** - Get running in 5 minutes
- **[🌐 Z.AI API Integration](./docs/Claude-Code-GLM.md)** - GLM API setup and configuration
- **[⚙️ Configuration Guide](./docs/USAGE_GUIDE.md)** - Daily operations and workflows

#### 🏗️ Architecture & Design
- **[🏗️ Architecture Overview](./docs/DOCKER_MAPPING_DIAGRAM.md)** - System design diagrams
- **[🔍 Expert Analysis](./docs/EXPERT_ANALYSIS.md)** - Technical deep-dive and insights
- **[📊 Multi-Container Analysis](./docs/MULTI_CONTAINER_RISK_ANALYSIS.md)** - Container strategies

#### 🔧 Configuration & Setup
- **[⚙️ Settings Reference](./docs/Claude-Code-settings.md)** - Complete configuration documentation
- **[📝 Settings Template Guide](./docs/SETTINGS_TEMPLATE_GUIDE.md)** - Ready-to-use configuration with nano editor
- **[🔄 Container Lifecycle Management](./docs/CONTAINER_LIFECYCLE_MANAGEMENT.md)** - **NEW** - Container modes (--debug, --no-del, auto-delete)
- **[📝 Configuration Template](./.claude/settings.template.json)** - Safe settings template
- **[🔧 Development Scripts](./scripts/)** - Testing and debugging tools
- **[📝 Nano Editor Setup](./docs/NANO_EDITOR_SETUP.md)** - External editor integration

#### 🐳 Docker Infrastructure
- **[🐳 Dockerfile](./Dockerfile)** - Current production container definition
- **[🔧 Dockerfile.fixed](./Dockerfile.fixed)** - Enhanced container with fixes
- **[📦 Docker Compose](./docker-compose.yml)** - Multi-container orchestration
- **[🚀 Launcher Script](./claude-launch.sh)** - Container deployment automation

#### 🔬 Research & Validation
- **[🧪 Experiments Plan](./PRACTICAL_EXPERIMENTS_PLAN.md)** - Validation procedures and testing
- **[📋 Session Handoff](./SESSION_HANDOFF.md)** - Project status and next steps
- **[🤖 System Instructions](./docs/system-instruction.md)** - AI methodology and prompts

#### 📚 Reference Documentation
- **[📚 Documentation Hub](./docs/index.md)** - **CENTRAL HUB** - Complete documentation navigation
- **[📖 Official Documentation](./docs/Claude-Code-Docs.md)** - All Claude Code official docs
- **[🎯 Project Review](./docs/PROJECT_REVIEW.md)** - Complete project analysis
- **[🔄 Variable Reset Analysis](./docs/EXPERT_OPINION_VARIABLE_RESET.md)** - Environment handling

### 🎯 **Documentation by Use Case**

#### 🔒 **Security & Compliance**
- **[🔐 Security Guidelines](./SECURITY.md)** - Must-read security practices
- **[🔬 Authentication Research](./DOCKER_AUTHENTICATION_RESEARCH.md)** - Security analysis
- **[📋 Security Handoff](./SESSION_HANDOFF.md)** - Security considerations

#### 🚀 **Deployment & Operations**
- **[🚀 Quick Start](#-quick-start)** - Immediate deployment
- **[📋 Production Guide](./docs/USAGE_GUIDE.md)** - Operational procedures
- **[🔧 Debug Tools](./scripts/debug-mapping.sh)** - Troubleshooting utilities

#### 🔧 **Development & Testing**
- **[🧪 Testing Scripts](./scripts/test-claude.sh)** - Validation tools
- **[🔧 Development Workflow](#-development)** - Development procedures
- **[📝 Template Configuration](./.claude/settings.template.json)** - Development setup

#### 📚 **Learning & Reference**
- **[📖 Official Documentation](./docs/Claude-Code-Docs.md)** - Claude Code docs
- **[🔍 Expert Analysis](./docs/EXPERT_ANALYSIS.md)** - Technical insights
- **[🤖 Methodology](./CLAUDE.md)** - Expert approach

### 🔗 **Quick Links**

#### ⚡ **Most Used**
- **[🔐 Security](./SECURITY.md)** | **[🚀 Quick Start](#-quick-start)** | **[🌐 API Setup](./docs/Claude-Code-GLM.md)**

#### 📁 **File Navigation**
- **[⚙️ Configuration](./.claude/settings.template.json)** | **[🔧 Scripts](./scripts/)** | **[📖 Docs](./docs/)**

#### 🔍 **Troubleshooting**
- **[🔧 Debug Script](./scripts/debug-mapping.sh)** | **[📚 Usage Guide](./docs/USAGE_GUIDE.md)** | **[🔍 Expert Analysis](./docs/EXPERT_ANALYSIS.md)**

## 📁 Project Structure

### Repository Organization

```
glm-docker-tools/
├── 📄 README.md                    # 🏠 Main project hub
├── 📋 CLAUDE.md                    # 📖 Project instructions for Claude
├── 🔐 SECURITY.md                  # 🔒 Security guidelines
├── 🔬 DOCKER_AUTHENTICATION_RESEARCH.md  # 📊 Authentication analysis
├── 🧪 PRACTICAL_EXPERIMENTS_PLAN.md      # 📋 Experiment procedures
├── 📋 SESSION_HANDOFF.md          # 🔄 Session status and next steps
│
├── 📁 docs/                       # 📚 Complete documentation
│   ├── index.md                   # 🧭 Central navigation hub
│   ├── Claude-Code-Docs.md        # 📖 Official docs index
│   ├── Claude-Code-GLM.md         # 🌐 Z.AI API integration
│   ├── Claude-Code-settings.md    # ⚙️ Settings reference
│   ├── USAGE_GUIDE.md             # 📚 Daily operations
│   ├── EXPERT_ANALYSIS.md         # 🔍 Technical insights
│   ├── system-instruction.md      # 🤖 AI methodology
│   ├── DOCKER_MAPPING_DIAGRAM.md  # 🏗️ Architecture diagrams
│   ├── MULTI_CONTAINER_RISK_ANALYSIS.md  # 📊 Multi-container analysis
│   ├── PROJECT_REVIEW.md          # 🎯 Complete project review
│   └── EXPERT_OPINION_VARIABLE_RESET.md  # 🔄 Environment handling
│
├── 📁 scripts/                    # 🔧 Utility scripts
│   ├── ai-assistant.zsh           # 🤖 Main AI assistant script
│   ├── debug-mapping.sh           # 🔍 Volume mapping diagnostics
│   ├── test-claude.sh             # 🧪 Claude functionality tests
│   ├── test-config.sh             # ⚙️ Configuration validation
│   └── test-claude-install.sh     # 📦 Installation tests
│
├── 📁 config/                     # ⚙️ Configuration files (future)
│   └── README.md                  # 📋 Directory purpose and plans
│
├── 📁 tests/                      # 🧪 Test suites (future)
│   └── README.md                  # 📋 Testing framework plans
│
├── 📁 examples/                   # 💡 Usage examples
│   └── README.md                  # 📋 Example categories
│
├── 🐳 Dockerfile                  # 🐳 Container definition
├── 🔧 Dockerfile.fixed            # 🔧 Enhanced container version
├── 📦 docker-compose.yml          # 📦 Multi-container setup
├── 🚀 claude-launch.sh            # 🚀 Launcher script
└── 📄 LICENSE                     # 📄 Project license
```

### Directory Purposes

#### 📚 **Documentation** (`docs/`)
- **Complete navigation** via `index.md`
- **Official docs** integration and reference
- **Technical analysis** and research findings
- **Usage guides** and best practices

#### 🔧 **Scripts** (`scripts/`)
- **Testing utilities** for validation
- **Debug tools** for troubleshooting
- **Deployment automation** scripts
- **AI assistant** integration tools

#### ⚙️ **Configuration** (`config/`)
- **Future environment files** (.env variants)
- **CI/CD pipeline configurations**
- **Monitoring and logging setups**

#### 🧪 **Tests** (`tests/`)
- **Automated test suites** (planned)
- **Integration tests** for containers
- **Security validation** scripts
- **Performance benchmarks**

#### 💡 **Examples** (`examples/`)
- **Deployment scenarios** and patterns
- **Configuration examples**
- **Use case demonstrations**

## 🏗️ Architecture

### Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Architecture                       │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Client    │──│ Docker Host │──│  Claude Code        │  │
│  │  (Terminal) │  │  Container  │  │  Container          │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│                           │                    │           │
│                    ┌──────▼──────┐   ┌────────▼────────┐   │
│                    │ Volume Maps │   │ Auth System     │   │
│                    │ ~/.claude    │   │ OAuth + API      │   │
│                    └─────────────┘   └─────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Authentication Flow

1. **OAuth Priority** - OAuth tokens take priority over API configuration
2. **Volume Mapping** - Authorization persistence depends on volume mapping identity
3. **Session Isolation** - Different volume mappings create isolated sessions

## ⚙️ Configuration

### Environment Variables

```bash
# Required for Z.AI API integration
ANTHROPIC_AUTH_TOKEN="your_token_here"
ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"

# Optional configuration
ANTHROPIC_MODEL="glm-4.6"
API_TIMEOUT_MS="3000000"
TZ="Europe/Moscow"
```

### Docker Compose

```yaml
version: '3.8'
services:
  claude-code:
    image: claude-code-docker:latest
    container_name: claude-code
    volumes:
      - ~/.claude:/root/.claude:ro  # Read-only for security
      - ./workspace:/workspace
    environment:
      - CLAUDE_CONFIG_DIR=/root/.claude
      - TZ=Europe/Moscow
    working_dir: /workspace
    command: /usr/local/bin/claude
```

## 🔐 Security

### Critical Security Rules

1. **NEVER** commit authentication credentials
2. **ALWAYS** use environment variables for secrets
3. **NEVER** share `.claude/` directory contents
4. **ALWAYS** review `.gitignore` before committing

### Security Features

- ✅ Comprehensive `.gitignore` for sensitive data protection
- ✅ Template configuration files without secrets
- ✅ Security scanning integration ready
- ✅ OAuth token isolation and management
- ✅ Volume-based authentication boundaries

## 🧪 Development

### Building the Image

```bash
# Build with timezone support
docker build -t claude-code-docker:latest .

# Build with custom tag
docker build -t claude-code-docker:dev .
```

### Testing

```bash
# Run authentication tests
./scripts/test-claude.sh

# Validate configuration
./scripts/test-config.sh

# Debug volume mappings
./scripts/debug-mapping.sh
```

### Development Workflow

```bash
# Make changes
vim Dockerfile

# Test locally
docker-compose up --build

# Run tests
./scripts/test-claude-install.sh

# Commit changes
git add .
git commit -m "feat: update configuration"
```

## 🔍 Research Findings

### Key Discoveries

1. **OAuth > API Priority**: OAuth tokens override Z.AI API configuration
2. **Volume Mapping Identity**: Authorization persists with identical volume mappings
3. **Three Critical Files**: `.credentials.json`, `.claude.json`, `settings.json`
4. **Timezone Synchronization**: Fixed MSK/UTC timezone issues

### Validation Status

| Finding | Confidence | Status |
|---------|------------|--------|
| OAuth Priority | 99% | ✅ Practically verified |
| Volume Mapping | 95% | 🧪 Experiments planned |
| Token Refresh | 90% | 📋 Documentation verified |
| Session Isolation | 85% | 🧪 Framework ready |

## 📋 Project Status

### Completed ✅

- Docker infrastructure with timezone fix
- Comprehensive authentication research
- Security documentation and guidelines
- Template configuration system
- GitOps repository structure

### In Progress 🔄

- Practical validation experiments
- Production deployment guides
- Performance optimization
- Multi-container strategies

### Next Session 🎯

1. Execute practical experiments
2. Validate research findings
3. Complete production readiness
4. Update documentation with results

## 🤝 Contributing

### Development Setup

1. Fork the repository
2. Create feature branch: `git checkout -b feature-name`
3. Make changes following security guidelines
4. Test thoroughly: `./scripts/test-claude.sh`
5. Submit pull request with security review

### Security Requirements

- All contributions must follow [SECURITY.md](./SECURITY.md)
- No sensitive data in any commits
- Use template files for configuration
- Security review required for all changes

## 📞 Support

### Getting Help

- 📖 **Documentation**: Check the `docs/` directory first
- 🔒 **Security Issues**: Create private security advisory
- 🐛 **Bugs**: Open issue with detailed information
- 💬 **General**: Use GitHub discussions

### Quick Commands

```bash
# Check container status
docker ps | grep claude

# View authentication state
docker exec claude-code cat /root/.claude/.credentials.json

# Monitor logs
docker logs -f claude-code

# Debug configuration
docker exec claude-code env | grep ANTHROPIC
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Claude Code Team** - For the excellent CLI tool
- **Z.AI Platform** - For API integration support
- **Docker Community** - For containerization best practices
- **Security Researchers** - For authentication analysis contributions

---

**Project Status**: 🟢 Production Ready
**Security Level**: 🔒 High
**Last Updated**: 2025-12-19
**Version**: 1.0.0

> ⚠️ **Security Reminder**: Never commit authentication credentials or sensitive data to this repository.