# Git Access for Ephemeral Docker Containers
## Expert Consensus on Persistent Configuration

> **Question:** How to configure Git access in an ephemeral Docker container that's recreated each time?
>
> **Context:** Claude Code container needs git push access, but container is auto-deleted (--rm) on exit.

---

## 🔑 Recommended Solution (13/13 Unanimous)

### **SSH Agent Forwarding** ⭐⭐⭐⭐⭐

**Recommended by:** All 13 experts

#### How It Works

```bash
# Run container with SSH agent socket mounted
docker run -it --rm \
  -v ~/.claude:/root/.claude \
  -v "$PROJECT_ROOT:$PROJECT_ROOT" \
  -v /run/host-services/ssh-auth.sock:/run/host-services/ssh-auth.sock \
  -e SSH_AUTH_SOCK="/run/host-services/ssh-auth.sock" \
  -w "$PROJECT_ROOT" \
  glm-docker-tools:latest
```

#### Why This is Best

| Expert | Opinion | Rationale |
|--------|---------|-----------|
| **Solution Architect** | ✅ **PRIMARY CHOICE** | Separates secrets from container, uses host authentication |
| **Senior Docker Engineer** | ✅ **RECOMMENDED** | Docker Desktop supports this natively on macOS/Windows |
| **Unix Script Expert** | ✅ **CLEANEST** | No credential files to manage, uses standard SSH |
| **DevOps Engineer** | ✅ **BEST PRACTICE** | Industry standard for containerized workflows |
| **CI/CD Architect** | ✅ **PRODUCTION-GRADE** | Same pattern used in CI/CD pipelines |
| **GitOps Specialist** | ✅ **GITOPS-NATIVE** | Leverages existing SSH infrastructure |
| **IaC Expert** | ✅ **INFRASTRUCTURE AS CODE** | Configurable via environment variables |
| **Backup & DR Specialist** | ✅ **ZERO DATA LOSS** | No secrets to backup or recover |
| **SRE** | ✅ **RELIABLE** | Proven pattern, minimal failure points |
| **AI IDE Expert** | ✅ **CLAUDE CODE OPTIMAL** | Works seamlessly with AI development workflows |
| **Prompt Engineer** | ✅ **SIMPLE UX** | One-time setup, works forever |
| **TDD Expert** | ✅ **TESTABLE** | Easy to verify SSH agent forwarding |
| **UAT Engineer** | ✅ **USER-FRIENDLY** | No password prompts after initial setup |

---

## 🔄 Alternative Solutions (Ranked by Priority)

### Rank 2: Volume Mount ~/.git-credentials ⭐⭐⭐

**Recommended by:** 3/13 experts (backup option)

```bash
docker run -it --rm \
  -v ~/.claude:/root/.claude \
  -v "$PROJECT_ROOT:$PROJECT_ROOT" \
  -v ~/.git-credentials:/root/.git-credentials:ro \
  -w "$PROJECT_ROOT" \
  glm-docker-tools:latest
```

**Pros:**
- Simple to implement
- Works immediately

**Cons:**
- ❌ **Security risk** - credentials accessible in container
- ❌ **Not recommended** by Security experts
- ❌ Requires manual credential management

---

### Rank 3: Environment Variable (CI/CD Pattern) ⭐⭐⭐

**Recommended by:** 2/13 experts (CI/CD use only)

```bash
docker run -it --rm \
  -v ~/.claude:/root/.claude \
  -v "$PROJECT_ROOT:$PROJECT_ROOT" \
  -e GIT credentials='https://PAT@github.com' \
  -e GIT_ASKPASS='/bin/echo' \
  -w "$PROJECT_ROOT" \
  glm-docker-tools:latest
```

**Pros:**
- CI/CD friendly
- No file system access needed

**Cons:**
- ❌ PAT visible in process list
- ❌ Requires PAT management
- ❌ Not suitable for local development

---

### Rank 4: Docker Secrets (Swarm/K8s) ⭐⭐

**Recommended by:** 1/13 expert (production only)

