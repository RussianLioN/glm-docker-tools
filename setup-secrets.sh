#!/bin/bash
# =============================================================================
# GLM Docker Tools - Secrets Setup Script
# =============================================================================
# Interactive API key configuration for GLM Docker Tools
#
# Usage: ./setup-secrets.sh
#
# This script helps you securely configure your GLM API key by:
#   - Prompting for your API key interactively
#   - Validating the key format
#   - Saving it to secrets/.env with secure permissions
#   - Providing clear feedback throughout the process
#
# Security:
#   - All secrets stored in secrets/.env (gitignored)
#   - File permissions set to 600 (owner read/write only)
#   - Atomic write operation (.tmp + mv)
# =============================================================================

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

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

# =============================================================================
# Validation Functions
# =============================================================================

validate_terminal() {
    # Check if running in an interactive terminal
    if [[ ! -t 0 ]]; then
        log_error "Not running in an interactive terminal!"
        log_error ""
        log_error "This script requires an interactive terminal to input your API key."
        log_error ""
        log_error "Alternative: Create secrets/.env manually:"
        log_error "  mkdir -p secrets"
        log_error "  echo 'GLM_API_KEY=your_key_here' > secrets/.env"
        log_error "  chmod 600 secrets/.env"
        return 1
    fi

    # Check if /dev/tty is accessible
    if [[ ! -c /dev/tty ]] || [[ ! -r /dev/tty ]]; then
        log_error "Cannot access /dev/tty for interactive input!"
        return 1
    fi

    return 0
}

validate_api_key_format() {
    local key="$1"

    # Check minimum length (Z.AI keys are typically 32+ chars)
    if [[ ${#key} -lt 32 ]]; then
        log_warning "API key appears too short (${#key} chars, expected 32+)"
        return 1
    fi

    # Check for common invalid characters
    if [[ "$key" =~ [[:space:]] ]]; then
        log_error "API key contains whitespace characters!"
        return 1
    fi

    return 0
}

# =============================================================================
# Input Functions
# =============================================================================

prompt_for_api_key() {
    local api_key=""

    log_info ""
    log_info "Get your API key from: ${BOLD}https://z.ai/settings/api-keys${NC}"
    log_info ""

    # Read from /dev/tty to avoid any stdin contamination
    echo -n "Enter your GLM API key: " > /dev/tty
    read -r api_key < /dev/tty

    # Validate input
    if [[ -z "$api_key" ]]; then
        log_error "No API key entered!"
        return 1
    fi

    # Validate format
    if ! validate_api_key_format "$api_key"; then
        echo "" > /dev/tty
        echo -n "Continue anyway? [y/N]: " > /dev/tty
        read -r confirm < /dev/tty

        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            log_error "Setup cancelled."
            return 1
        fi
    fi

    echo "$api_key"
    return 0
}

# =============================================================================
# Write Functions
# =============================================================================

write_secrets_file() {
    local api_key="$1"
    local secrets_dir="secrets"
    local secrets_file="$secrets_dir/.env"
    local tmp_file="$secrets_file.tmp"

    # Create secrets directory
    if [[ ! -d "$secrets_dir" ]]; then
        mkdir -p "$secrets_dir"
        log_info "Created secrets directory"
    fi

    # Check if file already exists
    if [[ -f "$secrets_file" ]]; then
        log_warning "secrets/.env already exists!"
        echo "" > /dev/tty
        echo -n "Overwrite? [y/N]: " > /dev/tty
        read -r overwrite < /dev/tty

        if [[ "$overwrite" != "y" && "$overwrite" != "Y" ]]; then
            log_info "Keeping existing secrets file"
            return 0
        fi
        log_info "Overwriting secrets file"
    fi

    # Atomic write: write to .tmp first, then mv
    cat > "$tmp_file" <<EOF
# GLM API Key Configuration
# ========================
# This file contains your GLM API key for Claude Code
# IMPORTANT: Never commit this file to Git!

# Your Z.AI API key
GLM_API_KEY=$api_key

# Alternative variable name (both work):
# ANTHROPIC_AUTH_TOKEN=$api_key
EOF

    # Set secure permissions
    chmod 600 "$tmp_file"

    # Atomic move
    mv "$tmp_file" "$secrets_file"

    log_success "API key saved to $secrets_file"
    log_info "File permissions: 600 (owner read/write only)"
}

# =============================================================================
# Main
# =============================================================================

main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║     GLM Docker Tools - Secrets Setup                           ║"
    echo "║     Interactive API Key Configuration                          ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    # Step 1: Validate terminal
    if ! validate_terminal; then
        exit 1
    fi

    # Step 2: Prompt for API key
    local api_key
    if ! api_key=$(prompt_for_api_key); then
        exit 1
    fi

    # Step 3: Write to secrets file
    if ! write_secrets_file "$api_key"; then
        exit 1
    fi

    # Success message
    echo ""
    log_success "✅ Setup complete!"
    echo ""
    log_info "Next steps:"
    log_info "  1. Your API key is stored in secrets/.env"
    log_info "  2. This file is gitignored (safe from commits)"
    log_info "  3. Run ${BOLD}./glm-launch.sh${NC} to start Claude Code"
    echo ""
}

# Run main
main "$@"
