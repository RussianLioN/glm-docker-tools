#!/usr/bin/env bash
# setup-aliases.sh - Auto-setup GLM aliases for system-wide access
# Usage: ./setup-aliases.sh [--install|--install-system|--check|--uninstall]
#
# P13: Setup script for shell aliases
# Expert panel: 13/13 unanimous approval
# Architecture: FPATH auto-discovery (no ~/.zshrc modification)

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ALIASES_FILE="$SCRIPT_DIR/glm-aliases.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# =============================================================================
# Logging Functions
# =============================================================================

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# =============================================================================
# Prerequisites Check
# =============================================================================

check_prerequisites() {
    log_info "Checking prerequisites..."

    if [[ ! -f "$ALIASES_FILE" ]]; then
        log_error "Aliases file not found: $ALIASES_FILE"
        return 1
    fi

    if [[ ! -f "$PROJECT_ROOT/glm-launch.sh" ]]; then
        log_error "Launcher script not found: $PROJECT_ROOT/glm-launch.sh"
        return 1
    fi

    log_success "✅ Prerequisites check passed"
    return 0
}

# =============================================================================
# Shell Detection
# =============================================================================

detect_shell() {
    # P13: Use $SHELL environment variable (user's login shell)
    # This is more reliable than $ZSH_VERSION/$BASH_VERSION (which show subprocess)
    local user_shell="${SHELL:-}"

    if [[ -z "$user_shell" ]]; then
        # Fallback: check version variables
        if [[ -n "${ZSH_VERSION:-}" ]]; then
            echo "zsh"
        elif [[ -n "${BASH_VERSION:-}" ]]; then
            echo "bash"
        else
            echo "unknown"
        fi
        return 0
    fi

    # Extract shell name from path (e.g., /bin/zsh → zsh)
    local shell_name
    shell_name="$(basename "$user_shell")"

    case "$shell_name" in
        zsh)
            echo "zsh"
            ;;
        bash)
            echo "bash"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# =============================================================================
# Installation Functions
# =============================================================================

# Install for Zsh (FPATH method)
install_zsh() {
    log_info "Installing for Zsh (FPATH method)..."

    local fpath_dir="/usr/local/share/zsh/site-functions"
    local target_func="$fpath_dir/glm"
    local target_comp="$fpath_dir/_glm"

    # Check write permissions
    if [[ ! -d "$fpath_dir" ]] && ! mkdir -p "$fpath_dir" 2>/dev/null; then
        log_warning "No write permission to $fpath_dir"
        log_info "Try with sudo: sudo ./setup-aliases.sh --install"
        return 1
    fi

    # Create directory if needed
    if [[ ! -d "$fpath_dir" ]]; then
        mkdir -p "$fpath_dir" || {
            log_error "Cannot create $fpath_dir"
            return 1
        }
    fi

    # Backup existing files
    if [[ -f "$target_func" ]]; then
        local backup="${target_func}.bak.$(date +%s)"
        cp "$target_func" "$backup"
        log_info "Backed up existing $target_func to $backup"
    fi

    # Copy alias file as function (FPATH naming convention)
    # Replace ONLY the assignment line (not the comparison in if statement)
    sed 's|local installed_path="__GLM_INSTALLED_PATH__"|local installed_path="'"$PROJECT_ROOT"'"|g' "$ALIASES_FILE" > "$target_func"
    chmod +x "$target_func"

    # Create completion file
    cat > "$target_comp" <<'EOF'
#compdef _glm
#autoload completion
_glm() {
    local -a commands
    commands=(
        'glm:Standard launch (auto-delete container)'
        'glm-debug:Debug mode (persistent container + shell access)'
        'glm-no-del:No-delete mode (persistent container)'
        'glm-help:Show help'
    )
    if (( CURRENT == 1 )); then
        _describe 'command' "GLM commands"
    else
        case "$words[1]" in
            glm)
                _message "Standard launch (auto-delete container)"
                ;;
            glm-debug)
                _message "Debug mode (persistent container + shell access)"
                ;;
            glm-no-del)
                _message "No-delete mode (persistent container)"
                ;;
            glm-help)
                _message "Show help"
                ;;
        esac
    fi
}
_glm "@"
EOF

    log_success "✅ Installed to $fpath_dir"
    log_info ""
    log_info "To enable aliases, restart your shell or run:"
    log_info "  exec zsh"
    log_info ""
    log_info "Or force reload in current shell:"
    log_info "  autoload -U compinit && compinit"

    return 0
}

