#!/bin/bash
# Smart entrypoint for Claude Code container
# Different behavior based on CLAUDE_LAUNCH_MODE

claude_exit_code=0

# P8: Settings isolation for container layer (defense-in-depth)
isolate_project_settings() {
    local backup_file=""

    # Check if project settings exist
    if [[ ! -f /workspace/.claude/settings.json ]]; then
        # No project settings - container will use system settings
        return 0
    fi

    # Validate project settings (JSON syntax)
    if ! jq empty /workspace/.claude/settings.json 2>/dev/null; then
        echo "[ENTRYPOINT] ERROR: Invalid JSON in project settings" >&2
        return 1
    fi

    # Validate GLM configuration
    if ! grep -qE "api\.z\.ai|glm-[0-9]" /workspace/.claude/settings.json; then
        echo "[ENTRYPOINT] ERROR: Not a GLM configuration" >&2
        return 1
    fi

    # Backup system settings if exist
    if [[ -f /root/.claude/settings.json ]]; then
        backup_file="/tmp/settings.backup.$$"
        cp /root/.claude/settings.json "$backup_file"
    fi

    # Copy project settings to system location
    cp /workspace/.claude/settings.json /root/.claude/settings.json

    # Set up restoration trap
    if [[ -n "$backup_file" ]]; then
        trap "cp '$backup_file' /root/.claude/settings.json 2>/dev/null || true; rm -f '$backup_file'" EXIT INT TERM
    fi

    return 0
}

# P8: Apply settings isolation before launching Claude
if ! isolate_project_settings; then
    echo "[ENTRYPOINT] ERROR: Settings isolation failed" >&2
    exit 1
fi

# Run Claude based on mode and arguments
case "${CLAUDE_LAUNCH_MODE:-autodel}" in
    "debug")
        # Debug mode: run Claude, then stay in shell
        echo "🚀 Запуск Claude Code..."
        if [[ $# -gt 0 ]]; then
            /usr/local/bin/claude "$@"
        else
            /usr/local/bin/claude
        fi
        claude_exit_code=$?

        if [[ $claude_exit_code -ne 0 ]]; then
            echo "⚠️  Claude Code завершился с кодом $claude_exit_code"
        else
            echo "✅ Claude Code завершен успешно"
        fi

        echo
        echo "💡 Вы в shell контейнера. Для выхода из контейнера введите 'exit'"
        echo "💡 После выхода контейнер можно снова запустить через:"
        echo "   docker start -ai $HOSTNAME"
        echo

        # Start bash - user will be in shell, container stops on exit
        exec /bin/bash
        ;;

    "nodebug")
        # No-del mode: run Claude, then exit (container stops but persists)
        echo "🚀 Запуск Claude Code..."
        if [[ $# -gt 0 ]]; then
            /usr/local/bin/claude "$@"
        else
            /usr/local/bin/claude
        fi
        claude_exit_code=$?

        if [[ $claude_exit_code -ne 0 ]]; then
            echo "⚠️  Claude Code завершился с кодом $claude_exit_code"
        else
            echo "✅ Claude Code завершен успешно"
        fi

        echo "📦 Контейнер сохранен (ОСТАНОВЛЕН) для повторного использования"
        exit $claude_exit_code
        ;;

    "autodel"|*)
        # Auto-del mode: run Claude, then exit container (container will be removed)
        echo "🚀 Запуск Claude Code..."
        if [[ $# -gt 0 ]]; then
            /usr/local/bin/claude "$@"
        else
            /usr/local/bin/claude
        fi
        claude_exit_code=$?

        if [[ $claude_exit_code -ne 0 ]]; then
            echo "⚠️  Claude Code завершился с кодом $claude_exit_code"
        else
            echo "✅ Claude Code завершен успешно"
        fi

        exit $claude_exit_code
        ;;
esac