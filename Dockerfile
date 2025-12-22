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
    nano \
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

# Configure nano as default editor and set up Claude-friendly settings
RUN echo 'export EDITOR=nano' >> /root/.bashrc && \
    echo 'export VISUAL=nano' >> /root/.bashrc && \
    mkdir -p /root/.nano && \
    echo 'set linenumbers' >> /root/.nanorc && \
    echo 'set mouse' >> /root/.nanorc && \
    echo 'set softwrap' >> /root/.nanorc && \
    echo 'set tabsize 4' >> /root/.nanorc && \
    echo 'set tabstospaces' >> /root/.nanorc && \
    echo 'set autoindent' >> /root/.nanorc

# Volume mounts for persistent data
VOLUME ["/root/.claude", "/workspace", "/root/.ssh"]

# Copy universal entrypoint
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Set universal entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Default command (empty - entrypoint handles everything)
CMD []

# Environment variables
ENV NODE_ENV=production
ENV CLAUDE_CONFIG_DIR=/root/.claude
ENV TZ=Europe/Moscow
ENV EDITOR=nano
ENV VISUAL=nano

# Labels for metadata
LABEL maintainer="claude-code-docker-setup"
LABEL description="Claude Code CLI with all dependencies and nano editor"
LABEL version="1.1.0"
LABEL source="built from @anthropic-ai/claude-code npm package"
LABEL features="nano-editor, timezone-fix, git-config, claude-code"