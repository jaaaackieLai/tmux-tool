#!/usr/bin/env bats
# tests/test_config.bats - Tests for config get/set/list CLI functions

load 'test_helper'

setup() {
    load_lib constants
    load_lib config
    TEST_CONFIG_DIR="$(mktemp -d)"
    TEST_CONFIG_FILE="${TEST_CONFIG_DIR}/config.sh"
    TMUX_SESSION_CONFIG_FILE="$TEST_CONFIG_FILE"
}

teardown() {
    rm -rf "$TEST_CONFIG_DIR"
}

# ── config_set ──────────────────────────────────────────────────────

@test "config_set creates file if missing" {
    rm -f "$TEST_CONFIG_FILE"
    run config_set NEW_DEFAULT_DIR "/tmp/test"
    [ "$status" -eq 0 ]
    [ -f "$TEST_CONFIG_FILE" ]
    grep -q 'TMUX_SESSION_NEW_DEFAULT_DIR="/tmp/test"' "$TEST_CONFIG_FILE"
}

@test "config_set updates existing key" {
    echo 'TMUX_SESSION_NEW_DEFAULT_DIR="/old/path"' > "$TEST_CONFIG_FILE"
    run config_set NEW_DEFAULT_DIR "/new/path"
    [ "$status" -eq 0 ]
    grep -q 'TMUX_SESSION_NEW_DEFAULT_DIR="/new/path"' "$TEST_CONFIG_FILE"
    # Old value should be gone
    ! grep -q '/old/path' "$TEST_CONFIG_FILE"
}

@test "config_set rejects invalid key" {
    run config_set INVALID_KEY "value"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid config key"* ]]
}

# ── config_get ──────────────────────────────────────────────────────

@test "config_get returns value" {
    echo 'TMUX_SESSION_NEW_DEFAULT_DIR="/my/path"' > "$TEST_CONFIG_FILE"
    run config_get NEW_DEFAULT_DIR
    [ "$status" -eq 0 ]
    [ "$output" = "/my/path" ]
}

@test "config_get returns empty for unset key" {
    touch "$TEST_CONFIG_FILE"
    run config_get NEW_DEFAULT_DIR
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

# ── config_list ─────────────────────────────────────────────────────

@test "config_list shows all keys" {
    echo 'TMUX_SESSION_NEW_DEFAULT_DIR="/projects"' > "$TEST_CONFIG_FILE"
    run config_list
    [ "$status" -eq 0 ]
    [[ "$output" == *"NEW_DEFAULT_DIR"* ]]
    [[ "$output" == *"/projects"* ]]
    [[ "$output" == *"NEW_DEFAULT_CMD"* ]]
    [[ "$output" == *"NEW_ASK_DIR"* ]]
    [[ "$output" == *"NEW_ASK_CMD"* ]]
}

# ── Bool normalization ──────────────────────────────────────────────

@test "config_set normalizes bool true to 1" {
    run config_set NEW_ASK_DIR "true"
    [ "$status" -eq 0 ]
    grep -q 'TMUX_SESSION_NEW_ASK_DIR="1"' "$TEST_CONFIG_FILE"
}

@test "config_set normalizes bool false to 0" {
    run config_set NEW_ASK_CMD "false"
    [ "$status" -eq 0 ]
    grep -q 'TMUX_SESSION_NEW_ASK_CMD="0"' "$TEST_CONFIG_FILE"
}
