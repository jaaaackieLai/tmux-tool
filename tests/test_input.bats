#!/usr/bin/env bats
# tests/test_input.bats - Tests for lib/input.sh

load 'test_helper'

# ─── read_key tests ─────────────────────────────────────────────────

@test "read_key returns UP for up arrow escape sequence" {
    run bash -c "
        source '${LIB_DIR}/constants.sh'
        source '${LIB_DIR}/utils.sh'
        source '${LIB_DIR}/sessions.sh'
        source '${LIB_DIR}/ai.sh'
        source '${LIB_DIR}/render.sh'
        source '${LIB_DIR}/actions.sh'
        source '${LIB_DIR}/input.sh'
        printf '\033[A' | read_key
    "
    [ "$status" -eq 0 ]
    [ "$output" = "UP" ]
}

@test "read_key returns DOWN for down arrow escape sequence" {
    run bash -c "
        source '${LIB_DIR}/constants.sh'
        source '${LIB_DIR}/utils.sh'
        source '${LIB_DIR}/sessions.sh'
        source '${LIB_DIR}/ai.sh'
        source '${LIB_DIR}/render.sh'
        source '${LIB_DIR}/actions.sh'
        source '${LIB_DIR}/input.sh'
        printf '\033[B' | read_key
    "
    [ "$status" -eq 0 ]
    [ "$output" = "DOWN" ]
}

@test "read_key returns ENTER for newline (bash strips it to empty string)" {
    run bash -c "
        source '${LIB_DIR}/constants.sh'
        source '${LIB_DIR}/utils.sh'
        source '${LIB_DIR}/sessions.sh'
        source '${LIB_DIR}/ai.sh'
        source '${LIB_DIR}/render.sh'
        source '${LIB_DIR}/actions.sh'
        source '${LIB_DIR}/input.sh'
        printf '\n' | read_key
    "
    [ "$status" -eq 0 ]
    [ "$output" = "ENTER" ]
}

@test "read_key returns ESC for lone escape" {
    run bash -c "
        source '${LIB_DIR}/constants.sh'
        source '${LIB_DIR}/utils.sh'
        source '${LIB_DIR}/sessions.sh'
        source '${LIB_DIR}/ai.sh'
        source '${LIB_DIR}/render.sh'
        source '${LIB_DIR}/actions.sh'
        source '${LIB_DIR}/input.sh'
        printf '\033' | read_key
    "
    [ "$status" -eq 0 ]
    [ "$output" = "ESC" ]
}

@test "read_key returns TIMEOUT on no input" {
    run bash -c "
        source '${LIB_DIR}/constants.sh'
        source '${LIB_DIR}/utils.sh'
        source '${LIB_DIR}/sessions.sh'
        source '${LIB_DIR}/ai.sh'
        source '${LIB_DIR}/render.sh'
        source '${LIB_DIR}/actions.sh'
        source '${LIB_DIR}/input.sh'
        read_key </dev/null
    "
    [ "$status" -eq 0 ]
    [ "$output" = "TIMEOUT" ]
}

# ─── SELECTED boundary tests via handle_input ────────────────────────

@test "UP key does not go below 0 when SELECTED is 0" {
    run bash -c "
        source '${LIB_DIR}/constants.sh'
        source '${LIB_DIR}/utils.sh'
        source '${LIB_DIR}/sessions.sh'
        source '${LIB_DIR}/ai.sh'
        source '${LIB_DIR}/render.sh'
        source '${LIB_DIR}/actions.sh'
        source '${LIB_DIR}/input.sh'
        SESSIONS=(alpha beta gamma)
        SELECTED=0
        # Mock read_key to return UP
        read_key() { echo 'UP'; }
        # Mock render to do nothing
        render() { :; }
        handle_input
        echo \"\$SELECTED\"
    "
    [ "$status" -eq 0 ]
    [ "$output" = "0" ]
}

@test "DOWN key does not exceed last session index" {
    run bash -c "
        source '${LIB_DIR}/constants.sh'
        source '${LIB_DIR}/utils.sh'
        source '${LIB_DIR}/sessions.sh'
        source '${LIB_DIR}/ai.sh'
        source '${LIB_DIR}/render.sh'
        source '${LIB_DIR}/actions.sh'
        source '${LIB_DIR}/input.sh'
        SESSIONS=(alpha beta gamma)
        SELECTED=2
        # Mock read_key to return DOWN
        read_key() { echo 'DOWN'; }
        render() { :; }
        handle_input
        echo \"\$SELECTED\"
    "
    [ "$status" -eq 0 ]
    [ "$output" = "2" ]
}

@test "UP key decrements SELECTED from middle" {
    run bash -c "
        source '${LIB_DIR}/constants.sh'
        source '${LIB_DIR}/utils.sh'
        source '${LIB_DIR}/sessions.sh'
        source '${LIB_DIR}/ai.sh'
        source '${LIB_DIR}/render.sh'
        source '${LIB_DIR}/actions.sh'
        source '${LIB_DIR}/input.sh'
        SESSIONS=(alpha beta gamma)
        SELECTED=2
        read_key() { echo 'UP'; }
        render() { :; }
        handle_input
        echo \"\$SELECTED\"
    "
    [ "$status" -eq 0 ]
    [ "$output" = "1" ]
}

@test "DOWN key increments SELECTED from middle" {
    run bash -c "
        source '${LIB_DIR}/constants.sh'
        source '${LIB_DIR}/utils.sh'
        source '${LIB_DIR}/sessions.sh'
        source '${LIB_DIR}/ai.sh'
        source '${LIB_DIR}/render.sh'
        source '${LIB_DIR}/actions.sh'
        source '${LIB_DIR}/input.sh'
        SESSIONS=(alpha beta gamma)
        SELECTED=1
        read_key() { echo 'DOWN'; }
        render() { :; }
        handle_input
        echo \"\$SELECTED\"
    "
    [ "$status" -eq 0 ]
    [ "$output" = "2" ]
}
