# Security Guidelines for Claude Code Docker Project

> 🏠 [Home](./README.md) > **🔒 Security Guidelines**

## 🔐 Security Overview

This project handles sensitive authentication data including OAuth tokens, API keys, and user information. Following these security guidelines is **mandatory** for all contributors.

## 🚨 CRITICAL SECURITY RULES

### NEVER Commit These Files:

1. **Authentication Credentials**:
   - `.claude/.credentials.json` - Contains OAuth tokens
   - `.claude/settings.json` - Contains API tokens
   - `claude.bak/settings.json` - Backup with sensitive data

2. **User Data**:
   - `.claude/.claude.json` - User identity and session data
   - `.claude/history.jsonl` - Conversation history
   - `.claude/session-env/` - Session environment data

3. **Temporary and Backup Files**:
   - Any `.backup` or `.bak` files
   - Temporary files with credentials
   - Debug logs containing sensitive information

## 🛡️ Security Best Practices

### 1. Environment Variables for Secrets

```bash
# Use environment variables instead of hardcoded tokens
export ANTHROPIC_AUTH_TOKEN="your_token_here"
export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
```

### 2. Template Configuration Files

- Use `.template` or `.example` extensions for configuration templates
- Never include real tokens in example files
- Provide clear instructions for setting up credentials

### 3. GitOps Workflow

```bash
# Before any commit, check for sensitive data
git status
git diff --cached --name-only | xargs grep -l "sk-ant\|API_TOKEN\|credentials\|token.*="

# Verify no sensitive files are staged
git status --porcelain | grep -E "\.(json|key|pem)$"
```

## 🔍 Security Checklist

### Before Committing:
- [ ] No OAuth tokens in any files
- [ ] No API keys or secrets
- [ ] No personal identifiable information
- [ ] No conversation history or session data
- [ ] All sensitive files are in `.gitignore`
- [ ] Configuration files use templates only

### Review Process:
- [ ] Enable secret scanning in repository settings
- [ ] Review all file additions for sensitive data
- [ ] Check `.gitignore` covers all sensitive patterns
- [ ] Verify environment variable usage

## 🔑 Token Security

### Token Types and Handling:

1. **OAuth Tokens** (`sk-ant-*`, `sk-ort-*`):
   - **Risk**: CRITICAL
   - **Action**: Never commit, rotate immediately if exposed
   - **Storage**: Environment variables only

2. **API Tokens** (custom format):
   - **Risk**: HIGH
   - **Action**: Never commit, use secure storage
   - **Storage**: Environment variables or secret management

3. **Session Tokens**:
   - **Risk**: MEDIUM
   - **Action**: Exclude from version control
   - **Storage**: Runtime only, not persistent

## 🚨 Incident Response

### If Sensitive Data is Committed:

1. **Immediate Actions**:
   ```bash
   # Remove from latest commit
   git reset --soft HEAD~1
   git rm sensitive-file.json
   git commit -m "Remove sensitive data"

   # Remove from entire history (if needed)
   git filter-branch --force --index-filter \
     'git rm --cached --ignore-unmatch sensitive-file.json' \
     --prune-empty --tag-name-filter cat -- --all
   ```

2. **Token Rotation**:
   - Revoke all exposed OAuth tokens
   - Generate new API keys
   - Update all environment configurations

3. **Repository Security**:
   - Force push cleaned history
   - Enable branch protection
   - Require pull request reviews

## 📁 Secure File Structure

```
claude-code-docker/
├── .gitignore                    # Comprehensive ignore rules
├── SECURITY.md                   # This file
├── README.md                     # Public documentation
├── Dockerfile                    # Safe Docker configuration
├── docker-compose.yml            # Safe orchestration
├── claude-launch.sh              # Safe launcher script
├── docs/                         # Documentation only
├── scripts/                      # Safe utility scripts
├── config/                       # Configuration templates
│   └── settings.template.json    # Template without secrets
└── .claude/                      # Never committed contents
    └── settings.template.json    # Template only
```

## 🔧 GitHub Security Settings

### Repository Configuration:

1. **Enable Security Features**:
   - [ ] Secret scanning
   - [ ] Dependabot alerts
   - [ ] Code security scanning
   - [ ] Advisory database checks

2. **Branch Protection**:
   - [ ] Require pull request reviews
   - [ ] Require status checks
   - [ ] Restrict force pushes
   - [ ] Require signed commits

3. **Access Control**:
   - [ ] Two-factor authentication required
   - [ ] Restricted collaborator access
   - [ ] Audit log monitoring

## 🎯 Project-Specific Security

### Claude Code Integration:

1. **Credential Storage**:
   - Store only in user's home directory (`~/.claude/`)
   - Never commit project-level credentials
   - Use environment variables for container deployment

2. **Docker Security**:
   - Use read-only volume mounts for credentials when possible
   - Implement container isolation
   - Use minimal base images

3. **API Configuration**:
   - Validate all API endpoints
   - Use HTTPS everywhere
   - Implement rate limiting

## 📞 Security Contacts

### For Security Issues:
- Create a private security advisory in GitHub
- Contact repository maintainers directly
- Do NOT open public issues for security concerns

### Emergency Response:
- Immediate token revocation required
- Repository lockdown procedures
- Full security audit process

---

## 🔗 Related Security Documentation

### 🚨 **Critical Security Reading**
- **[🔬 Authentication Research](./DOCKER_AUTHENTICATION_RESEARCH.md)** - OAuth token analysis and security findings
- **[📋 Session Handoff](./SESSION_HANDOFF.md)** - Security considerations and status
- **[🏠 Project Hub](./README.md#security)** - Security features and implementation

### 🔧 **Implementation Security**
- **[⚙️ Configuration Template](./.claude/settings.template.json)** - Secure configuration template
- **[🔧 Debug Tools](./scripts/debug-mapping.sh)** - Security validation tools
- **[📚 Usage Guide](./docs/USAGE_GUIDE.md)** - Operational security procedures

### 📚 **Additional Resources**
- **[📖 Claude Code Security](./docs/Claude-Code-Docs.md)** - Official security documentation
- **[🔍 Expert Analysis](./docs/EXPERT_ANALYSIS.md)** - Technical security insights
- **[🤖 Project Methodology](./CLAUDE.md)** - Security-focused development approach

## 🚀 Quick Security Actions

### 🆕 **New Contributors**
1. **📖 Read This Document** - Security knowledge is mandatory
2. **🔐 Configure Environment** - Use secure setup procedures
3. **🧪 Run Security Tests** - Validate security configuration

### 🔒 **Security Checklist**
- [ ] Reviewed all security guidelines
- [ ] Configured environment variables properly
- [ ] Validated .gitignore coverage
- [ ] Tested credential isolation
- [ ] Enabled repository security features

### 🚨 **If Security Issue Found**
1. **🛑 Stop Work** - Do not commit potential security issues
2. **📞 Report Immediately** - Create private security advisory
3. **🔐 Revoke Tokens** - Immediately revoke any exposed credentials
4. **📋 Document Findings** - Record security analysis and resolution

---

**Security Status**: ✅ Guidelines implemented
**Last Updated**: 2025-12-19
**Next Review**: 2026-01-19
**Security Level**: 🔒 HIGH - All sensitive data protected

**Remember**: Security is everyone's responsibility. When in doubt, don't commit!