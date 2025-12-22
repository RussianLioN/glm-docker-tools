# Claude Code Settings Template Guide

> 🏠 [Home](../README.md) > **📚 Documentation** > **Settings Template Guide**

## 🔧 Configuration Template for Claude Code CLI

This guide explains how to use the Claude Code settings template with pre-configured nano editor and optimal development settings.

---

## 📋 Overview

The `.claude/settings.template.json` file provides a ready-to-use configuration template for Claude Code CLI with:

- **✅ External Editor Integration**: Pre-configured nano editor
- **🌐 Z.AI API Configuration**: GLM models setup
- **⚙️ Development Optimizations**: Extended thinking and timeouts
- **🔧 Environment Variables**: Proper variable hierarchy

---

## 🚀 Quick Start

### Step 1: Copy Template to Active Settings

```bash
# Navigate to project directory
cd /path/to/glm-docker-tools

# Copy template to active settings
cp .claude/settings.template.json .claude/settings.json
```

### Step 2: Update API Token

Edit `.claude/settings.json` and replace `YOUR_API_TOKEN_HERE` with your actual Z.AI API token:

```json
{
  "ANTHROPIC_AUTH_TOKEN": "your_actual_z_ai_token_here",
  "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic",
  // ... rest of configuration
}
```

### Step 3: Verify Configuration

```bash
# Test configuration with Claude Code
docker run --rm -v ~/.claude:/root/.claude glm-docker-tools:latest \
  /usr/local/bin/claude --version
```

---

## 📝 Template Configuration Breakdown

### External Editor Settings

```json
"env": {
  "EDITOR": "nano",
  "VISUAL": "nano",
  // ... other settings
}
```

**Purpose**: Configure nano as the external text editor for Claude Code

**Usage**: Press `Ctrl+G` in Claude Code to open current prompt in nano editor

**Benefits**:
- Seamless text editing experience
- Familiar keyboard shortcuts
- Syntax highlighting support
- Search and replace functionality

### Z.AI API Configuration

```json
{
  "ANTHROPIC_AUTH_TOKEN": "YOUR_API_TOKEN_HERE",
  "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic",
  "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.5-air",
  "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-4.6",
  "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-4.6",
  "ANTHROPIC_MODEL": "glm-4.6"
}
```

**Purpose**: Configure Claude Code to use Z.AI API with GLM models

**Models**:
- **glm-4.6**: Primary model for general tasks
- **glm-4.5-air**: Lightweight model for quick tasks

### Development Optimizations

```json
{
  "alwaysThinkingEnabled": true,
  "env": {
    "alwaysThinkingEnabled": "true",
    "API_TIMEOUT_MS": "3000000"
  }
}
```

**Purpose**: Optimize Claude Code for development workflow

**Features**:
- **Extended Thinking**: Enhanced reasoning capabilities
- **Extended Timeout**: 50-minute timeout for complex tasks
- **Consistent Environment**: Variables available both directly and via env section

---

## 🔧 Advanced Configuration

### Environment Variable Hierarchy

Claude Code settings support multiple levels of environment variable configuration:

1. **Direct Setting**: `"ANTHROPIC_MODEL": "glm-4.6"`
2. **Env Section**: `"env": {"ANTHROPIC_MODEL": "glm-4.6"}`
3. **Shell Environment**: Exported in shell profile
4. **Docker Environment**: Set in Docker container

**Precedence**: Settings > env > shell > Docker

### Custom Editor Configuration

To use a different editor than nano:

```json
"env": {
  "EDITOR": "vim",
  "VISUAL": "vim"
}
```

**Supported Editors**:
- `nano` - Beginner-friendly text editor
- `vim` - Advanced modal editor
- `emacs` - Extensible editor
- `code` - VS Code (requires installation)

### Timeout Configuration

Adjust timeout based on your needs:

```json
"env": {
  "API_TIMEOUT_MS": "600000"  // 10 minutes for quick tasks
  // or
  "API_TIMEOUT_MS": "7200000" // 2 hours for complex tasks
}
```

---

## 🧪 Testing Your Configuration

### Test Editor Integration

```bash
# Start Claude Code with your configuration
docker run -it -v ~/.claude:/root/.claude glm-docker-tools:latest

# Inside Claude Code, press Ctrl+G to test editor
# Nano should open with your current prompt
```

