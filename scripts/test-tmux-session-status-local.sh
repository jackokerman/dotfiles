#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
TARGET_SCRIPT="${PROJECT_ROOT}/home/.config/tmux/session-status.sh"

# shellcheck source=/dev/null
source "${TARGET_SCRIPT}"

pass() {
    printf '[tmux-local-test] pass: %s\n' "$1"
}

fail() {
    printf '[tmux-local-test] fail: %s\n' "$1" >&2
    exit 1
}

assert_equal() {
    local name="$1" expected="$2" actual="$3"

    if [[ "${actual}" == "${expected}" ]]; then
        pass "${name}"
        return 0
    fi

    printf '[tmux-local-test] fail: %s\n' "${name}" >&2
    printf '[tmux-local-test] expected: %q\n' "${expected}" >&2
    printf '[tmux-local-test] actual: %q\n' "${actual}" >&2
    exit 1
}

run_done_cleanup_case() {
    local name="$1"

    (
        local tmp_dir="" safe_session="docs%2Ffeature" actual=""

        tmp_dir=$(mktemp -d)
        STATE_DIR="${tmp_dir}"
        printf 'codex\tdone\n' > "${STATE_DIR}/${safe_session}"

        _session_has_live_agent_process() {
            return 1
        }

        actual=$(tmux_session_status_emit_local_record "docs/feature" "current")
        assert_equal "${name}" "" "${actual}"

        if [[ -e "${STATE_DIR}/${safe_session}" ]]; then
            fail "${name} state file was not removed"
        fi

        rm -rf "${tmp_dir}"
    )
}

run_done_cleanup_case \
    "explicit done local session without a live agent is hidden and clears state"
