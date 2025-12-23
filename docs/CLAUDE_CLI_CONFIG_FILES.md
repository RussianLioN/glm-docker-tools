# Claude Code CLI Configuration Files

## 📋 Overview

This document describes the configuration files that **Claude Code CLI automatically creates** in the `~/.claude/` directory on first run or during operation.

**Important**: The scripts in this project (`glm-launch.sh`, `docker-entrypoint.sh`, etc.) do **NOT** create these files. They are created by **Claude Code CLI itself** when it runs.

## 🗂️ File Structure

### Directory Location

```
~/.claude/                          # Home directory (on host system)
├── .claude.json                   # User identity and session state
├── .credentials.json               # OAuth authentication tokens
├── settings.json                   # API configuration (optional)
├── history.jsonl                   # Chat history (append-only)
├── projects/                       # Project-specific state
├── session-env/                    # Session environment data
├── plugins/                        # Installed plugins
└── ...                             # Other runtime files
```

## 📄 Auto-Created Files

### 1. `.claude.json` - User Identity

**When created**: First run of Claude Code CLI

**Purpose**: Stores user identity and session tracking

**Structure**:
```json
{
  "userID": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "lastSessionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "created": "2025-12-23T12:00:00.000Z"
}
```

**Fields**:
- `userID`: Unique user identifier (UUID format)
- `lastSessionId`: Most recent session UUID
- `created`: Timestamp of first Claude Code run

**Notes**:
- This file is critical for session continuity
- Contains no sensitive authentication data
- Safe to backup and restore

---

### 2. `.credentials.json` - OAuth Tokens

**When created**: After successful OAuth authentication

**Purpose**: Stores OAuth access and refresh tokens

**Structure**:
```json
{
  "claudeAiOauth": {
    "expiresAt": 1234567890000,
    "accessToken": "eyJhbGciOi...",
    "refreshToken": "eyJhbGciOi...",
    "tokenType": "Bearer",
    "scopes": ["scope1", "scope2"]
  }
}
```

**Fields**:
- `expiresAt`: Token expiration timestamp (milliseconds since epoch)
- `accessToken`: Current active OAuth access token
- `refreshToken`: Token for obtaining new access tokens
- `tokenType`: Typically "Bearer"
- `scopes`: OAuth permission scopes

**Security Notes**:
- ⚠️ **HIGHLY SENSITIVE** - contains authentication tokens
- Never commit to version control
- Protect with restrictive file permissions (chmod 600)
- Backup securely if needed

**Priority**: OAuth tokens **override** API configuration in `settings.json`

---

### 3. `settings.json` - API Configuration

**When created**: First run (with defaults) or when user configures API

**Purpose**: Stores API configuration and Claude Code preferences

**Structure**:
```json
{
  "ANTHROPIC_AUTH_TOKEN": "sk-ant-...",
  "ANTHROPIC_BASE_URL": "https://api.anthropic.com",
  "ANTHROPIC_MODEL": "claude-sonnet-4-20250514",
  "alwaysThinkingEnabled": false,
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "sk-ant-...",
    "ANTHROPIC_BASE_URL": "https://api.anthropic.com",
    "API_TIMEOUT_MS": "300000"
  }
}
```

**Common Fields**:
- `ANTHROPIC_AUTH_TOKEN`: API key (for non-OAuth usage)
- `ANTHROPIC_BASE_URL`: API endpoint URL
- `ANTHROPIC_MODEL`: Default model to use
- `ANTHROPIC_DEFAULT_HAIKU_MODEL`: Fast model for simple tasks
- `ANTHROPIC_DEFAULT_OPUS_MODEL`: Advanced model
- `ANTHROPIC_DEFAULT_SONNET_MODEL`: Balanced model
- `alwaysThinkingEnabled`: Extended thinking mode
- `env`: Environment variable overrides

**GLM Configuration Example**:
```json
{
  "ANTHROPIC_AUTH_TOKEN": "your-zai-token-here",
  "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic",
  "ANTHROPIC_MODEL": "glm-4.7",
  "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.5-air",
  "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-4.7",
  "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-4.7",
  "alwaysThinkingEnabled": true,
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "your-zai-token-here",
    "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic",
    "ANTHROPIC_MODEL": "glm-4.7",
    "API_TIMEOUT_MS": "3000000"
  }
}
```

**Notes**:
- Can be manually created or edited
- Used when OAuth is not available
- Overridden by project-specific settings (see [GLM Configuration Guide](./GLM_CONFIGURATION_GUIDE.md))

---

### 4. `history.jsonl` - Chat History

**When created**: First run (empty file)

**Purpose**: Append-only log of all chat conversations

**Format**: JSONL (one JSON object per line)

**Example**:
```jsonl
{"timestamp":"2025-12-23T12:00:00.000Z","role":"user","content":"Hello"}
{"timestamp":"2025-12-23T12:00:01.000Z","role":"assistant","content":"Hi there!"}
```

**Notes**:
- Append-only format for efficient logging
- Can grow large over time
- Safe to delete if storage is a concern (chats will be lost)
- Automatically backed up by some Claude Code installations

