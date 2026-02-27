#!/usr/bin/env bash
# lib/utils.sh - Terminal utilities and helpers

die() {
    echo "Error: $1" >&2
    exit 1
}

check_deps() {
    command -v tmux >/dev/null 2>&1 || die "tmux is not installed"
}

cursor_hide() { printf '\033[?25l'; }
cursor_show() { printf '\033[?25h'; }
cursor_to() { printf '\033[%d;%dH' "$1" "$2"; }
clear_screen() { printf '\033[2J\033[H'; }
clear_line() { printf '\033[2K'; }
clear_below() { printf '\033[J'; }

get_term_size() {
    TERM_ROWS=$(tput lines 2>/dev/null || echo 24)
    TERM_COLS=$(tput cols 2>/dev/null || echo 80)
}
