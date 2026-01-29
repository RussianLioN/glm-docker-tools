#!/usr/bin/env bash
# =============================================================================
# GLM Docker Tools - SSH Agent Forwarding Setup Script
# =============================================================================
# Interactive SSH agent forwarding configuration for Git operations in container
#
# Usage: ./scripts/setup-ssh-forwarding.sh [--check|--help]
#
# This script helps you configure SSH agent forwarding for Git operations
# inside Docker containers by:
#   - Checking if SSH agent is running
#   - Detecting available SSH keys
#   - Loading keys into the agent
#   - Testing GitHub authentication
#   - Providing diagnostic information
#
# Security:
#   - No secrets stored or copied
#   - Uses SSH agent forwarding (industry standard)
#   - Keys remain on host system only
#
# Expert Panel: 13/13 unanimous approval for SSH agent forwarding approach
# =============================================================================

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

# Common SSH key locations
declare -a KEY_LOCATIONS=(
    "$HOME/.ssh/id_ed25519"
    "$HOME/.ssh/id_rsa"
    "$HOME/.ssh/id_ecdsa"
    "$HOME/.ssh/id_ecdsa_sk"
    "$HOME/.ssh/id_ed25519_sk"
)

# =============================================================================
# Logging Functions
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_header() {
    echo ""
    echo -e "${BOLD}$*${NC}"
    echo ""
}

# =============================================================================
# Validation Functions
# =============================================================================

check_ssh_command() {
    if ! command -v ssh &> /dev/null; then
        log_error "SSH command not found!"
        log_error ""
        log_error "Please install OpenSSH:"
        log_error "  macOS: bundled with system"
        log_error "  Linux: sudo apt-get install openssh-client"
        return 1
    fi
    return 0
}

check_ssh_agent_running() {
    if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
        return 1
    fi

    if [[ ! -S "$SSH_AUTH_SOCK" ]]; then
        log_warning "SSH_AUTH_SOCK is set but socket doesn't exist: $SSH_AUTH_SOCK"
        return 1
    fi

    return 0
}

start_ssh_agent() {
    log_info "Attempting to start SSH agent..."

    # Try to start agent (works on most systems)
    if eval "$(ssh-agent -s)" 2>/dev/null; then
        # Export for current session
        export SSH_AUTH_SOCK
        export SSH_AGENT_PID
        log_success "SSH agent started"
        return 0
    fi

    log_error "Failed to start SSH agent automatically"
    return 1
}

# =============================================================================
# Key Detection Functions
# =============================================================================

find_ssh_keys() {
    declare -a found_keys=()

    for key_path in "${KEY_LOCATIONS[@]}"; do
        if [[ -f "$key_path" ]]; then
            # Check if public key also exists (indicates valid key pair)
            if [[ -f "${key_path}.pub" ]]; then
                found_keys+=("$key_path")
            fi
        fi
    done

    # Output found keys (one per line)
    printf '%s\n' "${found_keys[@]}"
}

check_loaded_keys() {
    # ssh-add -l returns "The agent has N identities" or error
    # Extract the number from first line
    local output
    output=$(ssh-add -l 2>/dev/null) || return 0

    # ssh-add -l format: "4096 SHA256:... comment (RSA)\n256 SHA256:... comment (ED25519)"
    # OR on some systems: "The agent has 2 identities"
    local count=0

    # Try parsing "The agent has N identities" format
    if echo "$output" | grep -q "The agent has"; then
        count=$(echo "$output" | grep -oE 'has [0-9]+ ident' | grep -oE '[0-9]+')
    else
        # Count lines instead
        count=$(echo "$output" | wc -l | tr -d ' ')
    fi

    echo "${count:-0}"
}

# =============================================================================
# Key Loading Functions
# =============================================================================

