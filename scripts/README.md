# Scripts Directory

> 🏠 [Home](../README.md) > **📚 Documentation** > **Scripts Directory**

This directory contains utility scripts for Claude Code Docker integration.

## 📋 Available Scripts

### 🚀 **Main Launcher Scripts**

#### [`glm-launch.sh`](./glm-launch.sh) - **Primary Launcher**
**Modern container lifecycle management script with multiple modes**

```bash
# Standard mode - auto-delete container (recommended for daily use)
./glm-launch.sh

# Debug mode - persistent container with shell access for troubleshooting
./glm-launch.sh --debug

# No-del mode - persistent container for long-term tasks
./glm-launch.sh --no-del

# Additional options
./glm-launch.sh --help           # Show all available options
./glm-launch.sh --test           # Test configuration
./glm-launch.sh --backup         # Create backup of ~/.claude
./glm-launch.sh --dry-run        # Show command without executing
./glm-launch.sh -w /path/to/dir  # Specify custom workspace
```

**Container Lifecycle Modes**:
| Mode | Command | Container Behavior | Memory Usage | Use Case |
|------|---------|-------------------|--------------|----------|
| **Standard** | `./glm-launch.sh` | Auto-delete on exit (`--rm`) | ~0MB (removed) | Daily work, temporary tasks |
| **Debug** | `./glm-launch.sh --debug` | Persistent + RUNNING | ~50-100MB | Troubleshooting, investigation |
| **No-delete** | `./glm-launch.sh --no-del` | Persistent + STOPPED | ~0MB (stopped) | Long-term tasks, state preservation |

#### [`launch-multiple.sh`](./launch-multiple.sh) - **Multiple Containers**
**Launch and manage multiple Claude containers simultaneously**

```bash
# Launch multiple containers
./launch-multiple.sh 3                    # Launch 3 containers
./launch-multiple.sh                     # Launch 1 container (default)

# Container management
./launch-multiple.sh --list              # Show running containers
./launch-multiple.sh --stop              # Stop all containers
./launch-multiple.sh --clean             # Stop and remove all containers

# Configuration options
./launch-multiple.sh -w /path/to/dir     # Specify workspace
./launch-multiple.sh -i image:tag        # Specify Docker image
./launch-multiple.sh --help             # Show all options
```

### 🧪 **Testing & Validation Scripts**

#### [`test-container-lifecycle.sh`](./test-container-lifecycle.sh) - **Lifecycle Testing**
**Comprehensive testing framework for container lifecycle management**

```bash
# Run all lifecycle tests
./test-container-lifecycle.sh

# Test with real container
./test-container-lifecycle.sh --test-real

# Clean up test containers
./test-container-lifecycle.sh --cleanup

# Show help
./test-container-lifecycle.sh --help
```

**Test Coverage**:
- ✅ Auto-delete mode validation
- ✅ Debug mode functionality
- ✅ No-del mode behavior
- ✅ Conflict detection (--debug --no-del)
- ✅ Help documentation completeness
- ✅ Unique container naming
- ✅ Environment variable support

#### [`test-claude.sh`](./test-claude.sh) - **Claude Functionality**
**Test Claude Code installation and basic functionality**

```bash
# Run Claude functionality tests
./test-claude.sh

# Test specific components
./test-claude.sh --auth    # Test authentication
./test-claude.sh --config  # Test configuration
./test-claude.sh --version # Test Claude version
```

#### [`test-claude-install.sh`](./test-claude-install.sh) - **Installation Testing**
**Verify Claude Code installation in container**

```bash
# Test installation
./test-claude-install.sh

# Test with specific image
./test-claude-install.sh glm-docker-tools:latest
```

### 🔧 **Debugging & Diagnostics Scripts**

#### [`debug-mapping.sh`](./debug-mapping.sh) - **Volume Mapping Diagnostics**
**Debug Docker volume mapping issues**

```bash
# Debug volume mapping
./debug-mapping.sh

# Test specific paths
./debug-mapping.sh ~/.claude /workspace

# Verbose output
./debug-mapping.sh --verbose
```

#### [`test-config.sh`](./test-config.sh) - **Configuration Testing**
**Validate Claude Code configuration**

```bash
# Test configuration files
./test-config.sh

# Test specific config file
./test-config.sh ~/.claude/settings.json

# Validate JSON syntax
./test-config.sh --validate
```

### 🐳 **Container Management Scripts**

#### [`shell-access.sh`](./shell-access.sh) - **Convenient Shell Access**
**Simplified shell access to stopped containers with automatic start/stop**

