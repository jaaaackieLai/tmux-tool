#!/usr/bin/env bash
# lib/update.sh - Self-update from GitHub raw files

check_remote_version() {
    local content=""
    content=$(curl -fsSL "${GITHUB_RAW_BASE}/lib/constants.sh") || return 1

    local remote_version=""
    remote_version=$(printf "%s\n" "$content" | sed -n 's/^readonly VERSION="\([^"]*\)".*/\1/p' | head -1)
    [[ -n "$remote_version" ]] || return 1
    echo "$remote_version"
}

run_remote_installer() {
    local install_dir="$1"
    local tmpdir=""
    tmpdir=$(mktemp -d) || return 1

    local installer="${tmpdir}/install.sh"
    if ! curl -fsSL "${GITHUB_RAW_BASE}/install.sh" -o "$installer"; then
        rm -rf "$tmpdir"
        return 1
    fi

    chmod +x "$installer"
    INSTALL_DIR="$install_dir" bash "$installer"
    local status=$?
    rm -rf "$tmpdir"
    return $status
}

do_self_update() {
    command -v curl >/dev/null 2>&1 || {
        echo "Error: curl is required for --update" >&2
        return 1
    }

    local remote_version=""
    remote_version=$(check_remote_version) || {
        echo "Error: failed to check remote version" >&2
        return 1
    }

    if [[ "$remote_version" == "$VERSION" ]]; then
        echo "Already up to date (v${VERSION})"
        return 0
    fi

    local current_bin=""
    current_bin=$(command -v tmux-session 2>/dev/null || true)

    local install_dir=""
    if [[ -n "$current_bin" ]]; then
        install_dir=$(dirname "$current_bin")
    elif [[ -n "${SCRIPT_DIR:-}" ]]; then
        install_dir="$SCRIPT_DIR"
    else
        install_dir="/usr/local/bin"
    fi

    echo "Updating tmux-session v${VERSION} -> v${remote_version}"
    if run_remote_installer "$install_dir"; then
        echo "Update complete."
        return 0
    fi

    echo "Update failed." >&2
    return 1
}
