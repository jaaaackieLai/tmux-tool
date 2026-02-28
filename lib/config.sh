#!/usr/bin/env bash
# lib/config.sh - User config loading

[[ -n "${_CONFIG_LOADED:-}" ]] && return
readonly _CONFIG_LOADED=1

default_config_file() {
    if [[ -n "${XDG_CONFIG_HOME:-}" ]]; then
        echo "${XDG_CONFIG_HOME}/tmux-session/config.sh"
    else
        echo "${HOME}/.config/tmux-session/config.sh"
    fi
}

normalize_bool() {
    case "${1,,}" in
        1|true|yes|on) echo "1" ;;
        *) echo "0" ;;
    esac
}

load_user_config() {
    TMUX_SESSION_CONFIG_FILE="${TMUX_SESSION_CONFIG_FILE:-$(default_config_file)}"
    TMUX_SESSION_NEW_DEFAULT_DIR="${TMUX_SESSION_NEW_DEFAULT_DIR:-}"
    TMUX_SESSION_NEW_DEFAULT_CMD="${TMUX_SESSION_NEW_DEFAULT_CMD:-}"
    TMUX_SESSION_NEW_ASK_DIR="${TMUX_SESSION_NEW_ASK_DIR:-0}"
    TMUX_SESSION_NEW_ASK_CMD="${TMUX_SESSION_NEW_ASK_CMD:-0}"

    if [[ -f "$TMUX_SESSION_CONFIG_FILE" ]]; then
        # Refuse to load config files writable by group or others to prevent
        # malicious code injection via a tampered config file.
        local perms
        perms=$(stat -c '%a' "$TMUX_SESSION_CONFIG_FILE" 2>/dev/null \
             || stat -f '%OLp' "$TMUX_SESSION_CONFIG_FILE" 2>/dev/null \
             || echo "")
        # Check group-write (020) or world-write (002) bits via octal arithmetic
        if [[ -n "$perms" ]] && (( (8#${perms} & 8#022) != 0 )); then
            echo "Warning: Skipping config '$TMUX_SESSION_CONFIG_FILE' (group/world-writable, mode $perms). Fix with: chmod go-w '$TMUX_SESSION_CONFIG_FILE'" >&2
        else
            # shellcheck disable=SC1090
            source "$TMUX_SESSION_CONFIG_FILE"
        fi
    fi

    TMUX_SESSION_NEW_ASK_DIR=$(normalize_bool "${TMUX_SESSION_NEW_ASK_DIR:-0}")
    TMUX_SESSION_NEW_ASK_CMD=$(normalize_bool "${TMUX_SESSION_NEW_ASK_CMD:-0}")
}
