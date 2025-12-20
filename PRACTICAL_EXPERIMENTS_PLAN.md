# Practical Experiments Plan: Claude Code Docker Authentication

## 🧪 Experimental Validation Plan

**Purpose**: Validate authentication theories with practical experiments
**Target Confidence**: 95%+ verification
**Planned Duration**: 2-3 weeks
**Safety Level**: Medium (isolated test environments)

---

## 📋 Experiment Overview

### High-Priority Experiments

1. **Volume Mapping Identity Verification** (Priority: CRITICAL)
2. **OAuth vs Z.AI API Priority Testing** (Priority: HIGH)
3. **Token Expiration and Refresh Mechanism** (Priority: HIGH)
4. **Container Identity Parameter Analysis** (Priority: MEDIUM)

### Medium-Priority Experiments

5. **Multi-Container Isolation Strategies**
6. **Security Boundary Validation**
7. **Performance Impact Assessment**
8. **Cross-Platform Compatibility**

---

## 🔬 Experiment 1: Volume Mapping Identity Verification

### Objective
Verify that authorization persistence is determined by volume mapping identity rather than container names or images.

### Hypothesis
Containers with identical volume mapping will share authentication, regardless of container names or images.

### Test Matrix

#### Test 1A: Identical Volume Mappings (Shared Auth)

```bash
# Setup test environment
mkdir -p ~/claude-test-experiment/volume-identity
cd ~/claude-test-experiment/volume-identity

# Create shared credential directory
mkdir -p shared-credentials

# Container A - First authentication
docker run -d --name test-identical-A \
  -v $(pwd)/shared-credentials:/root/.claude \
  -v $(pwd)/workspace-A:/workspace \
  -w /workspace \
  claude-code-docker:latest

# Container B - Should inherit auth
docker run -d --name test-identical-B \
  -v $(pwd)/shared-credentials:/root/.claude \
  -v $(pwd)/workspace-B:/workspace \
  -w /workspace \
  claude-code-docker:latest

# Container C - Different image, same volumes
docker run -d --name test-identical-C \
  -v $(pwd)/shared-credentials:/root/.claude \
  -v $(pwd)/workspace-C:/workspace \
  -w /workspace \
  node:22-alpine \
  sh -c "npm install -g @anthropic-ai/claude-code@latest && /usr/local/bin/claude"
```

#### Test 1B: Different Volume Mappings (Isolated Auth)

```bash
# Container A - Isolated credentials
docker run -d --name test-different-A \
  -v $(pwd)/credentials-A:/root/.claude \
  -v $(pwd)/workspace-A:/workspace \
  -w /workspace \
  claude-code-docker:latest

# Container B - Separate isolated credentials
docker run -d --name test-different-B \
  -v $(pwd)/credentials-B:/root/.claude \
  -v $(pwd)/workspace-B:/workspace \
  -w /workspace \
  claude-code-docker:latest
```

### Validation Criteria

**Expected Results Test 1A:**
- Container A: Requires initial OAuth authentication
- Container B: Inherits authentication from A (no OAuth prompt)
- Container C: Inherits authentication even with different base image

**Expected Results Test 1B:**
- Container A: Requires separate OAuth authentication
- Container B: Requires separate OAuth authentication
- No shared authentication state

### Data Collection

```bash
# Collect authentication state
collect_auth_state() {
  local container_name=$1
  local output_dir=$2

  mkdir -p "$output_dir"

  # Credential files
  docker exec "$container_name" cat /root/.claude/.credentials.json > "$output_dir/credentials.json" 2>/dev/null || echo "No credentials file"

  # User identity
  docker exec "$container_name" cat /root/.claude/.claude.json > "$output_dir/claude.json" 2>/dev/null || echo "No claude.json file"

  # Settings
  docker exec "$container_name" cat /root/.claude/settings.json > "$output_dir/settings.json" 2>/dev/null || echo "No settings file"

  # Volume mapping info
  docker inspect "$container_name" --format='{{json .Mounts}}' > "$output_dir/volumes.json"

  # Environment variables
  docker exec "$container_name" env | grep -i claude > "$output_dir/claude-env.txt"
}

# Usage
collect_auth_state "test-identical-A" "./results/container-A"
collect_auth_state "test-identical-B" "./results/container-B"
```

### Success Metrics

1. **Authentication Sharing**: Containers with identical volume mappings share authentication
2. **Isolation Verification**: Containers with different volume mappings have separate authentication
3. **Cross-Image Compatibility**: Different images with same volumes share authentication
4. **File Synchronization**: Credential files are identical across shared containers

