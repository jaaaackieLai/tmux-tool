#!/usr/bin/env bash
set -euo pipefail

# install.sh - Install tmux-session manager

readonly INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Install
echo "Installing tmux-session to ${INSTALL_DIR}..."
if [[ -w "$INSTALL_DIR" ]]; then
    cp "${SCRIPT_DIR}/tmux-session" "${INSTALL_DIR}/tmux-session"
    chmod +x "${INSTALL_DIR}/tmux-session"
else
    echo "Need sudo to write to ${INSTALL_DIR}"
    sudo cp "${SCRIPT_DIR}/tmux-session" "${INSTALL_DIR}/tmux-session"
    sudo chmod +x "${INSTALL_DIR}/tmux-session"
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
