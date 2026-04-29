#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
TARGET_SCRIPT="${PROJECT_ROOT}/home/.config/tmux/session-status.sh"
TEST_PREFIX="tmux-status-test"
TMUX_SESSION_STATUS_OVERLAY_SCRIPT="/dev/null"

# shellcheck source=/dev/null
source "${TARGET_SCRIPT}"
# shellcheck source=/dev/null
source "${PROJECT_ROOT}/tests/tmux-agent-status/testlib.sh"

run_case() {
    local name="$1" explicit_state="$2" live_state="$3" has_known_agent_pane="$4" stale_working="$5" agent_mismatch="$6" expected="$7" actual=""

    actual=$(tmux_session_status_resolve_state "${explicit_state}" "${live_state}" "${has_known_agent_pane}" "${stale_working}" "${agent_mismatch}")
    assert_equal "${name}" "${expected}" "${actual}"
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
    "explicit working upgrades to waiting on a real waiting prompt" \
    "working" \
    "waiting" \
    "1" \
    "0" \
    "0" \
    "waiting"

run_case \
    "explicit done ignores a non-waiting live working signal" \
    "done" \
    "working" \
    "1" \
    "0" \
    "0" \
    "done"

run_case \
    "explicit working ignores a non-waiting live done signal" \
    "working" \
    "done" \
    "1" \
    "0" \
    "0" \
    "working"

run_case \
    "explicit waiting ignores a non-waiting live done signal" \
    "waiting" \
    "done" \
    "1" \
    "0" \
    "0" \
    "waiting"

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
