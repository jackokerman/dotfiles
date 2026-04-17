#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
TARGET_SCRIPT="${PROJECT_ROOT}/home/.config/tmux/session-status.sh"

# shellcheck source=/dev/null
source "${TARGET_SCRIPT}"

run_case() {
    local name="$1" explicit_state="$2" live_state="$3" has_known_agent_pane="$4" stale_working="$5" agent_mismatch="$6" expected="$7" actual=""

    actual=$(tmux_session_status_resolve_state "${explicit_state}" "${live_state}" "${has_known_agent_pane}" "${stale_working}" "${agent_mismatch}")
    if [[ "${actual}" == "${expected}" ]]; then
        printf '[tmux-status-test] pass: %s\n' "${name}"
        return 0
    fi

    printf '[tmux-status-test] fail: %s\n' "${name}" >&2
    printf '[tmux-status-test] expected: %q\n' "${expected}" >&2
    printf '[tmux-status-test] actual: %q\n' "${actual}" >&2
    exit 1
}

run_case \
    "explicit done stays done when the live parser sees no prompt state" \
    "done" \
    "" \
    "1" \
    "0" \
    "0" \
    "done"

run_case \
    "explicit done upgrades to waiting on a real waiting prompt" \
    "done" \
    "waiting" \
    "1" \
    "0" \
    "0" \
    "waiting"

run_case \
    "explicit done upgrades back to working when the live signal is active" \
    "done" \
    "working" \
    "1" \
    "0" \
    "0" \
    "working"

run_case \
    "stale working hook falls back to done without a live signal" \
    "working" \
    "" \
    "1" \
    "1" \
    "0" \
    "done"

run_case \
    "agent mismatch forces done before render" \
    "working" \
    "" \
    "1" \
    "0" \
    "1" \
    "done"

run_case \
    "sessions without explicit state still show waiting when the prompt needs input" \
    "" \
    "waiting" \
    "1" \
    "0" \
    "0" \
    "waiting"

run_case \
    "sessions without explicit state default to done when the pane is just idle" \
    "" \
    "" \
    "1" \
    "0" \
    "0" \
    "done"

run_case \
    "sessions without agent panes stay hidden" \
    "" \
    "" \
    "0" \
    "0" \
    "0" \
    ""