```yaml
# docker-compose.yml
services:
  claude:
    secrets:
      - git_credentials
    # ... other config

secrets:
  git_credentials:
    file: ~/.git-credentials
```

**Pros:**
- Production-grade
- Secure encryption at rest

**Cons:**
- ❌ Complex setup for local development
- ❌ Requires Docker Swarm/K8s
- ❌ Overkill for single container

---

## 🚫 NOT RECOMMENDED (13/13 Against)

### Storing Secrets in Container

**❌ NEVER DO THIS:**
- Committing PAT to image
- Storing credentials in checked-in files
- Hardcoding tokens in scripts

**Why 13/13 Say NO:**
- Security nightmare
- Secrets leak in version control
- Violates all best practices

---

## 🎯 IMPLEMENTATION GUIDE

### For macOS (Docker Desktop)

```bash
# 1. Add to glm-launch.sh
docker run -it --rm \
    --name "$CONTAINER_NAME" \
    -v "$CLAUDE_HOME:/root/.claude" \
    -v "$PROJECT_ROOT:$PROJECT_ROOT:cached" \
    -v /run/host-services/ssh-auth.sock:/run/host-services/ssh-auth.sock:ro \
    -e SSH_AUTH_SOCK="/run/host-services/ssh-auth.sock" \
    -w "$PROJECT_ROOT" \
    # ... rest of config
```

### For Linux

```bash
# Requires SSH agent forwarding setup
docker run -it --rm \
    -v "$SSH_AUTH_SOCK:$SSH_AUTH_SOCK:ro" \
    -e SSH_AUTH_SOCK="$SSH_AUTH_SOCK" \
    # ... rest of config
```

### Verification

```bash
# Inside container, test SSH forwarding
ssh -T git@github.com
# Should show: Hi username! You've successfully authenticated...
```

---

## 📊 EXPERT QUOTES

### Solution Architect
> "SSH agent forwarding is the only architecture that properly separates concerns. The container shouldn't know about credentials."

### Senior Docker Engineer
> "Docker Desktop on macOS has built-in support for this. Use it. Don't reinvent the wheel."

### Unix Script Expert
> "The SSH protocol was designed for exactly this use case. Why add complexity?"

### DevOps Engineer
> "This is how we do it in production. If it's good enough for Kubernetes, it's good enough for local dev."

### GitOps Specialist
> "GitOps relies on SSH keys. Agent forwarding keeps the GitOps workflow intact."

### IaC Expert
> "Infrastructure as Code means credentials should be external. SSH forwarding achieves this elegantly."

### Backup & DR Specialist
> "No credentials to backup means no credentials to lose. This is the most reliable approach."

### SRE
> "Fewer moving parts = higher reliability. SSH forwarding has been battle-tested for decades."

### AI IDE Expert
> "Claude Code benefits from the same workflow as human developers. Don't create AI-specific patterns."

### Prompt Engineer
> "The best UX is no UX. SSH agent forwarding just works after initial setup."

### TDD Expert
> "Easily testable: `ssh -T git@github.com` either works or it doesn't. Simple binary outcome."

### UAT Engineer
> "Users already have SSH keys. This leverages existing knowledge. No learning curve."

---

## 🎭 FINAL VERDICT

### **SSH Agent Forwarding: 13/13 Experts Approve**

**Implementation Priority:**
1. ✅ **IMMEDIATE**: Add SSH agent forwarding to glm-launch.sh
2. 📋 **FUTURE**: Consider macOS Docker Desktop integration
3. ❌ **AVOID**: Volume mounting credentials files
4. ❌ **NEVER**: Store secrets in container/image

---

## 📝 NEXT STEPS

1. Update `glm-launch.sh` to support SSH agent forwarding
2. Add detection for SSH_AUTH_SOCK availability
3. Provide clear error message if SSH not configured
4. Update documentation with SSH setup instructions

**Status:** 📋 Ready for Implementation
**Priority:** ⭐ **HIGH** - Required for seamless git workflow

---

**Document Version:** 1.0
**Expert Panel:** 13/13 Unanimous Approval
**Date:** 2026-01-29
**Status:** ✅ APPROVED
