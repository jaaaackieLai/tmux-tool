#!/usr/bin/env bash
# lib/constants.sh - Constants, colors, and global state declarations

[[ -n "${_CONSTANTS_LOADED:-}" ]] && return
readonly _CONSTANTS_LOADED=1

readonly VERSION="1.0.0"
readonly PREVIEW_LINES=15
readonly PREVIEW_MAX_COLS=80
readonly CAPTURE_LINES=150
AI_TEMP_DIR="/tmp/tmux-session-ai-$$"
readonly AI_MODEL="claude-haiku-4-5-20251001"

# ─── Colors and styles ───────────────────────────────────────────────
readonly RESET='\033[0m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly REVERSE='\033[7m'
readonly RED='\033[31m'
readonly GREEN='\033[32m'
readonly YELLOW='\033[33m'
readonly BLUE='\033[34m'
readonly CYAN='\033[36m'
readonly WHITE='\033[37m'
readonly BG_BLUE='\033[44m'
readonly GRAY='\033[90m'

# ─── State ────────────────────────────────────────────────────────────
declare -a SESSIONS=()
declare -a AI_SUMMARIES=()
declare -a AI_NAMES=()
SELECTED=0
RUNNING=true
TERM_ROWS=0
TERM_COLS=0
LIST_END=0
