#!/bin/bash
# Smart entrypoint for Claude Code container
# Different behavior based on CLAUDE_LAUNCH_MODE

claude_exit_code=0

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