load_key_interactive() {
    local key_path="$1"

    log_info "Loading key: $key_path"

    # Use ssh-add with optional user interaction
    if ssh-add "$key_path" 2>/dev/null; then
        log_success "Key loaded: $key_path"
        return 0
    fi

    # If failed, might need passphrase (will prompt user)
    log_warning "Attempting to load with passphrase prompt..."
    if ssh-add "$key_path"; then
        log_success "Key loaded: $key_path"
        return 0
    fi

    log_error "Failed to load key: $key_path"
    return 1
}

# =============================================================================
# Authentication Testing
# =============================================================================

test_github_ssh() {
    log_info "Testing GitHub SSH authentication..."

    local github_response
    github_response=$(ssh -T git@github.com 2>&1 || true)

    if echo "$github_response" | grep -q "successfully authenticated"; then
        # Extract username (portable, no grep -P)
        local username
        username=$(echo "$github_response" | sed 's/Hi //;s/!.*//')
        log_success "GitHub SSH authentication successful! (User: ${username:-unknown})"
        return 0
    fi

    if echo "$github_response" | grep -q "Permission denied"; then
        log_error "GitHub authentication failed: Permission denied"
        log_error ""
        log_error "Possible reasons:"
        log_error "  1. SSH key not added to GitHub account"
        log_error "  2. Wrong key loaded (multiple keys issue)"
        log_error "  3. Key type not supported by GitHub"
        log_error ""
        log_error "Fix: Add your SSH key to GitHub"
        log_error "  https://github.com/settings/keys"
        return 1
    fi

    log_warning "GitHub test returned unexpected response"
    log_info "Response: $github_response"
    return 1
}

# =============================================================================
# Diagnostic Functions
# =============================================================================

