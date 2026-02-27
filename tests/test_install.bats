#!/usr/bin/env bats
# tests/test_install.bats - Tests for install.sh

load 'test_helper'

setup() {
    TEST_INSTALL_DIR="$(mktemp -d)"
    TEST_SCRIPT_DIR="$REPO_ROOT"
}

teardown() {
    rm -rf "$TEST_INSTALL_DIR"
}

@test "install twice does not create nested lib directory" {
    # First install
    INSTALL_DIR="$TEST_INSTALL_DIR" bash "$REPO_ROOT/install.sh"
    # Second install
    INSTALL_DIR="$TEST_INSTALL_DIR" bash "$REPO_ROOT/install.sh"

    # tmux-session-lib/ should exist with .sh files
    [ -d "${TEST_INSTALL_DIR}/tmux-session-lib" ]
    ls "${TEST_INSTALL_DIR}/tmux-session-lib/"*.sh >/dev/null 2>&1

    # No nested directories
    [ ! -d "${TEST_INSTALL_DIR}/tmux-session-lib/tmux-session-lib" ]
    [ ! -d "${TEST_INSTALL_DIR}/tmux-session-lib/lib" ]
}

@test "install copies all lib .sh files" {
    INSTALL_DIR="$TEST_INSTALL_DIR" bash "$REPO_ROOT/install.sh"

    local expected
    expected=$(ls "$REPO_ROOT/lib/"*.sh | wc -l)
    local actual
    actual=$(ls "$TEST_INSTALL_DIR/tmux-session-lib/"*.sh | wc -l)
    [ "$expected" -eq "$actual" ]
}

@test "install removes stale lib files from previous install" {
    # First install
    INSTALL_DIR="$TEST_INSTALL_DIR" bash "$REPO_ROOT/install.sh"

    # Simulate a stale file from an older version
    touch "${TEST_INSTALL_DIR}/tmux-session-lib/old_module.sh"

    # Second install
    INSTALL_DIR="$TEST_INSTALL_DIR" bash "$REPO_ROOT/install.sh"

    # Stale file should be gone
    [ ! -f "${TEST_INSTALL_DIR}/tmux-session-lib/old_module.sh" ]
}

@test "install does not touch other files in INSTALL_DIR" {
    # Pre-existing lib/ from another tool
    mkdir -p "${TEST_INSTALL_DIR}/lib"
    echo "other-tool" > "${TEST_INSTALL_DIR}/lib/other.sh"

    INSTALL_DIR="$TEST_INSTALL_DIR" bash "$REPO_ROOT/install.sh"

    # Other tool's lib should be untouched
    [ -f "${TEST_INSTALL_DIR}/lib/other.sh" ]
    [ "$(cat "${TEST_INSTALL_DIR}/lib/other.sh")" = "other-tool" ]
}

@test "install creates INSTALL_DIR if it does not exist" {
    local new_dir="${TEST_INSTALL_DIR}/sub/path"
    INSTALL_DIR="$new_dir" bash "$REPO_ROOT/install.sh"

    [ -f "${new_dir}/tmux-session" ]
    [ -d "${new_dir}/tmux-session-lib" ]
}
