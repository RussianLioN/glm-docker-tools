#!/usr/bin/env bash
# glm-aliases.sh - Shell functions for Claude Code launcher
# Source this file or use setup-aliases.sh for auto-installation
# Supports: bash 4+, zsh 5+
#
# P13: Shell-aliases for universal Claude Code access
# Expert panel: 13/13 unanimous approval
# Architecture: Auto-detection via BASH_SOURCE/zsh %x (works from any directory)

# =============================================================================
# P13 Core Function: Find Project Root (AUTO-DETECTION)
# Purpose: Find glm-docker-tools project automatically
# Priority: 1. GLM_PROJECT_ROOT (env var) -> 2. Script location -> 3. Search upward
# Returns: Project root path or empty string if not found
# =============================================================================
_glm_find_project_root() {
    # =============================================================================
    # Level 1: Environment Variable Override (Highest Priority)
    # Purpose: Allow user to override project root at runtime
    # Usage: export GLM_PROJECT_ROOT=~/custom/path/to/glm-docker-tools
    # =============================================================================
    if [[ -n "${GLM_PROJECT_ROOT:-}" ]]; then
        # Validate the path exists and contains glm-launch.sh (most specific marker)
        if [[ -d "$GLM_PROJECT_ROOT" ]] && \
           [[ -f "$GLM_PROJECT_ROOT/glm-launch.sh" ]]; then
            echo "$GLM_PROJECT_ROOT"
            return 0
        else
            # Path is invalid - warn but continue to next level
            echo "⚠️  GLM: GLM_PROJECT_ROOT is set but invalid: $GLM_PROJECT_ROOT" >&2
            echo "   Falling back to other methods..." >&2
        fi
    fi

    # =============================================================================
    # Level 2: Script Location (Auto-detection from file path)
    # Purpose: Use the location of this script (glm-aliases.sh) to find project root
    # This works because glm-aliases.sh is in scripts/ subdirectory of project
    # Supports both bash (${BASH_SOURCE[0]}) and zsh (${(%):-%x})
    # =============================================================================
    local script_dir=""

    # Try bash method first
    if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
        script_dir="${BASH_SOURCE[0]}"
    # Try zsh method
    elif [[ -n "${(%):-%x}" ]]; then
        script_dir="${(%):-%x}"
    # Try funcsourcetrace (zsh fallback)
    elif [[ -n "${funcsourcetrace[1]:-}" ]]; then
        script_dir="${funcsourcetrace[1]}"
    fi

    if [[ -n "$script_dir" ]]; then
        # Get absolute path of script directory
        script_dir="$(cd "$(dirname "$script_dir")" && pwd)"
        # Project root is parent of scripts/ directory
        local project_root="$(dirname "$script_dir")"

        # Validate the path exists and contains glm-launch.sh
        if [[ -d "$project_root" ]] && \
           [[ -f "$project_root/glm-launch.sh" ]]; then
            echo "$project_root"
            return 0
        fi
    fi

    # =============================================================================
    # Level 3: Upward Search (Fallback - Last Resort)
    # Purpose: Find project by searching upward from current directory
    # Note: Only works if user is inside glm-docker-tools or subdirectory
    # IMPORTANT: Only checks for glm-launch.sh (most specific marker)
    #           to avoid false positives from other projects with .git or Dockerfile
    # =============================================================================
    local current_dir="$(pwd)"

    while [[ "$current_dir" != "/" ]]; do
        # Check ONLY for glm-launch.sh (most specific marker for our project)
        if [[ -f "$current_dir/glm-launch.sh" ]]; then
            echo "$current_dir"
            return 0
        fi

        # Move up one directory
        current_dir="$(dirname "$current_dir")"
    done

    # =============================================================================
    # All Levels Failed: Return Error
    # =============================================================================
    return 1
}

# =============================================================================
# P13 Main Launcher: Internal function
# Purpose: Find project root and launch glm-launch.sh with all arguments
# Arguments: All glm-launch.sh arguments (passed via "$@")
# Returns: Exit code from glm-launch.sh
# =============================================================================
_glm() {
    local project_root

    # Find project root using 3-level fallback
    project_root="$(_glm_find_project_root)"

    if [[ -z "$project_root" ]]; then
        cat >&2 <<'EOF'
❌ GLM: Project root not found

💡 To fix:
   1. Navigate into your glm-docker-tools project directory
   2. Or set environment variable:
      export GLM_PROJECT_ROOT=~/path/to/glm-docker-tools
   3. Or re-run installation:
      cd ~/path/to/glm-docker-tools
      ./scripts/setup-aliases.sh --install

EOF
        return 1
    fi

    local launcher="$project_root/glm-launch.sh"

    # Check launcher exists
    if [[ ! -f "$launcher" ]]; then
        echo "❌ GLM: Launcher script not found: $launcher" >&2
        echo "" >&2
        echo "💡 Project root was found but glm-launch.sh is missing" >&2
        echo "   Expected location: $launcher" >&2
        return 1
    fi

    # Make executable if needed
    if [[ ! -x "$launcher" ]]; then
        chmod +x "$launcher" 2>/dev/null || {
            echo "❌ GLM: Cannot make launcher executable" >&2
            return 1
        }
    fi

    # Launch with all arguments
    "$launcher" "$@"
    return $?
}

# =============================================================================
# P13 Public Interface: User-facing functions
# =============================================================================

# Standard launch (auto-delete container)
# Usage: glm [args...]
glm() {
    _glm "$@"
}

# Debug mode (persistent container + shell access)
# Usage: glm-debug [args...]
glm-debug() {
    _glm --debug "$@"
}

# No-delete mode (persistent container)
# Usage: glm-no-del [args...]
glm-no-del() {
    _glm --no-del "$@"
}

# Help display
# Usage: glm-help
glm-help() {
    cat <<'EOF'
🚀 GLM Aliases - Claude Code Launcher

Available Commands:
  glm [args]          Standard launch (auto-delete container)
  glm-debug [args]    Debug mode (persistent container + shell access)
  glm-no-del [args]   No-delete mode (persistent container)
  glm-help            Show this help

All arguments are passed to glm-launch.sh:
  -h, --help          Show help
  -w, --workspace DIR  Specify workspace directory
  -i, --image IMAGE    Specify Docker image
  -t, --test           Run configuration test
  -b, --backup         Create backup
  --dry-run            Show command without execution
  --debug              Debug mode (persistent container)
  --no-del             No-delete mode (persistent container)
  --ci                 CI/CD mode (non-interactive)
  --non-interactive    Non-interactive mode

Examples:
  glm                    # Launch from current directory
  glm-debug             # Launch with debug shell on exit
  glm -w ~/other/project # Launch with different workspace
  glm --test            # Test configuration
  glm --dry-run         # Preview docker command

See also: glm-launch.sh --help

Installation:
  ./scripts/setup-aliases.sh --install    # Auto-install for current shell
  ./scripts/setup-aliases.sh --check      # Check installation status

Project Root Detection (Fallback Chain):
  1. GLM_PROJECT_ROOT environment variable (highest priority)
  2. Hardcoded path from installation
  3. Upward search from current directory

Documentation:
  https://github.com/RussianLioN/glm-docker-tools
EOF
}

# =============================================================================
# Auto-initialization guard
# Purpose: Prevent duplicate loading and show message once per session
# =============================================================================
if [[ -z "${_GLM_ALIASES_LOADED:-}" ]]; then
    export _GLM_ALIASES_LOADED=1
    # Uncomment below to show loading message:
    # echo "✅ GLM aliases loaded (type 'glm-help' for info)"
fi
