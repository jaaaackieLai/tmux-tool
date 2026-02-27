#!/usr/bin/env bash
# lib/ai.sh - AI summary generation using Anthropic API

ai_enabled() {
    [[ -n "${ANTHROPIC_API_KEY:-}" ]] && command -v curl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1
}

start_ai_summaries() {
    ai_enabled || return 0

    mkdir -p "$AI_TEMP_DIR"

    local i
    for i in "${!SESSIONS[@]}"; do
        local session="${SESSIONS[$i]}"
        (
            local content
            content=$(capture_pane "$session" "$CAPTURE_LINES" | tail -80)

            local prompt
            prompt="Based on this terminal output, provide: 1) A one-line summary in Traditional Chinese (max 30 chars) of what this session is doing. 2) A suggested short name (lowercase, hyphens ok, max 20 chars). Respond in EXACTLY this format, nothing else:
SUMMARY: <summary>
NAME: <name>

Terminal output:
${content}"

            local body
            body=$(jq -n \
                --arg model "$AI_MODEL" \
                --arg prompt "$prompt" \
                '{model: $model, max_tokens: 150, messages: [{role: "user", content: $prompt}]}')

            local response
            response=$(curl -s --max-time 15 \
                -H "x-api-key: ${ANTHROPIC_API_KEY}" \
                -H "anthropic-version: 2023-06-01" \
                -H "content-type: application/json" \
                "https://api.anthropic.com/v1/messages" \
                -d "$body" 2>/dev/null)

            if [[ -n "$response" ]]; then
                local text
                text=$(echo "$response" | jq -r '.content[0].text // empty' 2>/dev/null)
                if [[ -n "$text" ]]; then
                    local summary name
                    summary=$(echo "$text" | grep '^SUMMARY:' | sed 's/^SUMMARY: //' | head -1)
                    name=$(echo "$text" | grep '^NAME:' | sed 's/^NAME: //' | head -1)
                    echo "$summary" > "${AI_TEMP_DIR}/${session}.summary"
                    echo "$name" > "${AI_TEMP_DIR}/${session}.name"
                fi
            fi
        ) &
    done
}

load_ai_results() {
    [[ -d "$AI_TEMP_DIR" ]] || return 0

    local i
    for i in "${!SESSIONS[@]}"; do
        local session="${SESSIONS[$i]}"
        if [[ -f "${AI_TEMP_DIR}/${session}.summary" ]]; then
            AI_SUMMARIES[$i]=$(cat "${AI_TEMP_DIR}/${session}.summary" 2>/dev/null || true)
        fi
        if [[ -f "${AI_TEMP_DIR}/${session}.name" ]]; then
            AI_NAMES[$i]=$(cat "${AI_TEMP_DIR}/${session}.name" 2>/dev/null || true)
        fi
    done
}

cleanup_ai() {
    rm -rf "$AI_TEMP_DIR" 2>/dev/null || true
    # Kill any lingering background AI jobs
    jobs -p 2>/dev/null | xargs kill 2>/dev/null || true
}
