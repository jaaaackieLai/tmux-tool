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
    # placeholder: will be implemented in behavioral commit
    handle_input
}

handle_input() {
    local key
    key=$(read_key)

    case "$key" in
        UP)
            if (( SELECTED > 0 )); then
                SELECTED=$(( SELECTED - 1 ))
            fi
            ;;
        DOWN)
            if (( ${#SESSIONS[@]} > 0 && SELECTED < ${#SESSIONS[@]} - 1 )); then
                SELECTED=$(( SELECTED + 1 ))
            fi
            ;;
        ENTER)
            action_attach
            ;;
        r)
            action_rename
            ;;
        f)
            refresh_sessions
            start_ai_summaries
            ;;
        k)
            action_kill
            ;;
        n)
            action_new
            ;;
        q)
            RUNNING=false
            ;;
        TIMEOUT)
            # Just re-render to pick up AI results
            ;;
    esac
}
