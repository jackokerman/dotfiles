#!/usr/bin/env bash
set -euo pipefail

command -v tmux >/dev/null 2>&1 || exit 0

remove_hook_if_owned() {
    local hook_name="$1"
    local expected_action="$2"
    local current_hook=""

    current_hook="$(tmux show-hooks -g "${hook_name}" 2>/dev/null || true)"
    [[ "${current_hook}" == "${hook_name} ${expected_action}" ]] || return 0

    if [[ "${DOTTY_DRY_RUN:-false}" == "true" ]]; then
        printf '[dry-run] Would remove obsolete tmux hook %s\n' "${hook_name}"
        return 0
    fi

    tmux set-hook -gu "${hook_name}"
    printf 'Removed obsolete tmux hook %s\n' "${hook_name}"
}

remove_hook_if_owned \
    'client-attached[0]' \
    "run-shell \"${HOME}/.config/tmux/session-status-refresh.sh #{q:client_session} --force-refresh --client #{q:hook_client}\""
remove_hook_if_owned \
    'client-session-changed[0]' \
    "run-shell \"${HOME}/.config/tmux/session-status-refresh.sh #{q:client_session} --force-refresh --client #{q:hook_client}\""
remove_hook_if_owned \
    'session-closed[0]' \
    "run-shell \"${HOME}/.config/tmux/session-status-refresh.sh --all-clients --force-refresh --refresh-client\""
