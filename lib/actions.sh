#!/usr/bin/env bash
# lib/actions.sh - User actions (attach, rename, kill, new)

action_attach() {
    if [[ ${#SESSIONS[@]} -eq 0 ]]; then return; fi
    local session="${SESSIONS[$SELECTED]}"
    cursor_show
    clear_screen
    # Restore terminal before attaching
    stty "$SAVED_TTY" 2>/dev/null || true
    tmux attach -t "$session"
    # After detach, re-setup terminal
    SAVED_TTY=$(stty -g 2>/dev/null || true)
    stty -echo -icanon min 1 time 0 2>/dev/null || true
    cursor_hide
    refresh_sessions
    start_ai_summaries
    render
}

action_rename() {
    if [[ ${#SESSIONS[@]} -eq 0 ]]; then return; fi
    local session="${SESSIONS[$SELECTED]}"
    local suggested="${AI_NAMES[$SELECTED]:-}"

    # Show rename prompt
    cursor_show
    local prompt_row=$(( TERM_ROWS ))
    cursor_to "$prompt_row" 1
    clear_line

    # Restore terminal for input
    stty "$SAVED_TTY" 2>/dev/null || true
    stty echo icanon 2>/dev/null || true

    local new_name=""
    if [[ -n "$suggested" ]]; then
        printf " ${BOLD}Rename '${session}' to${RESET} [${DIM}${suggested}${RESET}] (ESC/empty=cancel): "
        IFS= read -r -e -i "$suggested" new_name || true
    else
        printf " ${BOLD}Rename '${session}' to${RESET} (ESC/empty=cancel): "
        IFS= read -r -e new_name || true
    fi

    # Re-setup raw terminal
    stty -echo -icanon min 1 time 0 2>/dev/null || true
    cursor_hide

    # Clear the prompt line
    cursor_to "$prompt_row" 1
    clear_line

    if [[ -n "$new_name" ]]; then
        tmux rename-session -t "$session" "$new_name" 2>/dev/null || true
        refresh_sessions
    fi
    render
}

action_kill() {
    if [[ ${#SESSIONS[@]} -eq 0 ]]; then return; fi
    local session="${SESSIONS[$SELECTED]}"

    # Show confirm prompt (stay in raw mode, read single key without Enter)
    local prompt_row=$(( TERM_ROWS ))
    cursor_to "$prompt_row" 1
    clear_line
    printf " ${RED}${BOLD}Kill session '${session}'? [y/N]${RESET} "

    local confirm=""
    IFS= read -r -s -n 1 confirm 2>/dev/null || true

    # Clear the prompt line
    cursor_to "$prompt_row" 1
    clear_line

    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        tmux kill-session -t "$session" 2>/dev/null || true
        refresh_sessions
    fi
    render
}

action_new() {
    cursor_show
    local prompt_row=$(( TERM_ROWS ))
    cursor_to "$prompt_row" 1
    clear_line

    stty "$SAVED_TTY" 2>/dev/null || true
    stty echo icanon 2>/dev/null || true

    printf " ${BOLD}New session name${RESET} (empty=cancel): "
    local name=""
    IFS= read -r -e name || true

    stty -echo -icanon min 1 time 0 2>/dev/null || true
    cursor_hide

    # Clear the prompt line
    cursor_to "$prompt_row" 1
    clear_line

    if [[ -n "$name" ]]; then
        tmux new-session -d -s "$name" 2>/dev/null || true
        refresh_sessions
        start_ai_summaries
    fi
    render
}