```bash
# Connect to container with automatic lifecycle management
./scripts/shell-access.sh glm-docker-nodebug-1234567890

# Show help
./scripts/shell-access.sh --help
```

**What it does:**
1. **Checks container state** - detects if container is running or stopped
2. **Starts if needed** - automatically starts stopped containers
3. **Connects to shell** - provides interactive /bin/bash access
4. **Stops when done** - automatically stops container after exit

**Use Cases:**
- Accessing `--no-del` mode containers (which are stopped after Claude exits)
- Quick shell operations without manual container management
- Debugging and inspection of stopped containers

**Container State Management**:
| Container State | Script Behavior |
|-----------------|-----------------|
| **Stopped** | Start → Shell → Stop (automatic) |
| **Running** | Direct shell access (no lifecycle change) |
| **Not found** | Error with available containers list |

**Comparison with manual commands:**
```bash
# Manual approach (3 commands):
docker start glm-docker-nodebug-1234567890
docker exec -it glm-docker-nodebug-1234567890 /bin/bash
docker stop glm-docker-nodebug-1234567890

# With shell-access.sh (1 command):
./scripts/shell-access.sh glm-docker-nodebug-1234567890
```

### 🤖 **AI Assistant Scripts**

#### [`ai-assistant.zsh`](./ai-assistant.zsh) - **Legacy AI Assistant**
**Legacy script for launching Claude (still supported)**

```bash
# Legacy launch method
./ai-assistant.zsh

# With custom configuration
CLAUDE_STATE_DIR="$HOME/.claude" ./ai-assistant.zsh
```

> 💡 **Note**: Use `glm-launch.sh` for new installations. The `ai-assistant.zsh` script is maintained for backward compatibility.

## 🎯 Common Usage Patterns

### Debugging Authentication Issues
```bash
# 1. Use debug mode for troubleshooting
./glm-launch.sh --debug

# 2. Check configuration
./test-config.sh

# 3. Test volume mapping
./debug-mapping.sh

# 4. Run comprehensive tests
./test-container-lifecycle.sh
```

### Development Workflow
```bash
# 1. Test configuration
./test-claude.sh --config

# 2. Start development session
./glm-launch.sh --no-del

# 3. Work in Claude... (container STOPPED after exit)

# 4. Reconnect to Claude later
docker start -ai glm-docker-nodebug-1234567890

# 5. Access shell for operations
./scripts/shell-access.sh glm-docker-nodebug-1234567890
```

### Testing New Features
```bash
# 1. Run all tests
./test-container-lifecycle.sh

# 2. Test with real container
./test-container-lifecycle.sh --test-real

# 3. Clean up if needed
./test-container-lifecycle.sh --cleanup
```

## 🔒 Security Considerations

- **Debug Mode**: Container stays RUNNING - consumes resources, use only when necessary
- **No-del Mode**: Container STOPS after Claude - resource-efficient, clean up regularly
- **Shell Access**: Use `shell-access.sh` for convenient container management
- **Persistent Containers**: May contain sensitive data - remove with `docker rm -f <container>`
- **Volume Mounts**: Ensure proper file permissions
- **API Tokens**: Store securely in `~/.claude/` directory

## 📚 Related Documentation

- **[Container Lifecycle Management](../docs/CONTAINER_LIFECYCLE_MANAGEMENT.md)** - Complete lifecycle guide
- **[Usage Guide](../docs/USAGE_GUIDE.md)** - Daily operations and workflows
- **[Security Guidelines](../SECURITY.md)** - Security best practices
- **[Configuration Reference](../docs/Claude-Code-settings.md)** - Settings documentation

## 🐛 Troubleshooting

### Common Issues

**Container not starting**:
```bash
# Check Docker daemon
docker info

# Test configuration
./test-claude.sh

# Check volume mapping
./debug-mapping.sh
```

**Permission errors**:
```bash
# Check file permissions
ls -la ~/.claude/
ls -la scripts/

# Fix script permissions
chmod +x scripts/*.sh
```

**Authentication issues**:
```bash
# Use debug mode
./glm-launch.sh --debug

# Check configuration
./test-config.sh

# Verify API connectivity
docker exec -it claude-debug curl https://api.z.ai/api/anthropic/models
```

**Container accumulation**:
```bash
# Clean up all containers
./test-container-lifecycle.sh --cleanup

# Or manual cleanup
docker ps -aq --filter "name=glm-docker" | xargs -r docker rm -f
```

---

**Status**: ✅ **Production Ready** - All scripts tested and documented

**Last Updated**: 2025-12-22 (New: `shell-access.sh` utility, optimized container lifecycle)
**Version**: 1.2.0
**Compatible**: Claude Code Docker Integration with Lifecycle Management