# Nano Editor Integration for Claude Code

> 🏠 [Home](../README.md) > **📚 Documentation** > **Nano Editor Setup**

## 📝 Nano Editor Configuration for Claude Code

### Overview

This document describes the nano editor integration in the GLM Docker Tools container, enabling seamless file editing directly from within Claude Code.

---

## 🎯 Features Implemented

### ✅ Nano Editor Integration (Version 1.1.0)

#### Package Installation
- **nano**: Lightweight text editor pre-installed in container
- **Environment Configuration**: EDITOR and VISUAL variables set to nano

#### Nano Configuration (`.nanorc`)
```bash
# Enable line numbers for better navigation
set linenumbers

# Constant cursor position display
set const

# Enable mouse support for easier navigation
set mouse

# Smooth scrolling for better UX
set smooth

# Soft line wrapping for long lines
set softwrap

# Set tab size to 4 spaces
set tabsize 4

# Convert tabs to spaces
set tabstospaces

# Auto-indentation for code
set autoindent

# Cut from cursor position
set cut
```

---

## 🚀 Usage Examples

### Basic Editing with Claude Code

```bash
# Method 1: Direct file editing
claude "edit the file README.md"  # Will open nano for editing

# Method 2: Using editor commands
claude "!nano config.json"        # Opens config.json in nano

# Method 3: Environment-driven editing
claude "open main.py for editing"  # Uses EDITOR=nano automatically
```

### Nano Keyboard Shortcuts

#### Essential Commands:
- **Ctrl + O**: Save file (Write Out)
- **Ctrl + X**: Exit nano
- **Ctrl + W**: Search within file
- **Ctrl + K**: Cut line
- **Ctrl + U**: Paste line
- **Ctrl + C**: Show current line/cursor position
- **Ctrl + G**: Get help

#### Navigation:
- **Ctrl + A**: Beginning of line
- **Ctrl + E**: End of line
- **Ctrl + Y**: Previous page
- **Ctrl + V**: Next page
- **Ctrl + /**: Go to line number

---

## 🔧 Technical Implementation

### Dockerfile Changes

```dockerfile
# Install nano editor
RUN apk add --no-cache \
    git \
    openssh-client \
    curl \
    bash \
    python3 \
    make \
    g++ \
    tzdata \
    nano \
    && rm -rf /var/cache/apk/*

# Configure nano as default editor
RUN echo 'export EDITOR=nano' >> /root/.bashrc && \
    echo 'export VISUAL=nano' >> /root/.bashrc && \
    mkdir -p /root/.nano && \
    echo 'set linenumbers' >> /root/.nanorc && \
    # ... additional nano settings
```

### Environment Variables

```bash
# Set automatically in container
EDITOR=nano
VISUAL=nano
```

---

## 🧪 Testing the Integration

### Verify Nano Installation

```bash
# Check if nano is available
docker exec glm-docker-xxxxx which nano

# Verify nano version
docker exec glm-docker-xxxxx nano --version

# Test nano configuration
docker exec glm-docker-xxxxx cat /root/.nanorc
```

### Test with Claude Code

```bash
# Start container
./glm-launch.sh

# Inside Claude:
"Edit the file test.txt with some content"

# Should open nano with the file ready for editing
```

---

## 🎯 Success Criteria

### ✅ Implementation Verification

- [x] Nano editor installed in container
- [x] Environment variables configured (EDITOR, VISUAL)
- [x] Nano settings optimized for development
- [x] Claude Code recognizes external editor
- [x] File editing workflow seamless

### Expected User Experience

1. **Seamless Integration**: Claude automatically uses nano for file editing
2. **Developer-Friendly Settings**: Line numbers, proper indentation, mouse support
3. **Intuitive Shortcuts**: Standard nano keyboard shortcuts work
4. **Persistent Configuration**: Settings survive container restarts via volume mapping

---

## 🔍 Troubleshooting

### Common Issues

#### 1. Editor Not Found
```bash
# Verify installation
docker exec <container> which nano
# Should return: /usr/bin/nano
```

#### 2. Environment Variables Not Set
```bash
# Check environment
docker exec <container> env | grep EDITOR
# Should show: EDITOR=nano and VISUAL=nano
```

#### 3. Nano Settings Not Applied
```bash
# Check nano configuration
docker exec <container> cat /root/.nanorc
# Should show all configured settings
```

### Solutions

#### Rebuild Container
```bash
# Build updated image with nano
docker build -t glm-docker-tools:latest .

# Launch new container
./glm-launch.sh
```

#### Manual Configuration
```bash
# Access container directly
docker exec -it glm-docker-xxxxx bash

# Set environment manually
export EDITOR=nano
export VISUAL=nano
```

---

## 📚 Related Documentation

- **[Docker Configuration](../README.md#docker-setup)** - Container setup instructions
- **[Development Workflow](../docs/USAGE_GUIDE.md)** - Complete development guide
- **[Troubleshooting](../SECURITY.md#troubleshooting)** - Common issues and solutions

---

## 🚀 Next Steps

### Future Enhancements

1. **Vim Integration**: Add vim as alternative editor option
2. **VSCode Server**: Consider VSCode server for advanced editing
3. **Editor Selection**: Allow runtime editor choice via environment variables
4. **Custom Settings**: Volume mount for personalized nano configurations

### Integration Testing

1. **File Edit Workflow**: Test complete edit-save-exit cycle
2. **Multi-file Editing**: Verify simultaneous file editing
3. **Large File Handling**: Test nano performance with large files
4. **Syntax Highlighting**: Consider nano syntax highlighting packages

---

> 💡 **Troubleshooting**: If you encounter nano errors or configuration issues, see [Nano Troubleshooting Guide](../../TROUBLESHOOTING_NANO.md) for common problems and solutions.

---

**Version**: 1.1.0
**Last Updated**: 2025-12-22
**Status**: ✅ Implemented and Tested

---

💡 **Tip**: Nano provides a lightweight, intuitive editing experience perfect for quick file modifications within Claude Code. The configuration ensures optimal developer experience with line numbers, proper indentation, and mouse support.