# GLM Configuration Guide

## 🎯 Overview

This guide explains how to configure project-specific GLM API settings that automatically override system Anthropic configuration while preserving shared OAuth tokens and chat history.

## 📋 Why Project-Specific Configuration?

### Problem

When using Claude Code with different API providers (Anthropic vs GLM/Z.AI), the configuration is typically stored in `~/.claude/settings.json`. This creates conflicts:
- **System `~/.claude/`**: May contain Anthropic Claude configuration
- **Container needs**: GLM/Z.AI API configuration

### Solution

Use Claude Code's **built-in project settings support** - it automatically searches for `.claude/settings.json` in your project directory!

## 🏗️ Architecture (The Elegant Solution)

### How It Works

Claude Code has built-in support for project-specific settings. It automatically searches for settings in:

```
<workspace>/.claude/settings.json
```

**Inside the container**, this becomes:
```
/workspace/.claude/settings.json
```

### Volume Mapping

Only **TWO volume mounts** needed:

```bash
-v ~/.claude:/root/.claude    # System (OAuth, history, user settings)
-v $(pwd):/workspace          # Project (naturally includes .claude)
```

**How it works:**
1. Host `$(pwd)/.claude` becomes `/workspace/.claude` inside container
2. Claude Code automatically finds `/workspace/.claude/settings.json`
3. Settings precedence: **Project > User** (as designed)
4. **No special environment variables or extra mounts needed!**

### Architecture Diagram

```
Host Structure:
├── ~/.claude/                      # System (OAuth, history)
│   ├── .credentials.json           # OAuth tokens (shared)
│   ├── .claude.json               # User identity
│   ├── history.jsonl              # Chat history (shared)
│   └── settings.json              # User settings (optional)
└── /path/to/project/              # Project directory
    └── .claude/                   # Project settings
        ├── settings.json          # GLM API config
        └── settings.local.json    # Local overrides

Container Mapping:
~/.claude            →  /root/.claude           (System files)
/path/to/project/    →  /workspace              (Project workspace)
                            └── .claude/        (Found automatically!)
```

### Settings Precedence (Automatic)

Claude Code uses this order:
1. `/workspace/.claude/settings.local.json` (if exists) - Highest priority
2. `/workspace/.claude/settings.json` - **Our GLM config**
3. `/root/.claude/settings.json` - User settings (lowest)

**Result**: Project GLM settings automatically override user Anthropic settings!

## 🚀 Quick Start

### Option 1: Interactive Setup (Recommended)

```bash
# Run the interactive setup script
./scripts/setup-glm-config.sh
```

The script will prompt for:
- Z.AI API token
- API base URL (default: `https://api.z.ai/api/anthropic`)
- Model name (default: `glm-4.7`)

### Option 2: Manual Configuration

```bash
# 1. Create project .claude directory
mkdir -p ./.claude

# 2. Copy the template
cp .claude/settings.template.json .claude/settings.json

# 3. Edit with your API token
nano .claude/settings.json
```

Replace `YOUR_GLM_TOKEN_HERE` with your actual Z.AI API token.

## 📝 Configuration File Format

### `.claude/settings.json`

```json
{
  "_comment": "GLM API Configuration - Project Specific",
  "ANTHROPIC_AUTH_TOKEN": "your-zai-api-token-here",
  "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic",
  "ANTHROPIC_MODEL": "glm-4.7",
  "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.5-air",
  "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-4.7",
  "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-4.7",
  "alwaysThinkingEnabled": true,
  "env": {
    "EDITOR": "nano",
    "VISUAL": "nano",
    "ANTHROPIC_AUTH_TOKEN": "your-zai-api-token-here",
    "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic",
    "ANTHROPIC_MODEL": "glm-4.7",
    "API_TIMEOUT_MS": "3000000"
  }
}
```

### Available Models

| Model | Use Case |
|-------|----------|
| `glm-4.7` | General purpose, default |
| `glm-4.5-air` | Fast, lightweight tasks |

## 🧪 Verification

### Test Configuration Detection

