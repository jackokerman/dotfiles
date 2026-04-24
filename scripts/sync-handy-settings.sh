#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
PROMPT_SOURCE="${HANDY_PROMPT_SOURCE:-${DOTFILES_ROOT}/home/.config/handy/prompts/improve-transcriptions.txt}"
SETTINGS_PATH="${HANDY_SETTINGS_PATH:-${HOME}/Library/Application Support/com.pais.handy/settings_store.json}"
MANAGED_PROMPT_ID="dotfiles_improve_transcriptions"
MANAGED_PROMPT_NAME="Improve Transcriptions (Dotfiles)"
SKIP_RUNNING_CHECK="${HANDY_SKIP_RUNNING_CHECK:-0}"

log() {
    printf '[sync-handy-settings] %s\n' "$*"
}

warn() {
    printf '[sync-handy-settings] %s\n' "$*" >&2
}

main() {
    local prompt_contents="" tmp_path=""

    if ! command -v jq >/dev/null 2>&1; then
        log "Skipping Handy sync because jq is not available"
        return 0
    fi

    if [[ ! -f "${PROMPT_SOURCE}" ]]; then
        warn "Tracked Handy prompt not found at ${PROMPT_SOURCE}"
        return 1
    fi

    if [[ ! -f "${SETTINGS_PATH}" ]]; then
        log "Skipping Handy sync because settings file does not exist at ${SETTINGS_PATH}"
        return 0
    fi

    if [[ "${SKIP_RUNNING_CHECK}" != "1" ]] && pgrep -x handy >/dev/null 2>&1; then
        log "Skipping Handy sync because Handy is running; close it and rerun dotty update"
        return 0
    fi

    prompt_contents="$(<"${PROMPT_SOURCE}")"
    tmp_path="$(mktemp "${TMPDIR:-/tmp}/handy-settings.XXXXXX")"
    trap 'rm -f "${tmp_path:-}"' EXIT

    if ! jq \
        --arg id "${MANAGED_PROMPT_ID}" \
        --arg name "${MANAGED_PROMPT_NAME}" \
        --arg prompt "${prompt_contents}" '
        if (.settings | type) != "object" then
            error("settings_store.json is missing the .settings object")
        else
            .settings |= (
                .post_process_prompts = (
                    (.post_process_prompts // [])
                    | if type == "array" then . else [] end
                    | if any(.id == $id) then
                        map(if .id == $id then . + {name: $name, prompt: $prompt} else . end)
                    else
                        . + [{id: $id, name: $name, prompt: $prompt}]
                    end
                )
                | .post_process_selected_prompt_id = $id
            )
        end
    ' "${SETTINGS_PATH}" >"${tmp_path}"; then
        warn "Failed to update Handy settings at ${SETTINGS_PATH}"
        return 1
    fi

    if cmp -s "${SETTINGS_PATH}" "${tmp_path}"; then
        log "Handy prompt already in sync"
        return 0
    fi

    mv "${tmp_path}" "${SETTINGS_PATH}"
    log "Synced Handy prompt to ${SETTINGS_PATH}"
}

main "$@"