---

## 🔬 Experiment 2: OAuth vs Z.AI API Priority Testing

### Objective
Confirm that OAuth tokens take priority over Z.AI API configuration in settings.json.

### Hypothesis
When both OAuth tokens and Z.AI API configuration are present, OAuth authentication is used exclusively.

### Test Setup

#### Test 2A: OAuth Present vs API Configured

```bash
# Setup environment with both OAuth and Z.AI API
mkdir -p ~/claude-test-experiment/oauth-priority
cd ~/claude-test-experiment/oauth-priority

# Create test directory with both configurations
mkdir -p test-credentials

# Add Z.AI API configuration
cat > test-credentials/settings.json << EOF
{
  "ANTHROPIC_AUTH_TOKEN": "YOUR_API_TOKEN_HERE",
  "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic",
  "ANTHROPIC_MODEL": "glm-4.6",
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "YOUR_API_TOKEN_HERE",
    "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic",
    "ANTHROPIC_MODEL": "glm-4.6",
    "API_TIMEOUT_MS": "3000000"
  }
}
EOF

# Copy existing OAuth tokens
cp ~/.claude/.credentials.json test-credentials/ 2>/dev/null || echo "No existing OAuth tokens"

# Test container
docker run -d --name oauth-priority-test \
  -v $(pwd)/test-credentials:/root/.claude \
  -v $(pwd)/workspace:/workspace \
  -w /workspace \
  claude-code-docker:latest
```

#### Test 2B: API Only (No OAuth)

```bash
# Create test directory with only API configuration
mkdir -p api-only-credentials

cat > api-only-credentials/settings.json << EOF
{
  "ANTHROPIC_AUTH_TOKEN": "YOUR_API_TOKEN_HERE",
  "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic",
  "ANTHROPIC_MODEL": "glm-4.6",
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "YOUR_API_TOKEN_HERE",
    "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic",
    "ANTHROPIC_MODEL": "glm-4.6",
    "API_TIMEOUT_MS": "3000000"
  }
}
EOF

# Test container with API only
docker run -d --name api-only-test \
  -v $(pwd)/api-only-credentials:/root/.claude \
  -v $(pwd)/workspace:/workspace \
  -w /workspace \
  claude-code-docker:latest
```

### Validation Methods

#### Network Traffic Analysis

```bash
# Monitor network requests to identify which API endpoint is used
monitor_api_calls() {
  local container_name=$1
  local duration=300  # 5 minutes

  echo "Monitoring API calls for $container_name for $duration seconds..."

  docker exec "$container_name" sh -c "
    # Install tcpdump if available
    apk add --no-cache tcpdump 2>/dev/null || echo 'tcpdump not available'

    # Monitor network traffic
    timeout $duration tcpdump -i any -n host api.z.ai or host api.anthropic.com 2>/dev/null &

    # Alternatively, monitor with curl/test requests
    echo 'Testing authentication endpoint...'
    /usr/local/bin/claude --version
  "
}
```

#### Authentication Method Detection

```bash
# Test which authentication method is being used
detect_auth_method() {
  local container_name=$1

  docker exec "$container_name" sh -c "
    echo '=== Configuration Analysis ==='
    echo 'OAuth tokens present:'
    ls -la /root/.claude/.credentials.json 2>/dev/null && echo 'YES' || echo 'NO'

    echo 'Z.AI API configured:'
    grep -q 'api.z.ai' /root/.claude/settings.json 2>/dev/null && echo 'YES' || echo 'NO'

    echo '=== Authentication Test ==='
    # Try to authenticate and observe behavior
    echo 'Testing authentication...'
    timeout 30 /usr/local/bin/claude --help 2>&1 | head -10
  "
}
```

### Expected Results

**Test 2A (OAuth + API):**
- OAuth authentication should be used
- Network traffic should go to Anthropic OAuth endpoints
- Z.AI API configuration should be ignored

**Test 2B (API Only):**
- Z.AI API should be used for authentication
- Network traffic should go to api.z.ai
- Model should be glm-4.6

---

## 🔬 Experiment 3: Token Expiration and Refresh Mechanism

### Objective
Verify automatic token refresh functionality when OAuth tokens expire.

### Test Setup

#### Test 3A: Manual Token Expiration

