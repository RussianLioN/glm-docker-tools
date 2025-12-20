#!/bin/bash

# Test script to verify Claude Code installation in Docker container

echo "Building Docker image..."
docker build -f Dockerfile.fixed -t claude-code-docker:fixed .

echo -e "\n=== Testing 1: Verify claude binary exists ==="
docker run --rm claude-code-docker:fixed which claude

echo -e "\n=== Testing 2: Check permissions ==="
docker run --rm claude-code-docker:fixed ls -la /usr/local/bin/claude

echo -e "\n=== Testing 3: Run claude --version ==="
docker run --rm claude-code-docker:fixed claude --version

echo -e "\n=== Testing 4: Run claude --help ==="
docker run --rm claude-code-docker:fixed claude --help | head -20

echo -e "\n=== Testing 5: Verify PATH contains claude binary ==="
docker run --rm claude-code-docker:fixed echo $PATH | tr ':' '\n' | grep -E "(local|bin)"

echo -e "\n=== Testing 6: Check npm global modules ==="
docker run --rm claude-code-docker:fixed npm list -g @anthropic-ai/claude-code