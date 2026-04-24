#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
PROMPT_SOURCE="${HANDY_PROMPT_SOURCE:-${DOTFILES_ROOT}/home/.config/handy/prompts/improve-transcriptions.txt}"
SETTINGS_PATH="${HANDY_SETTINGS_PATH:-${HOME}/Library/Application Support/com.pais.handy/settings_store.json}"
MANAGED_PROMPT_ID="dotfiles_improve_transcriptions"
MANAGED_PROMPT_NAME="Improve Transcriptions (Dotfiles)"
SKIP_RUNNING_CHECK="${HANDY_SKIP_RUNNING_CHECK:-0}"
HANDY_PROCESS_NAME="${HANDY_PROCESS_NAME:-handy}"
HANDY_BUNDLE_ID="${HANDY_BUNDLE_ID:-com.pais.handy}"
HANDY_QUIT_TIMEOUT_SECONDS="${HANDY_QUIT_TIMEOUT_SECONDS:-10}"

tmp_path=""
restart_required=0

log() {
    printf '[sync-handy-settings] %s\n' "$*"
}

warn() {
    printf '[sync-handy-settings] %s\n' "$*" >&2
}

build_synced_settings() {
    local prompt_contents="$1" output_path="$2"

    jq \
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
    ' "${SETTINGS_PATH}" >"${output_path}"
}

is_handy_running() {
    pgrep -x "${HANDY_PROCESS_NAME}" >/dev/null 2>&1
}

quit_handy() {
    if ! command -v osascript >/dev/null 2>&1; then
        warn "Cannot restart Handy because osascript is not available"
        return 1
    fi

    osascript -e "tell application id \"${HANDY_BUNDLE_ID}\" to quit" >/dev/null
}

wait_for_handy_to_exit() {
    local elapsed=0

    while is_handy_running; do
        if (( elapsed >= HANDY_QUIT_TIMEOUT_SECONDS )); then
            return 1
        fi

        sleep 1
        ((elapsed += 1))
    done
}

relaunch_handy() {
    if ! command -v open >/dev/null 2>&1; then
        warn "Cannot relaunch Handy because open is not available"
        return 1
    fi

    open -gj -b "${HANDY_BUNDLE_ID}" >/dev/null
}

sync_handy_settings() {
    local prompt_contents="$1"

    if ! build_synced_settings "${prompt_contents}" "${tmp_path}"; then
        warn "Failed to update Handy settings at ${SETTINGS_PATH}"
        return 1
    fi

    if cmp -s "${SETTINGS_PATH}" "${tmp_path}"; then
        log "Handy prompt already in sync"
        return 0
    fi

    if [[ "${SKIP_RUNNING_CHECK}" != "1" ]] && is_handy_running; then
        log "Handy is running and the managed prompt changed; restarting Handy to apply sync"

        if ! quit_handy; then
            warn "Failed to quit Handy before syncing ${SETTINGS_PATH}"
            return 1
        fi

        restart_required=1

        if ! wait_for_handy_to_exit; then
            warn "Timed out waiting for Handy to quit before syncing ${SETTINGS_PATH}"
            return 1
        fi

        if ! build_synced_settings "${prompt_contents}" "${tmp_path}"; then
            warn "Failed to update Handy settings at ${SETTINGS_PATH} after Handy shut down"
            return 1
        fi

        if cmp -s "${SETTINGS_PATH}" "${tmp_path}"; then
            log "Handy prompt already in sync after Handy shut down"
            return 0
        fi
    fi

    if ! mv "${tmp_path}" "${SETTINGS_PATH}"; then
        warn "Failed to replace Handy settings at ${SETTINGS_PATH}"
        return 1
    fi

    tmp_path=""
    log "Synced Handy prompt to ${SETTINGS_PATH}"
}

main() {
    local prompt_contents="" status=0

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

    prompt_contents="$(<"${PROMPT_SOURCE}")"
    tmp_path="$(mktemp "${TMPDIR:-/tmp}/handy-settings.XXXXXX")"
    trap 'rm -f "${tmp_path:-}"' EXIT

    if sync_handy_settings "${prompt_contents}"; then
        status=0
    else
        status=$?
    fi

    if [[ "${restart_required}" == "1" ]]; then
        if relaunch_handy; then
            log "Relaunched Handy"
        else
            warn "Failed to relaunch Handy after syncing ${SETTINGS_PATH}"
            return 1
        fi
    fi

    return "${status}"
}

main "$@"