```bash
# Create test environment with manipulated expiration
mkdir -p ~/claude-test-experiment/token-refresh
cd ~/claude-test-experiment/token-refresh

# Copy current valid tokens
mkdir -p test-credentials
cp ~/.claude/.credentials.json test-credentials/ 2>/dev/null || exit 1

# Manipulate expiration time (set to past)
python3 << 'EOF'
import json
import time

# Load current credentials
with open('test-credentials/.credentials.json', 'r') as f:
    creds = json.load(f)

# Set expiration to 1 hour ago
current_time = int(time.time() * 1000)
past_time = current_time - (60 * 60 * 1000)  # 1 hour ago

creds['claudeAiOauth']['expiresAt'] = past_time

# Save modified credentials
with open('test-credentials/.credentials.json', 'w') as f:
    json.dump(creds, f, indent=2)

print(f"Token expiration set to: {past_time}")
print(f"Current time: {current_time}")
print(f"Difference: {(current_time - past_time) / (1000*60*60):.1f} hours ago")
EOF

# Test container with expired token
docker run -d --name token-expired-test \
  -v $(pwd)/test-credentials:/root/.claude \
  -v $(pwd)/workspace:/workspace \
  -w /workspace \
  claude-code-docker:latest
```

### Validation

```bash
# Monitor token refresh behavior
monitor_refresh() {
  local container_name=$1

  echo "=== Initial Token State ==="
  docker exec "$container_name" cat /root/.claude/.credentials.json | jq '.claudeAiOauth.expiresAt'

  echo "=== Triggering Authentication ==="
  # Try to use Claude to trigger refresh
  docker exec "$container_name" timeout 60 /usr/local/bin/claude --version

  echo "=== Post-Authentication Token State ==="
  docker exec "$container_name" cat /root/.claude/.credentials.json | jq '.claudeAiOauth.expiresAt'

  echo "=== Refresh Log Analysis ==="
  docker logs "$container_name" 2>&1 | grep -i -E "(refresh|token|auth|oauth)"
}
```

### Expected Results

1. **Token Refresh**: Expired tokens should be automatically refreshed
2. **Continuity**: Session should continue without user intervention
3. **New Expiration**: `expiresAt` should be updated to future timestamp

---

## 🔬 Experiment 4: Container Identity Parameter Analysis

### Objective
Identify which container parameters are critical for authorization persistence.

### Test Matrix

#### Test 4A: Container Name Variations

```bash
# Test with different container names, same volumes
for name in claude-test-alpha claude-test-beta claude-test-gamma; do
  docker run -d --name "$name" \
    -v ~/claude-test-shared:/root/.claude \
    -v ~/workspace:/workspace \
    -w /workspace \
    claude-code-docker:latest

  echo "Testing container: $name"
  # Test authentication state
done
```

#### Test 4B: Environment Variable Variations

```bash
# Test different environment variables
docker run -d --name test-env-vars-1 \
  -v ~/claude-test-shared:/root/.claude \
  -e CLAUDE_CONFIG_DIR=/root/.claude \
  claude-code-docker:latest

docker run -d --name test-env-vars-2 \
  -v ~/claude-test-shared:/root/.claude \
  -e CLAUDE_CONFIG_DIR=/root/.claude \
  -e TZ=UTC \
  claude-code-docker:latest

docker run -d --name test-env-vars-3 \
  -v ~/claude-test-shared:/root/.claude \
  -e CUSTOM_CLAUDE_DIR=/root/.claude \
  claude-code-docker:latest
```

#### Test 4C: Volume Path Variations

```bash
# Test with slightly different volume paths
docker run -d --name test-volume-absolute \
  -v /home/user/claude-test:/root/.claude \
  claude-code-docker:latest

docker run -d --name test-volume-relative \
  -v ./claude-test:/root/.claude \
  claude-code-docker:latest

docker run -d --name test-volume-canonical \
  -v ~/claude-test:/root/.claude \
  claude-code-docker:latest
```

### Data Analysis

```bash
# Compare authentication states across variations
compare_auth_states() {
  local containers=("test-env-vars-1" "test-env-vars-2" "test-env-vars-3")

  for container in "${containers[@]}"; do
    echo "=== $container ==="

    # User ID
    docker exec "$container" cat /root/.claude/.claude.json 2>/dev/null | jq '.userID' || echo "No user ID"

    # Session ID
    docker exec "$container" cat /root/.claude/.claude.json 2>/dev/null | jq '.lastSessionId' || echo "No session ID"

    # Volume mapping
    docker inspect "$container" --format='{{range .Mounts}}{{.Source}}:{{.Destination}} {{end}}'

    echo ""
  done
}
```

