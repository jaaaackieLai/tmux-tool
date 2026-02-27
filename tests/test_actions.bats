#!/usr/bin/env bats
# tests/test_actions.bats - Tests for lib/actions.sh

load 'test_helper'

@test "action_rename uses AI suggestion when pressing Enter" {
    run bash -c "
        source '${LIB_DIR}/constants.sh'
        source '${LIB_DIR}/utils.sh'
        source '${LIB_DIR}/sessions.sh'
        source '${LIB_DIR}/ai.sh'
        source '${LIB_DIR}/render.sh'
        source '${LIB_DIR}/actions.sh'

        SESSIONS=(alpha)
        SELECTED=0
        AI_NAMES=('ai-name')
        TERM_ROWS=20
        SAVED_TTY=''

        cursor_show() { :; }
        cursor_hide() { :; }
        cursor_to() { :; }
        clear_line() { :; }
        refresh_sessions() { :; }
        render() { :; }

        tmux() {
            if [[ \"\$1\" == 'rename-session' ]]; then
                echo \"RENAMED:\${3}:\${4}\"
            fi
        }

        printf '\n' | action_rename
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"RENAMED:alpha:ai-name"* ]]
}

@test "action_rename supports custom input when pressing e" {
    run bash -c "
        source '${LIB_DIR}/constants.sh'
        source '${LIB_DIR}/utils.sh'
        source '${LIB_DIR}/sessions.sh'
        source '${LIB_DIR}/ai.sh'
        source '${LIB_DIR}/render.sh'
        source '${LIB_DIR}/actions.sh'

        SESSIONS=(alpha)
        SELECTED=0
        AI_NAMES=('ai-name')
        TERM_ROWS=20
        SAVED_TTY=''

        cursor_show() { :; }
        cursor_hide() { :; }
        cursor_to() { :; }
        clear_line() { :; }
        refresh_sessions() { :; }
        render() { :; }

        tmux() {
            if [[ \"\$1\" == 'rename-session' ]]; then
                echo \"RENAMED:\${3}:\${4}\"
            fi
        }

        printf 'emy-custom-name\n' | action_rename
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"RENAMED:alpha:my-custom-name"* ]]
}

@test "action_rename cancels on ESC without renaming" {
    run bash -c "
        source '${LIB_DIR}/constants.sh'
        source '${LIB_DIR}/utils.sh'
        source '${LIB_DIR}/sessions.sh'
        source '${LIB_DIR}/ai.sh'
        source '${LIB_DIR}/render.sh'
        source '${LIB_DIR}/actions.sh'

        SESSIONS=(alpha)
        SELECTED=0
        AI_NAMES=('ai-name')
        TERM_ROWS=20
        SAVED_TTY=''

        cursor_show() { :; }
        cursor_hide() { :; }
        cursor_to() { :; }
        clear_line() { :; }
        refresh_sessions() { :; }
        render() { :; }

        tmux() {
            if [[ \"\$1\" == 'rename-session' ]]; then
                echo \"RENAMED:\${3}:\${4}\"
            fi
        }

        printf '\033' | action_rename
    "
    [ "$status" -eq 0 ]
    [[ "$output" != *"RENAMED:"* ]]
}