# Install for Bash (completion method)
install_bash() {
    log_info "Installing for Bash (completion method)..."

    local comp_dir="$HOME/.local/share/bash-completion/completions"
    local target="$comp_dir/glm"

    # Create directory if needed
    mkdir -p "$comp_dir"

    # Backup existing
    if [[ -f "$target" ]]; then
        local backup="${target}.bak.$(date +%s)"
        cp "$target" "$backup"
        log_info "Backed up existing $target to $backup"
    fi

    # Copy aliases file with placeholder substitution
    sed 's|local installed_path="__GLM_INSTALLED_PATH__"|local installed_path="'"$PROJECT_ROOT"'"|g' "$ALIASES_FILE" > "$target"
    chmod +x "$target"

    log_success "✅ Installed to $target"
    log_info ""
    log_info "To enable aliases, restart your shell or run:"
    log_info "  exec bash"
    log_info ""
    log_info "Or source directly in current shell:"
    log_info "  source $target"

    return 0
}

# Install system-wide (profile.d)
install_system() {
    log_info "Installing system-wide (requires sudo)..."

    if [[ $EUID -ne 0 ]]; then
        log_error "This option requires sudo. Run: sudo ./setup-aliases.sh --install-system"
        return 1
    fi

    local target="/etc/profile.d/glm-aliases.sh"

    # Backup existing
    if [[ -f "$target" ]]; then
        local backup="${target}.bak.$(date +%s)"
        cp "$target" "$backup"
        log_info "Backed up existing $target to $backup"
    fi

    # Copy with project root substitution for robustness
    sed "s|%%PROJECT_ROOT%%|$PROJECT_ROOT|g" "$ALIASES_FILE" > "$target"
    chmod +x "$target"

    log_success "✅ Installed to $target"
    log_info ""
    log_info "Aliases will be available in new shell sessions for all users"

    return 0
}

# =============================================================================
# Status Check
# =============================================================================

check_installation() {
    log_info "Checking installation status..."

    local installed=false
    local shell=$(detect_shell)

    case "$shell" in
        zsh)
            if [[ -f "/usr/local/share/zsh/site-functions/glm" ]]; then
                log_success "✅ Installed for Zsh (FPATH)"
                installed=true
            fi
            ;;
        bash)
            if [[ -f "$HOME/.local/share/bash-completion/completions/glm" ]]; then
                log_success "✅ Installed for Bash (completion)"
                installed=true
            fi
            ;;
    esac

    if [[ -f "/etc/profile.d/glm-aliases.sh" ]]; then
        log_success "✅ Installed system-wide (profile.d)"
        installed=true
    fi

    if [[ "$installed" == "false" ]]; then
        log_warning "❌ Not installed"
        log_info "Run: ./scripts/setup-aliases.sh --install"
    fi

    return 0
}

# =============================================================================
# Main Function
# =============================================================================

main() {
    # Check prerequisites first
    check_prerequisites || exit 1

    local action="${1:---install}"
    local shell=$(detect_shell)

    log_info "Detected shell: $shell"
    log_info "Project root: $PROJECT_ROOT"
    log_info "Aliases file: $ALIASES_FILE"
    echo ""

    case "$action" in
        --install)
            case "$shell" in
                zsh)
                    install_zsh
                    ;;
                bash)
                    install_bash
                    ;;
                *)
                    log_error "Unknown shell: $shell"
                    log_info ""
                    log_info "Manual installation:"
                    log_info "  Add to your shell config (~/.zshrc or ~/.bashrc):"
                    log_info "  source $ALIASES_FILE"
                    exit 1
                    ;;
            esac
            ;;
        --install-system)
            install_system
            ;;
        --check)
            check_installation
            ;;
        --uninstall)
            log_error "Uninstall not implemented yet"
            log_info "Manual removal required:"
            log_info "  Zsh:  rm /usr/local/share/zsh/site-functions/glm"
            log_info "  Bash: rm ~/.local/share/bash-completion/completions/glm"
            log_info "  System: sudo rm /etc/profile.d/glm-aliases.sh"
            exit 1
            ;;
        *)
            log_error "Unknown action: $action"
            log_info ""
            log_info "Usage: $0 [--install|--install-system|--check|--uninstall]"
            log_info ""
            log_info "Options:"
            log_info "  --install         Auto-install for current shell (zsh/bash)"
            log_info "  --install-system  Install system-wide (requires sudo)"
            log_info "  --check            Check installation status"
            log_info "  --uninstall        Uninstall aliases"
            exit 1
            ;;
    esac
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
