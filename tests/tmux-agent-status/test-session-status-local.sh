#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
TARGET_SCRIPT="${PROJECT_ROOT}/home/.config/tmux/session-status.sh"
TEST_PREFIX="tmux-local-test"
TMUX_SESSION_STATUS_OVERLAY_SCRIPT="/dev/null"

# shellcheck source=/dev/null
source "${TARGET_SCRIPT}"
# shellcheck source=/dev/null
source "${PROJECT_ROOT}/tests/tmux-agent-status/testlib.sh"

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

run_shell_wrapped_explicit_done_case() {
  local name="$1"

  (
    local tmp_dir="" session="review-shell" actual=""

    tmp_dir=$(mktemp -d)
    STATE_DIR="${tmp_dir}"
    printf 'codex\tdone\n' > "${STATE_DIR}/${session}"

    _session_has_live_agent_process() {
      return 0
    }

    _session_agent_command() {
      printf '%s\n' "codex"
    }

    _session_live_state() {
      printf '%s\n' "working"
    }

    _state_file_mtime() {
      printf '%s\n' "42"
    }

    actual=$(tmux_session_status_emit_local_record "${session}" "current")
    assert_equal \
      "${name}" \
      $'review-shell\tcodex\tworking\tlocal_explicit\t42' \
      "${actual}"

    rm -rf "${tmp_dir}"
  )
}

run_shell_wrapped_explicit_done_case \
    "shell-wrapped explicit done session recovers to working from the live pane"

run_shell_wrapped_fallback_case() {
  local name="$1"

  (
    local tmp_dir="" session="review-shell" actual=""

    tmp_dir=$(mktemp -d)
    STATE_DIR="${tmp_dir}"

    _session_agent_command() {
      printf '%s\n' "codex"
    }

    _session_live_state() {
      printf '%s\n' "working"
    }

    actual=$(tmux_session_status_emit_local_record "${session}" "current")
    assert_equal \
      "${name}" \
      $'review-shell\tcodex\tworking\tlocal_fallback\t0' \
      "${actual}"

    rm -rf "${tmp_dir}"
  )
}

run_shell_wrapped_fallback_case \
    "shell-wrapped live agent sessions without explicit state still render"

run_working_heartbeat_case() {
  local name="$1"

  (
    local tmp_dir="" session="heartbeat" actual="" refreshed_at="" now=""

    tmp_dir=$(mktemp -d)
    STATE_DIR="${tmp_dir}"
    printf 'codex\tworking\n' > "${STATE_DIR}/${session}"
    touch -t 202001010000 "${STATE_DIR}/${session}"

    _session_agent_command() {
      printf '%s\n' "codex"
    }

    _session_live_state() {
      printf '%s\n' "working"
    }

    actual=$(tmux_session_status_emit_local_record "${session}" "current")
    refreshed_at=$(_state_file_mtime "${STATE_DIR}/${session}")
    now=$(date +%s)

    if (( now - refreshed_at > 5 )); then
      fail "${name} state file heartbeat was not refreshed"
    fi

    assert_equal \
      "${name}" \
      $'heartbeat\tcodex\tworking\tlocal_explicit\t'"${refreshed_at}" \
      "${actual}"

    _session_live_state() {
      printf '%s\n' ""
    }

    actual=$(tmux_session_status_emit_local_record "${session}" "current")
    assert_equal \
      "${name} survives a transient empty live parse" \
      $'heartbeat\tcodex\tworking\tlocal_explicit\t'"${refreshed_at}" \
      "${actual}"

    rm -rf "${tmp_dir}"
  )
}

run_working_heartbeat_case \
    "live working refreshes the explicit state heartbeat"
