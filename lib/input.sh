#!/usr/bin/env bash
# lib/input.sh - Keyboard input reading and handling

read_key() {
    local key
    IFS= read -r -s -n 1 -t 0.5 key 2>/dev/null || { echo "TIMEOUT"; return; }

    if [[ "$key" == $'\x1b' ]]; then
        local seq1 seq2
        IFS= read -r -s -n 1 -t 0.1 seq1 2>/dev/null || true
        IFS= read -r -s -n 1 -t 0.1 seq2 2>/dev/null || true
        case "${seq1}${seq2}" in
            '[A') echo "UP" ;;
            '[B') echo "DOWN" ;;
            *)    echo "ESC" ;;
        esac
    elif [[ "$key" == "" ]]; then
        echo "ENTER"
    else
        echo "$key"
    fi
}

handle_detail_input() {
    local key
    key=$(read_key)

    case "$key" in
        UP)
            if (( DETAIL_SELECTED > 0 )); then
                DETAIL_SELECTED=$(( DETAIL_SELECTED - 1 ))
                DIRTY=1
            fi
            ;;
        DOWN)
            if (( DETAIL_SELECTED < ${#DETAIL_ACTIONS[@]} - 1 )); then
                DETAIL_SELECTED=$(( DETAIL_SELECTED + 1 ))
                DIRTY=1
            fi
            ;;
        ENTER)
            case "${DETAIL_ACTIONS[$DETAIL_SELECTED]}" in
                attach) action_attach ;;
                rename) action_rename ;;
                kill)   action_kill ;;
                back)   VIEW_MODE="list"; DIRTY=1 ;;
            esac
            ;;
        a) action_attach ;;
        r) action_rename ;;
        k) action_kill ;;
        ESC|q) VIEW_MODE="list"; DIRTY=1 ;;
        TIMEOUT)
            if load_ai_results; then
                DIRTY=1
            fi
            ;;
    esac
}

handle_input() {
    local key
    key=$(read_key)

    case "$key" in
        UP)
            if (( SELECTED > 0 )); then
                SELECTED=$(( SELECTED - 1 ))
                DIRTY=1
            fi
            ;;
        DOWN)
            if (( ${#SESSIONS[@]} > 0 && SELECTED < ${#SESSIONS[@]} - 1 )); then
                SELECTED=$(( SELECTED + 1 ))
                DIRTY=1
            fi
            ;;
        ENTER)
            if [[ ${#SESSIONS[@]} -gt 0 ]]; then
                DETAIL_SELECTED=0
                VIEW_MODE="detail"
                DIRTY=1
            fi
            ;;
        f)
            refresh_sessions
            start_ai_summaries
            DIRTY=1
            ;;
        n)
            action_new
            ;;
        q)
            RUNNING=false
            ;;
        TIMEOUT)
            if load_ai_results; then
                DIRTY=1
            fi
            ;;
    esac
}