---

## 🔄 Creation Order and Priorities

### First Run (No OAuth)

1. **Directory creation**: `~/.claude/` created if it doesn't exist
2. **`.claude.json`**: Created with new userID
3. **`history.jsonl`**: Created as empty file
4. **`settings.json`**: Created with defaults OR checked for existing configuration

### First Run (With OAuth)

1-4. Same as above
5. **OAuth flow initiated**: User prompted for authentication
6. **`.credentials.json`**: Created with OAuth tokens

### Settings Precedence (Highest to Lowest)

1. **Managed settings** (Enterprise) - Cannot be overridden
2. **Command line arguments** - Temporary for current session
3. **`.claude/settings.local.json`** - Personal project overrides
4. **`.claude/settings.json`** - Project/team settings ⭐
5. **`~/.claude/settings.json`** - Global user settings
6. **`.credentials.json`** - **Overrides settings.json** API config

---

## 📁 File Locations in Containers

### Docker Container Mapping

When using `glm-launch.sh`, the following volume mounts apply:

```
Host:                    Container:
~/.claude/          →     /root/.claude        (System files)
./.claude/           →     /workspace/.claude/   (Project files)
```

**In the container**:
- `/root/.claude/.claude.json` - User identity (from host)
- `/root/.claude/.credentials.json` - OAuth tokens (from host)
- `/root/.claude/settings.json` - User settings (from host)
- `/root/.claude/history.jsonl` - Chat history (from host)
- `/workspace/.claude/settings.json` - Project settings (from project)

### Project Settings Override

If `./.claude/settings.json` exists in the project directory:
- Claude Code finds it at `/workspace/.claude/settings.json`
- Project settings **override** user settings in `/root/.claude/settings.json`
- OAuth and history remain shared via `/root/.claude/`

---

## 🔒 Security Considerations

### File Permissions

Recommended permissions:
```bash
chmod 600 ~/.claude/.credentials.json    # OAuth tokens (restrictive)
chmod 600 ~/.claude/settings.json       # API keys (restrictive)
chmod 644 ~/.claude/.claude.json        # User ID (can be public)
chmod 644 ~/.claude/history.jsonl       # History (can be public)
```

### Git Security

**NEVER commit these files**:
- `.credentials.json` - OAuth tokens
- `settings.json` - Contains API keys/tokens

**Can commit** (with caution):
- `.claude.json` - User identity only (no sensitive data)
- `settings.template.json` - Template without real tokens

### Backup Strategy

**Critical files to backup**:
- `~/.claude/.credentials.json` - To avoid re-authentication
- `~/.claude/.claude.json` - For session continuity

**Optional backup**:
- `~/.claude/settings.json` - API configuration
- `~/.claude/history.jsonl` - Chat history

**Backup command**:
```bash
# Create timestamped backup
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
cp -a ~/.claude ~/.claude-backup-$TIMESTAMP
```

---

## 🧪 Verification

### Check Auto-Created Files

```bash
# List all config files
ls -la ~/.claude/

# View user identity
cat ~/.claude/.claude.json | jq '.userID'

# Check OAuth status
cat ~/.claude/.credentials.json | jq '.claudeAiOauth.expiresAt'

# View API configuration
cat ~/.claude/settings.json | jq '.ANTHROPIC_BASE_URL'

# Check history size
wc -l ~/.claude/history.jsonl
du -h ~/.claude/history.jsonl
```

### Verify Volume Mounting in Container

```bash
# Run in debug mode
./glm-launch.sh --debug

# In container shell, check file sources
echo "=== .claude.json ==="
cat /root/.claude/.claude.json | head -3

echo "=== .credentials.json ==="
cat /root/.claude/.credentials.json | head -3

echo "=== Project settings ==="
ls -la /workspace/.claude/
```

---

## 📖 Related Documentation

- **[GLM Configuration Guide](./GLM_CONFIGURATION_GUIDE.md)** - Project-specific GLM API setup
- **[Authentication Research](../DOCKER_AUTHENTICATION_RESEARCH.md)** - OAuth and API authentication analysis
- **[Settings Reference](./Claude-Code-settings.md)** - Complete settings documentation
- **[Container Lifecycle Management](./CONTAINER_LIFECYCLE_MANAGEMENT.md)** - Docker container modes

---

## 🎯 Summary

| File | Created By | Purpose | Sensitive? |
|------|-------------|---------|------------|
| `.claude.json` | Claude Code CLI | User identity | ❌ No |
| `.credentials.json` | Claude Code CLI (OAuth) | OAuth tokens | ✅ **YES** |
| `settings.json` | Claude Code CLI / User | API configuration | ⚠️ May contain tokens |
| `history.jsonl` | Claude Code CLI | Chat history | ⚠️ May contain sensitive data |

**Key Takeaway**: None of these files are created by the project's scripts (`glm-launch.sh`, `docker-entrypoint.sh`, etc.). They are **automatically created by Claude Code CLI** during its normal operation.
