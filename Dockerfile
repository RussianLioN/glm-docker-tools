# Claude Code Docker Image
# Based on Node.js with Claude Code CLI installed globally
FROM node:22-alpine

# Install system dependencies required for Claude Code
RUN apk add --no-cache \
    git \
    openssh-client \
    curl \
    bash \
    python3 \
    make \
    g++ \
    tzdata \
    && rm -rf /var/cache/apk/*

# Install Claude Code CLI globally using npm
RUN npm install -g @anthropic-ai/claude-code@latest

# Set working directory
WORKDIR /workspace

# Create necessary directories with proper permissions
RUN mkdir -p /root/.claude && \
    chmod 755 /root/.claude && \
    mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh

# Configure git for proper operation
RUN git config --global user.email "claude@docker.local" && \
    git config --global user.name "Claude Docker"

# Volume mounts for persistent data
VOLUME ["/root/.claude", "/workspace", "/root/.ssh"]

# Default command
CMD ["/usr/local/bin/claude"]

# Environment variables
ENV NODE_ENV=production
ENV CLAUDE_CONFIG_DIR=/root/.claude
ENV TZ=Europe/Moscow

# Labels for metadata
LABEL maintainer="claude-code-docker-setup"
LABEL description="Claude Code CLI with all dependencies"
LABEL version="1.0.0"
LABEL source="built from @anthropic-ai/claude-code npm package"