### Test API Connection

```bash
# Test with a simple prompt
docker run -it -v ~/.claude:/root/.claude glm-docker-tools:latest \
  /usr/local/bin/claude -p "Hello, Claude!"
```

### Validate Settings

```bash
# Check if Claude loads your settings
docker run --rm -v ~/.claude:/root/.claude glm-docker-tools:latest \
  sh -c 'echo "Editor: $EDITOR" && echo "API Base: $ANTHROPIC_BASE_URL"'
```

---

## 🔒 Security Best Practices

### Token Management

- **✅ Do**: Store tokens in `settings.json` only
- **❌ Don't**: Commit tokens to version control
- **✅ Do**: Use `.gitignore` for `settings.json`
- **❌ Don't**: Share tokens in public documentation

### File Permissions

```bash
# Secure your settings file
chmod 600 .claude/settings.json
```

### Environment Variables

For enhanced security, use environment variables instead of hardcoded tokens:

```bash
# Set token in environment
export ANTHROPIC_AUTH_TOKEN="your_token_here"

# Reference in settings.json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "$ANTHROPIC_AUTH_TOKEN"
  }
}
```

---

## 🐳 Docker Integration

### Container Settings

When using Docker containers, ensure proper volume mounting:

```bash
docker run -it \
  -v ~/.claude:/root/.claude \
  -v $(pwd):/workspace \
  glm-docker-tools:latest
```

### Container Environment

The Docker image already includes:
- ✅ Nano editor installed and configured
- ✅ Environment variables set
- ✅ Proper file permissions
- ✅ Development optimizations

### Multi-Container Setup

For multiple containers with shared settings:

```yaml
version: '3.8'
services:
  claude-dev:
    image: glm-docker-tools:latest
    volumes:
      - ~/.claude:/root/.claude
      - ./project:/workspace
    environment:
      - EDITOR=nano
      - VISUAL=nano
```

---

## 🔍 Troubleshooting

### Editor Not Working

**Problem**: Ctrl+G doesn't open nano editor

**Solution**:
1. Check if nano is installed: `which nano`
2. Verify environment variables: `echo $EDITOR`
3. Ensure settings.json is properly formatted
4. Restart Claude Code after changes

### API Connection Issues

**Problem**: Claude can't connect to Z.AI API

**Solution**:
1. Verify token is valid and active
2. Check network connectivity
3. Confirm base URL is correct: `https://api.z.ai/api/anthropic`
4. Review token permissions and quota

### Settings Not Loading

**Problem**: Configuration changes not taking effect

**Solution**:
1. Validate JSON syntax: `jq . .claude/settings.json`
2. Check file permissions: `ls -la .claude/settings.json`
3. Ensure correct file location
4. Restart Claude Code container

### Timeout Issues

**Problem**: Tasks timing out too quickly

**Solution**:
```json
"env": {
  "API_TIMEOUT_MS": "600000"  // Increase to 10 minutes
}
```

---

## 📚 Related Documentation

- **[Nano Editor Setup](./NANO_EDITOR_SETUP.md)** - Complete nano configuration guide
- **[Z.AI API Integration](./Claude-Code-GLM.md)** - API setup and authentication
- **[Settings Reference](./Claude-Code-settings.md)** - Complete settings documentation
- **[Docker Configuration](../README.md#docker-setup)** - Container setup instructions

---

## ✅ Configuration Checklist

### Essential Settings
- [ ] API token configured and valid
- [ ] Base URL set to `https://api.z.ai/api/anthropic`
- [ ] Editor configured (nano by default)
- [ ] Timeouts set appropriately for your workflow

### Security Settings
- [ ] Token not committed to version control
- [ ] File permissions properly set (600)
- [ ] Backup of configuration created

### Docker Integration
- [ ] Volume mounts configured correctly
- [ ] Container image up to date
- [ ] Environment variables available in container

### Testing Validation
- [ ] Editor integration tested (Ctrl+G)
- [ ] API connection verified
- [ ] Settings loading confirmed
- [ ] Performance acceptable

---

**Status**: ✅ **Ready for Production** - Template includes all essential configurations for optimal Claude Code development experience

**Last Updated**: 2025-12-22
**Version**: 1.1.0
**Compatible**: Claude Code CLI with Z.AI API integration