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

# ─── Config CLI helpers ─────────────────────────────────────────────

readonly -a CONFIG_KEYS=(NEW_DEFAULT_DIR NEW_DEFAULT_CMD NEW_ASK_DIR NEW_ASK_CMD)
readonly -a CONFIG_BOOL_KEYS=(NEW_ASK_DIR NEW_ASK_CMD)

_is_valid_config_key() {
    local key="$1" k
    for k in "${CONFIG_KEYS[@]}"; do
        [[ "$k" == "$key" ]] && return 0
    done
    return 1
}

_is_bool_key() {
    local key="$1" k
    for k in "${CONFIG_BOOL_KEYS[@]}"; do
        [[ "$k" == "$key" ]] && return 0
    done
    return 1
}

config_list() {
    TMUX_SESSION_CONFIG_FILE="${TMUX_SESSION_CONFIG_FILE:-$(default_config_file)}"
    # Reset to defaults before sourcing
    local TMUX_SESSION_NEW_DEFAULT_DIR=""
    local TMUX_SESSION_NEW_DEFAULT_CMD=""
    local TMUX_SESSION_NEW_ASK_DIR="0"
    local TMUX_SESSION_NEW_ASK_CMD="0"
    if [[ -f "$TMUX_SESSION_CONFIG_FILE" ]]; then
        # shellcheck disable=SC1090
        source "$TMUX_SESSION_CONFIG_FILE"
    fi
    local key
    for key in "${CONFIG_KEYS[@]}"; do
        local var="TMUX_SESSION_${key}"
        echo "${key}=${!var}"
    done
}

config_get() {
    local key="$1"
    if ! _is_valid_config_key "$key"; then
        echo "Invalid config key: ${key}" >&2
        return 1
    fi
    TMUX_SESSION_CONFIG_FILE="${TMUX_SESSION_CONFIG_FILE:-$(default_config_file)}"
    local TMUX_SESSION_NEW_DEFAULT_DIR=""
    local TMUX_SESSION_NEW_DEFAULT_CMD=""
    local TMUX_SESSION_NEW_ASK_DIR="0"
    local TMUX_SESSION_NEW_ASK_CMD="0"
    if [[ -f "$TMUX_SESSION_CONFIG_FILE" ]]; then
        # shellcheck disable=SC1090
        source "$TMUX_SESSION_CONFIG_FILE"
    fi
    local var="TMUX_SESSION_${key}"
    echo "${!var}"
}

config_set() {
    local key="$1" value="$2"
    if ! _is_valid_config_key "$key"; then
        echo "Invalid config key: ${key}" >&2
        return 1
    fi
    if _is_bool_key "$key"; then
        value=$(normalize_bool "$value")
    fi
    TMUX_SESSION_CONFIG_FILE="${TMUX_SESSION_CONFIG_FILE:-$(default_config_file)}"
    local config_dir
    config_dir="$(dirname "$TMUX_SESSION_CONFIG_FILE")"
    if [[ ! -d "$config_dir" ]]; then
        mkdir -p "$config_dir"
        chmod 700 "$config_dir"
    fi
    local full_key="TMUX_SESSION_${key}"
    local line="${full_key}=\"${value}\""
    if [[ -f "$TMUX_SESSION_CONFIG_FILE" ]] && grep -q "^${full_key}=" "$TMUX_SESSION_CONFIG_FILE"; then
        sed -i "s|^${full_key}=.*|${line}|" "$TMUX_SESSION_CONFIG_FILE"
    else
        echo "$line" >> "$TMUX_SESSION_CONFIG_FILE"
    fi
}
