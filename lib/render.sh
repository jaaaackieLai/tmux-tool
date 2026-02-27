#!/usr/bin/env bash
# lib/render.sh - TUI rendering functions

draw_header() {
    cursor_to 1 1
    clear_line
    printf "${BOLD}${CYAN} tmux-session manager${RESET}${DIM}  v${VERSION}${RESET}"
    cursor_to 2 1
    clear_line
    local separator=""
    local max_w=$(( TERM_COLS - 2 ))
    for (( c=0; c<max_w; c++ )); do separator+="─"; done
    printf " ${DIM}${separator}${RESET}"
}

draw_session_list() {
    local start_row=3
    local max_items=$(( (TERM_ROWS - 10) / 2 ))  # Reserve space for preview + footer
    if (( max_items < 3 )); then max_items=3; fi
    if (( max_items > ${#SESSIONS[@]} )); then max_items=${#SESSIONS[@]}; fi

    # Calculate scroll offset
    local offset=0
    if (( SELECTED >= max_items )); then
        offset=$(( SELECTED - max_items + 1 ))
    fi

    local i
    for (( i=0; i<max_items; i++ )); do
        local idx=$(( offset + i ))
        if (( idx >= ${#SESSIONS[@]} )); then break; fi

        local row=$(( start_row + i ))
        cursor_to "$row" 1
        clear_line

        local session="${SESSIONS[$idx]}"
        local ai_text=""
        if [[ -n "${AI_SUMMARIES[$idx]:-}" ]]; then
            ai_text="${CYAN} [${AI_SUMMARIES[$idx]}]${RESET}"
        elif ai_enabled; then
            ai_text="${DIM} [...]${RESET}"
        fi

        if (( idx == SELECTED )); then
            printf " ${REVERSE}${BOLD} > %-20s${RESET}${ai_text}" "$session"
        else
            printf "   %-20s${ai_text}" "$session"
        fi
    done

    # Clear any leftover lines from previous render
    local clear_row=$(( start_row + max_items ))
    cursor_to "$clear_row" 1
    clear_line

    LIST_END=$(( start_row + max_items ))
}

draw_separator() {
    local row="$1"
    cursor_to "$row" 1
    clear_line
    local separator=""
    local max_w=$(( TERM_COLS - 2 ))
    for (( c=0; c<max_w; c++ )); do separator+="─"; done
    printf " ${DIM}${separator}${RESET}"
}

draw_preview() {
    local preview_start="$1"

    if [[ ${#SESSIONS[@]} -eq 0 ]]; then
        cursor_to "$preview_start" 1
        clear_line
        printf " ${DIM}No tmux sessions found. Press [n] to create one.${RESET}"
        return
    fi

    local session="${SESSIONS[$SELECTED]}"
    cursor_to "$preview_start" 1
    clear_line
    printf " ${BOLD}Preview${RESET} ${DIM}(${session}):${RESET}"

    local preview_content
    preview_content=$(capture_pane "$session" "$PREVIEW_LINES")

    local line_num=0
    local max_preview_lines=$(( TERM_ROWS - preview_start - 4 ))
    if (( max_preview_lines < 3 )); then max_preview_lines=3; fi

    while IFS= read -r line; do
        line_num=$(( line_num + 1 ))
        if (( line_num > max_preview_lines )); then break; fi

        local row=$(( preview_start + line_num ))
        cursor_to "$row" 1
        clear_line
        # Truncate line to the smaller of terminal width and PREVIEW_MAX_COLS
        local max_len=$(( TERM_COLS - 2 ))
        if (( PREVIEW_MAX_COLS < max_len )); then max_len=$PREVIEW_MAX_COLS; fi
        printf " ${GRAY}%s${RESET}" "${line:0:$max_len}"
    done <<< "$preview_content"

    # Clear remaining preview lines
    local r
    for (( r = preview_start + line_num + 1; r <= TERM_ROWS - 3; r++ )); do
        cursor_to "$r" 1
        clear_line
    done
}

draw_footer() {
    local row=$(( TERM_ROWS - 1 ))

    # Separator
    cursor_to $(( row - 1 )) 1
    clear_line
    local separator=""
    local max_w=$(( TERM_COLS - 2 ))
    for (( c=0; c<max_w; c++ )); do separator+="─"; done
    printf " ${DIM}${separator}${RESET}"

    cursor_to "$row" 1
    clear_line
    printf " ${GREEN}[Enter]${RESET} open  ${BLUE}[n]${RESET} new  ${DIM}[f]${RESET} refresh  ${DIM}[q]${RESET} quit"
}

draw_detail_footer() {
    local row=$(( TERM_ROWS - 1 ))

    # Separator
    cursor_to $(( row - 1 )) 1
    clear_line
    local separator=""
    local max_w=$(( TERM_COLS - 2 ))
    for (( c=0; c<max_w; c++ )); do separator+="─"; done
    printf " ${DIM}${separator}${RESET}"

    cursor_to "$row" 1
    clear_line
    printf " ${DIM}[Up/Down]${RESET} select  ${GREEN}[Enter]${RESET} confirm  ${DIM}[ESC]${RESET} back"
}

render_list() {
    draw_header

    draw_session_list

    draw_separator $(( LIST_END + 1 ))
    draw_preview $(( LIST_END + 2 ))
    draw_footer
}

render_detail() {
    if [[ ${#SESSIONS[@]} -eq 0 ]]; then
        VIEW_MODE="list"
        render_list
        return
    fi

    local session="${SESSIONS[$SELECTED]}"

    # Header: session name + version
    cursor_to 1 1
    clear_line
    printf "${BOLD}${CYAN} %s${RESET}${DIM}  v${VERSION}${RESET}" "$session"
    cursor_to 2 1
    clear_line
    local separator=""
    local max_w=$(( TERM_COLS - 2 ))
    for (( c=0; c<max_w; c++ )); do separator+="─"; done
    printf " ${DIM}${separator}${RESET}"

    # Info line: session details + AI summary
    cursor_to 3 1
    clear_line
    local info
    info=$(get_session_info "$session")
    local info_detail="${info#*: }"
    printf " ${BOLD}Info:${RESET} %s" "$info_detail"

    cursor_to 4 1
    clear_line
    local ai_text="${AI_SUMMARIES[$SELECTED]:-}"
    if [[ -n "$ai_text" ]]; then
        printf " ${BOLD}AI:${RESET}   ${CYAN}%s${RESET}" "$ai_text"
    elif ai_enabled; then
        printf " ${BOLD}AI:${RESET}   ${DIM}(loading...)${RESET}"
    fi

    # Separator
    draw_separator 5

    # Action menu
    local i
    for (( i=0; i<${#DETAIL_ACTIONS[@]}; i++ )); do
        local row=$(( 6 + i ))
        cursor_to "$row" 1
        clear_line
        if (( i == DETAIL_SELECTED )); then
            printf " ${REVERSE}${BOLD} > %-20s${RESET}" "${DETAIL_ACTIONS[$i]}"
        else
            printf "   %-20s" "${DETAIL_ACTIONS[$i]}"
        fi
    done

    # Clear remaining lines
    local r
    for (( r = 6 + ${#DETAIL_ACTIONS[@]}; r <= TERM_ROWS - 3; r++ )); do
        cursor_to "$r" 1
        clear_line
    done

    draw_detail_footer
}

render() {
    get_term_size
    load_ai_results

    if [[ "$VIEW_MODE" == "detail" ]]; then
        render_detail
    else
        render_list
    fi
}