---

## 🧪 Experiment 5: Multi-Container Isolation Strategies

### Objective
Validate different isolation strategies for multiple containers.

### Test Cases

#### Test 5A: Project-Based Isolation

```bash
# Create separate credentials per project
for project in project-alpha project-beta project-gamma; do
  mkdir -p "${project}/.claude"

  docker run -d --name "claude-${project}" \
    -v "./${project}/.claude:/root/.claude" \
    -v "./${project}:/workspace" \
    -w /workspace \
    claude-code-docker:latest
done
```

#### Test 5B: User-Based Isolation

```bash
# Simulate different user contexts
for user in user-dev user-staging user-prod; do
  mkdir -p "users/${user}/.claude"

  docker run -d --name "claude-${user}" \
    -v "./users/${user}/.claude:/root/.claude" \
    -e USER_CONTEXT="${user}" \
    claude-code-docker:latest
done
```

### Isolation Validation

```bash
# Verify isolation between containers
verify_isolation() {
  local container1=$1
  local container2=$2

  # Get user IDs
  local uid1=$(docker exec "$container1" cat /root/.claude/.claude.json 2>/dev/null | jq -r '.userID // "null"')
  local uid2=$(docker exec "$container2" cat /root/.claude/.claude.json 2>/dev/null | jq -r '.userID // "null"')

  # Get session IDs
  local sid1=$(docker exec "$container1" cat /root/.claude/.claude.json 2>/dev/null | jq -r '.lastSessionId // "null"')
  local sid2=$(docker exec "$container2" cat /root/.claude/.claude.json 2>/dev/null | jq -r '.lastSessionId // "null"')

  echo "Isolation Analysis: $container1 vs $container2"
  echo "User IDs: $uid1 vs $uid2"
  echo "Session IDs: $sid1 vs $sid2"

  if [[ "$uid1" != "$uid2" ]] && [[ "$sid1" != "$sid2" ]]; then
    echo "✅ ISOLATION CONFIRMED"
  else
    echo "❌ ISOLATION FAILED"
  fi
}
```

---

## 📊 Data Collection and Analysis

### Automated Data Collection Script

```bash
#!/bin/bash
# collect-experiment-data.sh

EXPERIMENT_DIR="$HOME/claude-test-experiments"
RESULTS_DIR="$EXPERIMENT_DIR/results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$RESULTS_DIR/$TIMESTAMP"

collect_container_data() {
  local container=$1
  local result_dir="$RESULTS_DIR/$TIMESTAMP/$container"

  mkdir -p "$result_dir"

  echo "Collecting data for $container..."

  # Container info
  docker inspect "$container" > "$result_dir/container-info.json"

  # Authentication files
  docker exec "$container" cat /root/.claude/.credentials.json > "$result_dir/credentials.json" 2>/dev/null || echo "No credentials"
  docker exec "$container" cat /root/.claude/.claude.json > "$result_dir/claude.json" 2>/dev/null || echo "No claude.json"
  docker exec "$container" cat /root/.claude/settings.json > "$result_dir/settings.json" 2>/dev/null || echo "No settings"

  # Environment
  docker exec "$container" env > "$result_dir/environment.txt"

  # Network info
  docker exec "$container" ip addr > "$result_dir/network.txt"

  # Processes
  docker exec "$container" ps aux > "$result_dir/processes.txt"

  # Logs
  docker logs "$container" > "$result_dir/container.log" 2>&1
}

# Collect data from all test containers
for container in $(docker ps --format "table {{.Names}}" | grep -v NAMES); do
  if [[ "$container" =~ test|experiment ]]; then
    collect_container_data "$container"
  fi
done

echo "Data collection completed: $RESULTS_DIR/$TIMESTAMP"
```

### Analysis Framework

