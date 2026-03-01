#!/usr/bin/env bash
set -euo pipefail

# install.sh - Install tmux-session manager
#
# Layout:
#   ${INSTALL_PREFIX}/share/tmux-session/   # all program files
#   ${INSTALL_PREFIX}/bin/tmux-session       # symlink -> ../share/tmux-session/tmux-session

readonly INSTALL_PREFIX="${INSTALL_PREFIX:-${HOME}/.local}"
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
readonly SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
readonly GITHUB_REPO="jaaaackieLai/tmux-tool"
readonly GITHUB_RAW_BASE="https://raw.githubusercontent.com/${GITHUB_REPO}/main"
readonly LIB_FILES=(
    actions.sh
    ai.sh
    config.sh
    constants.sh
    input.sh
    render.sh
    sessions.sh
    update.sh
    utils.sh
)

BIN_DIR="${INSTALL_PREFIX}/bin"
DATA_DIR="${INSTALL_PREFIX}/share/tmux-session"

# ─── Uninstall ────────────────────────────────────────────────────────

do_uninstall() {
    echo "Uninstalling tmux-session..."

    local need_sudo=false
    if [[ -d "$DATA_DIR" && ! -w "$DATA_DIR" ]] || [[ -L "${BIN_DIR}/tmux-session" && ! -w "$BIN_DIR" ]]; then
        need_sudo=true
    fi

    if $need_sudo; then
        sudo rm -rf "$DATA_DIR"
        sudo rm -f "${BIN_DIR}/tmux-session"
    else
        rm -rf "$DATA_DIR"
        rm -f "${BIN_DIR}/tmux-session"
    fi

    # Clean up legacy layout (tmux-session-lib in bin dir)
    local legacy_lib="${BIN_DIR}/tmux-session-lib"
    if [[ -d "$legacy_lib" ]]; then
        if $need_sudo; then
            sudo rm -rf "$legacy_lib"
        else
            rm -rf "$legacy_lib"
        fi
    fi

    echo "Uninstalled successfully."
}

if [[ "${1:-}" == "--uninstall" ]]; then
    do_uninstall
    exit 0
fi

# ─── Install ──────────────────────────────────────────────────────────

SOURCE_DIR=""
TMP_SOURCE_DIR=""

echo "tmux-session installer"
echo "======================"
echo ""

# Check dependencies
check_dep() {
    if command -v "$1" >/dev/null 2>&1; then
        echo "  [OK] $1"
    else
        echo "  [MISSING] $1 - $2"
        return 1
    fi
}

download_from_github() {
    local target_dir="$1"
    mkdir -p "${target_dir}/lib"

    curl -fsSL "${GITHUB_RAW_BASE}/tmux-session" -o "${target_dir}/tmux-session"
    chmod +x "${target_dir}/tmux-session"

    local f=""
    for f in "${LIB_FILES[@]}"; do
        curl -fsSL "${GITHUB_RAW_BASE}/lib/${f}" -o "${target_dir}/lib/${f}"
    done
}

echo "Checking dependencies..."
MISSING=0
check_dep tmux "Required. Install: sudo apt install tmux / brew install tmux" || MISSING=1
check_dep curl "Optional (for AI features). Install: sudo apt install curl / brew install curl" || true
check_dep jq   "Optional (for AI features). Install: sudo apt install jq / brew install jq" || true
echo ""

if [[ $MISSING -eq 1 ]]; then
    echo "Error: Required dependencies are missing."
    exit 1
fi

# Determine source (local clone or remote raw)
if [[ -f "${SCRIPT_DIR}/tmux-session" && -d "${SCRIPT_DIR}/lib" ]]; then
    SOURCE_DIR="${SCRIPT_DIR}"
else
    TMP_SOURCE_DIR="$(mktemp -d)"
    echo "Running in remote install mode (downloading from GitHub)..."
    download_from_github "$TMP_SOURCE_DIR"
    SOURCE_DIR="${TMP_SOURCE_DIR}"
fi

# Install files to DATA_DIR, symlink in BIN_DIR
echo "Installing tmux-session to ${DATA_DIR}..."

install_files() {
    local use_sudo="$1"
    local cmd=""
    if $use_sudo; then cmd="sudo"; else cmd=""; fi

    # Create directories
    $cmd mkdir -p "$DATA_DIR"
    $cmd mkdir -p "${DATA_DIR}/lib"
    $cmd mkdir -p "$BIN_DIR"

    # Copy program files
    $cmd cp "${SOURCE_DIR}/tmux-session" "${DATA_DIR}/tmux-session"
    $cmd chmod +x "${DATA_DIR}/tmux-session"
    $cmd cp "${SOURCE_DIR}/lib/"*.sh "${DATA_DIR}/lib/"

    # Create symlink
    $cmd ln -sf "${DATA_DIR}/tmux-session" "${BIN_DIR}/tmux-session"

    # Clean up legacy layout (tmux-session-lib in bin dir)
    local legacy_lib="${BIN_DIR}/tmux-session-lib"
    if [[ -d "$legacy_lib" ]]; then
        $cmd rm -rf "$legacy_lib"
    fi
    local legacy_bin="${BIN_DIR}/tmux-session"
    if [[ -f "$legacy_bin" && ! -L "$legacy_bin" ]]; then
        # Old install had a real file in bin; replace with symlink
        $cmd rm -f "$legacy_bin"
        $cmd ln -sf "${DATA_DIR}/tmux-session" "${BIN_DIR}/tmux-session"
    fi
}

mkdir -p "$BIN_DIR" 2>/dev/null || true
mkdir -p "$DATA_DIR" 2>/dev/null || true

if [[ -w "$BIN_DIR" || ! -d "$BIN_DIR" ]] && [[ -w "$(dirname "$DATA_DIR")" || ! -d "$(dirname "$DATA_DIR")" ]]; then
    install_files false
else
    echo "Need sudo to write to ${INSTALL_PREFIX}"
    install_files true
fi

if [[ -n "$TMP_SOURCE_DIR" ]]; then
    rm -rf "$TMP_SOURCE_DIR"
fi

echo ""
echo "Installed successfully!"
echo "  Files:   ${DATA_DIR}/"
echo "  Symlink: ${BIN_DIR}/tmux-session -> ${DATA_DIR}/tmux-session"
echo ""

# Check for API key
if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
    echo "Tip: Set ANTHROPIC_API_KEY to enable AI summaries."
    echo "  export ANTHROPIC_API_KEY='your-key-here'"
    echo "  Add this to your ~/.bashrc or ~/.zshrc"
    echo ""
fi

# Auto-launch tip
echo "To auto-launch on SSH login, add to ~/.bashrc or ~/.zshrc:"
echo ""
echo '  if [[ -z "${TMUX:-}" ]] && command -v tmux-session >/dev/null 2>&1; then'
echo '      tmux-session'
echo '  fi'
echo ""
echo "Done!"
