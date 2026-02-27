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

@test "remote install mode works when install.sh is executed without local lib directory" {
    run bash -c "
        set -euo pipefail
        work=\$(mktemp -d)
        trap 'rm -rf \"\$work\"' EXIT

        mkdir -p \"\$work/bin\" \"\$work/remote\"
        cp '${REPO_ROOT}/install.sh' \"\$work/remote/install.sh\"

        cat > \"\$work/bin/tmux\" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

        cat > \"\$work/bin/curl\" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
out=''
url=''
while [[ \$# -gt 0 ]]; do
    case \"\$1\" in
        -o) out=\"\$2\"; shift 2 ;;
        -f|-s|-S|-L|-fsSL) shift ;;
        *) url=\"\$1\"; shift ;;
    esac
done
[[ -n \"\$out\" ]] || exit 0
rel=\"\${url#https://raw.githubusercontent.com/jaaaackieLai/tmux-tool/main/}\"
cp \"\$REPO_ROOT/\$rel\" \"\$out\"
EOF

        chmod +x \"\$work/bin/tmux\" \"\$work/bin/curl\"

        PATH=\"\$work/bin:\$PATH\" REPO_ROOT='${REPO_ROOT}' INSTALL_DIR='${TEST_INSTALL_DIR}' bash \"\$work/remote/install.sh\"

        [ -f '${TEST_INSTALL_DIR}/tmux-session' ]
        [ -f '${TEST_INSTALL_DIR}/tmux-session-lib/update.sh' ]
    "
    [ "$status" -eq 0 ]
}

@test "remote install downloads all lib .sh files" {
    run bash -c "
        set -euo pipefail
        work=\$(mktemp -d)
        trap 'rm -rf \"\$work\"' EXIT

        mkdir -p \"\$work/bin\" \"\$work/remote\"
        cp '${REPO_ROOT}/install.sh' \"\$work/remote/install.sh\"

        cat > \"\$work/bin/tmux\" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

        cat > \"\$work/bin/curl\" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
out=''
url=''
while [[ \$# -gt 0 ]]; do
    case \"\$1\" in
        -o) out=\"\$2\"; shift 2 ;;
        -f|-s|-S|-L|-fsSL) shift ;;
        *) url=\"\$1\"; shift ;;
    esac
done
[[ -n \"\$out\" ]] || exit 0
rel=\"\${url#https://raw.githubusercontent.com/jaaaackieLai/tmux-tool/main/}\"
cp \"\$REPO_ROOT/\$rel\" \"\$out\"
EOF

        chmod +x \"\$work/bin/tmux\" \"\$work/bin/curl\"

        PATH=\"\$work/bin:\$PATH\" REPO_ROOT='${REPO_ROOT}' INSTALL_DIR='${TEST_INSTALL_DIR}' bash \"\$work/remote/install.sh\"

        expected=\$(ls '${REPO_ROOT}/lib/'*.sh | wc -l)
        actual=\$(ls '${TEST_INSTALL_DIR}/tmux-session-lib/'*.sh | wc -l)
        [ \"\$expected\" -eq \"\$actual\" ]
    "
    [ "$status" -eq 0 ]
}
