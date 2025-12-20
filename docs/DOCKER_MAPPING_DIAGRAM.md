# Docker Mapping Architecture Diagram

## 🏗️ Current Docker Mapping Architecture

### Host Machine (macOS)
```
/Users/s060874gmail.com/
├── .claude/                              ← ACTIVE Claude State (Host)
│   ├── settings.json                    (661KB history, current chats)
│   ├── history.jsonl
│   ├── projects/
│   ├── todos/
│   └── ...
├── .docker-ai-config/                   ← DOCKER Claude State (Isolated)
│   └── global_state/
│       └── claude_config/               ← USED by Container
│           ├── settings.json            (10KB history, old chats)
│           ├── history.jsonl
│           ├── projects/
│           └── ...
├── coding/projects/
│   └── claude-code-docker/              ← Project Directory
│       ├── CLAUDE.md
│       ├── DOCKER_INVESTIGATION_TODO.md
│       └── ...
├── .ssh/
│   ├── known_hosts
│   └── config
└── .gitconfig
```

### Docker Container (claude-session-*)
```
/root/
├── .claude-config/                      ← MAPPED from Docker Config
│   └── settings.json                    (OLD state, isolated)
├── .claude/                             ← INTERNAL container state
│   └── ... (separate from both host locations)
├── .ssh/
│   ├── known_hosts                      ← MAPPED from Host
│   └── config                          ← MAPPED from Host
├── .gitconfig                          ← MAPPED from Host
└── workspace/
    └── claude-code-docker/              ← MAPPED from Host Project
        ├── CLAUDE.md
        └── ...
```

## 🔄 Current Flow Analysis

### Chat History Flow
```
Host Claude Session          Docker Container Session
┌─────────────────┐         ┌─────────────────────────┐
│ ~/.claude/       │         │ /root/.claude-config/    │
│ history.jsonl    │◄───────┤ history.jsonl            │
│ (661KB, current) │         │ (10KB, old)             │
└─────────────────┘         └─────────────────────────┘
         ▲                             ▲
         │                             │
    Different files               Different files
    (ISOLATED)                    (ISOLATED)
```

**Problem**: `/resume` command reads from container's `/root/.claude-config/` which has old history!

### Settings.json Flow
```
Host Settings                Docker Container Settings
┌─────────────────┐         ┌─────────────────────────┐
│ ~/.claude/       │         │ /root/.claude-config/    │
│ settings.json    │◄───────┤ settings.json            │
│ (GLM models)     │         │ (GLM models)             │
└─────────────────┘         └─────────────────────────┘
         ▲                             ▲
         │                             │
    Same content                 Same content
    (SYNCHRONIZED)                (SYNCHRONIZED)
```

**Status**: Currently synchronized but from different sources

## 🎯 Volume Mappings (Current Configuration)

```yaml
# Actual Docker Volume Mappings (from container inspection)
volumes:
  # Project Directory
  - /Users/s060874gmail.com/coding/projects/claude-code-docker:/workspace/claude-code-docker

  # SSH Configuration
  - /Users/s060874gmail.com/.ssh/known_hosts:/root/.ssh/known_hosts
  - /Users/s060874gmail.com/.docker-ai-config/global_state/ssh_config_clean:/root/.ssh/config

  # Git Configuration
  - /Users/s060874gmail.com/.gitconfig:/root/.gitconfig

  # GitHub CLI
  - /Users/s060874gmail.com/.docker-ai-config/gh_config:/root/.config/gh

  # ⚠️  PROBLEM: Claude Configuration (Isolated)
  - /Users/s060874gmail.com/.docker-ai-config/global_state/claude_config:/root/.claude-config

  # ⚠️  MISSING: Host ~/.claude mapping
```

## 🔧 Solution Architecture (Target State)

### Proposed Correct Mapping
```yaml
volumes:
  # Project Directory (unchanged)
  - /Users/s060874gmail.com/coding/projects/claude-code-docker:/workspace/claude-code-docker

  # SSH Configuration (unchanged)
  - /Users/s060874gmail.com/.ssh/known_hosts:/root/.ssh/known_hosts
  - /Users/s060874gmail.com/.docker-ai-config/global_state/ssh_config_clean:/root/.ssh/config

  # Git Configuration (unchanged)
  - /Users/s060874gmail.com/.gitconfig:/root/.gitconfig

  # ✅ SOLUTION: Unified Claude Configuration
  - /Users/s060874gmail.com/.claude:/root/.claude-config

  # Remove: Docker-specific claude_config mapping
```

### Expected Result After Fix
```
Unified Claude State
┌─────────────────┐         ┌─────────────────────────┐
│ Host ~/.claude/  │◄────────┤ Container /root/.claude/ │
│ history.jsonl    │────────►│ history.jsonl            │
│ settings.json    │         │ settings.json            │
│ (Current state)  │         │ (Same state)             │
└─────────────────┘         └─────────────────────────┘
         ▲                             ▲
         │                             │
    Single source                 Same single source
    of truth                     of truth
```

## 📊 Current State Summary

| Component | Host Location | Container Location | Status |
|-----------|---------------|-------------------|---------|
| **Chat History** | `~/.claude/history.jsonl` (661KB) | `/root/.claude-config/history.jsonl` (10KB) | ❌ **ISOLATED** |
| **Settings** | `~/.claude/settings.json` | `/root/.claude-config/settings.json` | ✅ Synced but different source |
| **Project Files** | `/Users/.../claude-code-docker/` | `/workspace/claude-code-docker/` | ✅ **CORRECT** |
| **SSH Config** | `~/.ssh/` | `/root/.ssh/` | ✅ **CORRECT** |
| **Git Config** | `~/.gitconfig` | `/root/.gitconfig` | ✅ **CORRECT** |

## 🚨 Root Cause Analysis

**Why `/resume` shows old chats:**

1. **Container starts** with volume mapping to `~/.docker-ai-config/global_state/claude_config/`
2. **Claude Code reads** from `/root/.claude-config/` inside container
3. **This location** contains old chat history (10KB vs 661KB on host)
4. **Host Claude sessions** use `~/.claude/` and create new history
5. **Result**: Complete isolation between host and container chat histories

**Solution**: Map container's Claude configuration directory to host's `~/.claude/` instead of isolated Docker config directory.