```python
#!/usr/bin/env python3
# analyze-experiment-results.py

import json
import os
from pathlib import Path
from datetime import datetime

class ExperimentAnalyzer:
    def __init__(self, results_dir):
        self.results_dir = Path(results_dir)
        self.experiments = {}

    def load_experiment_data(self):
        """Load all experiment data"""
        for experiment_dir in self.results_dir.iterdir():
            if experiment_dir.is_dir():
                self.experiments[experiment_dir.name] = self.load_container_data(experiment_dir)

    def load_container_data(self, experiment_dir):
        """Load data for a single experiment"""
        containers = {}

        for container_dir in experiment_dir.iterdir():
            if container_dir.is_dir():
                containers[container_dir.name] = {
                    'credentials': self.load_json(container_dir / 'credentials.json'),
                    'claude_config': self.load_json(container_dir / 'claude.json'),
                    'settings': self.load_json(container_dir / 'settings.json'),
                    'container_info': self.load_json(container_dir / 'container-info.json'),
                    'environment': self.load_text(container_dir / 'environment.txt'),
                    'network': self.load_text(container_dir / 'network.txt')
                }

        return containers

    def analyze_authentication_sharing(self):
        """Analyze which containers share authentication"""
        auth_groups = {}

        for exp_name, containers in self.experiments.items():
            for cont_name, data in containers.items():
                user_id = data.get('claude_config', {}).get('userID', 'unknown')

                if user_id not in auth_groups:
                    auth_groups[user_id] = []

                auth_groups[user_id].append({
                    'experiment': exp_name,
                    'container': cont_name,
                    'data': data
                })

        return auth_groups

    def analyze_volume_mapping_patterns(self):
        """Analyze volume mapping patterns and their relation to auth sharing"""
        patterns = {}

        for exp_name, containers in self.experiments.items():
            for cont_name, data in containers.items():
                volumes = data.get('container_info', [{}])[0].get('Mounts', [])
                volume_signature = self.create_volume_signature(volumes)

                if volume_signature not in patterns:
                    patterns[volume_signature] = []

                patterns[volume_signature].append({
                    'experiment': exp_name,
                    'container': cont_name,
                    'volumes': volumes,
                    'user_id': data.get('claude_config', {}).get('userID', 'unknown')
                })

        return patterns

    def create_volume_signature(self, volumes):
        """Create unique signature for volume mapping pattern"""
        signature_parts = []

        for volume in volumes:
            if volume.get('Destination') == '/root/.claude':
                source = volume.get('Source', '')
                signature_parts.append(f"claude:{source}")

        return '|'.join(sorted(signature_parts))

    def generate_report(self):
        """Generate comprehensive experiment report"""
        self.load_experiment_data()

        report = {
            'timestamp': datetime.now().isoformat(),
            'experiments_count': len(self.experiments),
            'authentication_groups': self.analyze_authentication_sharing(),
            'volume_patterns': self.analyze_volume_mapping_patterns()
        }

        return report

if __name__ == "__main__":
    analyzer = ExperimentAnalyzer("./results")
    report = analyzer.generate_report()

    print(json.dumps(report, indent=2))
```

---

## 🎯 Success Criteria

### Primary Validation Goals

1. **Volume Mapping Identity**: 95%+ confidence that identical volume mappings share authentication
2. **OAuth Priority**: 99%+ confidence that OAuth tokens override Z.AI API settings
3. **Token Refresh**: 90%+ confidence in automatic token refresh functionality
4. **Isolation Strategies**: 85%+ confidence in isolation mechanisms

### Secondary Validation Goals

1. **Performance Impact**: Measure authentication overhead
2. **Security Boundaries**: Validate isolation effectiveness
3. **Cross-Platform**: Verify compatibility across different systems

---

## 📅 Timeline

### Week 1: Core Experiments
- Day 1-2: Volume mapping identity verification
- Day 3-4: OAuth vs API priority testing
- Day 5-7: Token expiration and refresh testing

### Week 2: Advanced Analysis
- Day 8-10: Container identity parameter analysis
- Day 11-12: Multi-container isolation strategies
- Day 13-14: Data analysis and report generation

### Week 3: Validation and Documentation
- Day 15-17: Cross-validation experiments
- Day 18-19: Final report compilation
- Day 20-21: Documentation updates

---

## ⚠️ Safety and Security Considerations

### Isolation
- All experiments run in isolated test environments
- No production credentials used in testing
- Container cleanup procedures in place

### Data Protection
- Sensitive tokens masked in logs
- Test data encrypted at rest
- Temporary data cleanup after experiments

### Network Safety
- Limited network access during experiments
- API usage monitoring and rate limiting
- No external service dependencies

---

## 📋 Expected Deliverables

1. **Experiment Results Data**: Raw data from all experiments
2. **Analysis Report**: Comprehensive findings with confidence levels
3. **Validation Scripts**: Reproducible test automation
4. **Updated Documentation**: Research validation and corrections
5. **Best Practices Guide**: Production deployment recommendations

---

**Experiment Readiness**: ✅ Waiting for execution approval
**Estimated Duration**: 15-21 days
**Resource Requirements**: Docker environment, test directories, monitoring tools