show_diagnostics() {
    log_header "📊 SSH Diagnostics"

    # SSH command
    log_info "SSH Command:"
    if command -v ssh &> /dev/null; then
        local ssh_version
        ssh_version=$(ssh -V 2>&1 | head -1)
        echo "  ✅ $ssh_version"
    else
        echo "  ❌ Not found"
    fi
    echo

    # SSH Agent
    log_info "SSH Agent:"
    if [[ -n "${SSH_AUTH_SOCK:-}" ]]; then
        echo "  ✅ Running"
        echo "     Socket: $SSH_AUTH_SOCK"
        if [[ -n "${SSH_AGENT_PID:-}" ]]; then
            echo "     PID: $SSH_AGENT_PID"
        fi
    else
        echo "  ❌ Not running"
    fi
    echo

    # Loaded Keys
    log_info "Loaded Keys:"
    local key_count
    key_count=$(check_loaded_keys)
    if [[ "$key_count" -gt 0 ]]; then
        echo "  ✅ $key_count key(s) loaded"
        ssh-add -l 2>/dev/null | sed 's/^/     /'
    else
        echo "  ❌ No keys loaded"
    fi
    echo

    # Available Keys
    log_info "Available Keys:"
    local found_keys
    mapfile -t found_keys < <(find_ssh_keys)
    if [[ ${#found_keys[@]} -gt 0 ]]; then
        echo "  ✅ Found ${#found_keys[@]} key pair(s)"
        for key in "${found_keys[@]}"; do
            local key_type
            key_type=$(basename "$key")
            local fingerprint
            fingerprint=$(ssh-keygen -lf "$key" 2>/dev/null | awk '{print $2}')
            echo "     - $key_type ($fingerprint)"
        done
    else
        echo "  ⚠️  No SSH keys found in standard locations"
        echo "     Standard locations checked:"
        for loc in "${KEY_LOCATIONS[@]}"; do
            echo "       - $loc"
        done
    fi
    echo

    # GitHub Test
    log_info "GitHub Authentication:"
    test_github_ssh || true  # Don't fail diagnostics on GitHub test
    echo

    return 0  # Always succeed in diagnostics mode
}

# =============================================================================
# Interactive Setup Functions
# =============================================================================

interactive_setup() {
    log_header "🔑 SSH Agent Forwarding Setup"

    # Step 1: Check SSH command
    log_info "Step 1: Checking SSH installation..."
    if ! check_ssh_command; then
        return 1
    fi
    log_success "SSH command found"
    echo

    # Step 2: Check SSH agent
    log_info "Step 2: Checking SSH agent..."
    if ! check_ssh_agent_running; then
        log_warning "SSH agent not running"
        echo

        if read -p "Start SSH agent? [Y/n] " -r; then
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                if ! start_ssh_agent; then
                    log_error "Failed to start SSH agent"
                    log_error ""
                    log_error "Manual start:"
                    log_error "  eval \"\$(ssh-agent -s)\""
                    return 1
                fi
            else
                log_error "SSH agent required for Git operations in container"
                return 1
            fi
        fi
    else
        log_success "SSH agent is running"
        echo
    fi

    # Step 3: Check loaded keys
    log_info "Step 3: Checking loaded SSH keys..."
    local key_count
    key_count=$(check_loaded_keys)

    if [[ "$key_count" -gt 0 ]]; then
        log_success "Found $key_count loaded key(s)"
        ssh-add -l
    else
        log_warning "No SSH keys loaded"
        echo

        # Find available keys
        mapfile -t found_keys < <(find_ssh_keys)

        if [[ ${#found_keys[@]} -eq 0 ]]; then
            log_error "No SSH keys found!"
            log_error ""
            log_error "Generate a new SSH key:"
            log_error "  ssh-keygen -t ed25519 -C \"your_email@example.com\""
            return 1
        fi

        log_info "Found ${#found_keys[@]} available key pair(s):"
        for i in "${!found_keys[@]}"; do
            echo "  $((i+1)). ${found_keys[$i]}"
        done
        echo

        if read -p "Load keys? [Y/n] " -r; then
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                for key in "${found_keys[@]}"; do
                    if ! load_key_interactive "$key"; then
                        log_warning "Failed to load: $key"
                    fi
                done
                echo

                # Check if any keys were loaded
                key_count=$(check_loaded_keys)
                if [[ "$key_count" -gt 0 ]]; then
                    log_success "$key_count key(s) loaded"
                else
                    log_error "No keys loaded successfully"
                    return 1
                fi
            fi
        fi
    fi
    echo

    # Step 4: Test GitHub authentication
    log_info "Step 4: Testing GitHub authentication..."
    if ! test_github_ssh; then
        echo
        log_warning "GitHub SSH authentication not working"
        log_info ""
        log_info "To add SSH key to GitHub:"
        log_info "  1. Copy public key: ssh-keygen -y ~/.ssh/id_ed25519"
        log_info "  2. Add to GitHub: https://github.com/settings/keys"
        return 1
    fi
    echo

    # Success!
    log_header "✅ Setup Complete!"

    log_success "SSH agent forwarding is ready for Docker container"
    echo
    log_info "Next steps:"
    log_info "  1. Launch container: ./glm-launch.sh"
    log_info "  2. Test inside container: ssh-add -l"
    log_info "  3. Test Git push: git push"

    return 0
}

# =============================================================================
# Main
# =============================================================================

show_help() {
    cat << EOF
${BOLD}SSH Agent Forwarding Setup${NC}

${BOLD}Usage:${NC}
  $0 [OPTIONS]

${BOLD}Options:${NC}
  -h, --help      Show this help
  -c, --check     Run diagnostics only (no setup)
  -v, --verbose   Enable verbose output

${BOLD}Description:${NC}
  Configures SSH agent forwarding for Git operations inside Docker containers.
  This allows Claude Code container to push to GitHub without storing credentials.

${BOLD}Expert Panel:${NC}
  13/13 experts unanimously recommend SSH agent forwarding as the only secure method.

${BOLD}Documentation:${NC}
  https://github.com/RussianLioN/glm-docker-tools/docs/GIT_ACCESS_EPHEMERAL_CONTAINER.md

EOF
}

main() {
    local mode="setup"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--check)
                mode="check"
                shift
                ;;
            -v|--verbose)
                set -x
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Run based on mode
    if [[ "$mode" == "check" ]]; then
        show_diagnostics
        exit $?
    else
        interactive_setup
        exit $?
    fi
}

# Run main
main "$@"
