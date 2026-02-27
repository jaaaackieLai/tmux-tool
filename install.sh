#!/usr/bin/env bash
set -euo pipefail

# install.sh - Install tmux-session manager

readonly INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly GITHUB_REPO="jaaaackieLai/tmux-tool"
readonly GITHUB_RAW_BASE="https://raw.githubusercontent.com/${GITHUB_REPO}/main"
readonly LIB_SUBDIR="tmux-session-lib"
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

# Install
echo "Installing tmux-session to ${INSTALL_DIR}..."
mkdir -p "$INSTALL_DIR" 2>/dev/null || true
if [[ -w "$INSTALL_DIR" ]]; then
    cp "${SOURCE_DIR}/tmux-session" "${INSTALL_DIR}/tmux-session"
    chmod +x "${INSTALL_DIR}/tmux-session"
    rm -rf "${INSTALL_DIR}/${LIB_SUBDIR}"
    mkdir -p "${INSTALL_DIR}/${LIB_SUBDIR}"
    cp "${SOURCE_DIR}/lib/"*.sh "${INSTALL_DIR}/${LIB_SUBDIR}/"
else
    echo "Need sudo to write to ${INSTALL_DIR}"
    sudo mkdir -p "$INSTALL_DIR"
    sudo cp "${SOURCE_DIR}/tmux-session" "${INSTALL_DIR}/tmux-session"
    sudo chmod +x "${INSTALL_DIR}/tmux-session"
    sudo rm -rf "${INSTALL_DIR}/${LIB_SUBDIR}"
    sudo mkdir -p "${INSTALL_DIR}/${LIB_SUBDIR}"
    sudo cp "${SOURCE_DIR}/lib/"*.sh "${INSTALL_DIR}/${LIB_SUBDIR}/"
fi

if [[ -n "$TMP_SOURCE_DIR" ]]; then
    rm -rf "$TMP_SOURCE_DIR"
fi

echo ""
echo "Installed successfully!"
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
