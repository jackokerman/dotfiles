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
