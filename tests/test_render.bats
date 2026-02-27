#!/usr/bin/env bats
# tests/test_render.bats - Tests for lib/render.sh

load 'test_helper'

setup() {
    # Source libs - note: declare -a in constants.sh becomes local inside
    # setup(), so we must re-assign globals AFTER sourcing all libs.
    source "${LIB_DIR}/constants.sh"
    source "${LIB_DIR}/utils.sh"
    source "${LIB_DIR}/sessions.sh"
    source "${LIB_DIR}/ai.sh"
    source "${LIB_DIR}/render.sh"

    # Stub cursor/clear to suppress ANSI output
    cursor_to() { :; }
    clear_line() { :; }

    # Temp file for spying on capture_pane arguments
    SPY_FILE="$(mktemp)"
}

teardown() {
    rm -f "$SPY_FILE"
}

spy_capture_pane() {
    capture_pane() {
        echo "$2" > "$SPY_FILE"
        echo "line1"
    }
}

@test "draw_preview passes dynamic line count to capture_pane based on terminal height" {
    SESSIONS=("test-session")
    SELECTED=0
    TERM_COLS=80
    TERM_ROWS=22
    # preview_start=10, available = 22 - 10 - 4 = 8, which is < PREVIEW_LINES(15)
    local expected_lines=8
    spy_capture_pane

    draw_preview 10

    [ "$(cat "$SPY_FILE")" -eq "$expected_lines" ]
}

@test "draw_preview caps line count at PREVIEW_LINES when terminal is very tall" {
    SESSIONS=("test-session")
    SELECTED=0
    TERM_COLS=80
    TERM_ROWS=200
    spy_capture_pane

    draw_preview 10

    [ "$(cat "$SPY_FILE")" -eq "$PREVIEW_LINES" ]
}

@test "draw_preview uses minimum 3 lines when terminal is very short" {
    SESSIONS=("test-session")
    SELECTED=0
    TERM_COLS=80
    TERM_ROWS=12
    spy_capture_pane

    draw_preview 10

    [ "$(cat "$SPY_FILE")" -eq 3 ]
}