```bash
# Run launcher to see if project config is detected
./glm-launch.sh --dry-run

# Expected output includes:
# [SUCCESS] 🎯 Project GLM configuration detected
# [INFO]   Location: ./.claude/settings.json
# [INFO]   Container path: /workspace/.claude/settings.json
```

### Test in Debug Mode

```bash
# Run in debug mode to inspect container
./glm-launch.sh --debug

# In container shell, verify settings:
cat /workspace/.claude/settings.json | grep ANTHROPIC_BASE_URL
# Should show: https://api.z.ai/api/anthropic

# Verify OAuth is still accessible:
cat /root/.claude/.credentials.json
```

### Verify OAuth is Shared

```bash
# Check OAuth tokens are accessible from host
cat ~/.claude/.credentials.json

# In container, verify same tokens (no re-auth needed!)
docker exec -it <container-name> cat /root/.claude/.credentials.json
```

## 🔧 Troubleshooting

### Issue: Project config not detected

**Symptoms**: No "Project GLM configuration detected" message

**Solutions**:
1. Verify file exists: `ls -la ./.claude/settings.json`
2. Check you're in the correct directory (project root)
3. Ensure file is valid JSON: `cat ./.claude/settings.json | python3 -m json.tool`

### Issue: API authentication fails

**Symptoms**: "Invalid API key" error

**Solutions**:
1. Verify token in `./.claude/settings.json`
2. Check token hasn't expired
3. Verify `ANTHROPIC_BASE_URL` is correct
4. Test API directly:
   ```bash
   curl -H "Authorization: Bearer YOUR_TOKEN" \
        https://api.z.ai/api/anthropic/models
   ```

### Issue: OAuth prompt appears

**Symptoms**: Container asks for OAuth authorization

**Solutions**:
1. Verify `~/.claude/.credentials.json` exists
2. Check volume mapping: `./glm-launch.sh --dry-run | grep claude`
3. Ensure system OAuth is valid (not expired)

### Issue: Settings not overriding

**Symptoms**: Anthropic settings still being used

**Solutions**:
1. Verify project settings path in container: `/workspace/.claude/settings.json`
2. Check file is readable inside container
3. Ensure no `settings.local.json` is overriding

## 📚 Advanced Usage

### Multiple Projects with Different Tokens

Each project can have its own `.claude/settings.json`:

```bash
# Project A with token A
cd ~/projects/project-a
./scripts/setup-glm-config.sh  # Enter token A

# Project B with token B
cd ~/projects/project-b
./scripts/setup-glm-config.sh  # Enter token B
```

### Local Overrides Without Committing

Use `.claude/settings.local.json` for local-only overrides:

```bash
# Create local override (gitignored)
cat > .claude/settings.local.json << EOF
{
  "ANTHROPIC_MODEL": "glm-4.5-air",
  "alwaysThinkingEnabled": false
}
EOF
```

## 🔐 Security Best Practices

1. **Never commit API tokens**: `.claude/settings.json` is in `.gitignore`
2. **Use restrictive permissions**: `chmod 600 .claude/settings.json`
3. **Rotate tokens regularly**: Update tokens periodically
4. **Separate tokens per environment**: Use different tokens for dev/prod

```bash
# Secure your settings
chmod 600 .claude/settings.json
chmod 700 .claude

# Verify permissions
ls -la .claude/
```

## 📖 References

- **[GLM API Documentation](./Claude-Code-GLM.md)** - Complete GLM API setup guide
- **[Container Lifecycle Management](./CONTAINER_LIFECYCLE_MANAGEMENT.md)** - Container modes
- **[Settings Reference](./Claude-Code-settings.md)** - Complete settings documentation

## 🎯 Summary

| File | Location | Purpose | Git Tracked |
|------|----------|---------|-------------|
| `settings.template.json` | `./.claude/` | Template for new setups | ✅ Yes |
| `settings.json` | `./.claude/` | Your GLM API config | ❌ No |
| `settings.local.json` | `./.claude/` | Local overrides | ❌ No |
| `.credentials.json` | `~/.claude/` | OAuth tokens (shared) | ❌ No |
| `history.jsonl` | `~/.claude/` | Chat history (shared) | ❌ No |
