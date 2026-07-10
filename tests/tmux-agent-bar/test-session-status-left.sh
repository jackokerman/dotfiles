#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
TARGET_SCRIPT="${PROJECT_ROOT}/home/.config/tmux/session-status-left.sh"
TEST_PREFIX="tmux-agent-bar-left-test"

# shellcheck source=/dev/null
source "${PROJECT_ROOT}/tests/tmux-agent-status/testlib.sh"

run_raw_waiting_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  mkdir -p "${tmp_dir}/state"
  printf 'codex\twaiting\n' > "${tmp_dir}/state/session"

  actual=$(
    STATE_DIR="${tmp_dir}/state" \
      XDG_CACHE_HOME="${tmp_dir}/cache" \
      "${TARGET_SCRIPT}" "session"
  )

  assert_equal "raw waiting state displays as done" "#[fg=#21c7a8] " "${actual}"
  rm -rf "${tmp_dir}"
}

run_raw_state_precedence_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  mkdir -p "${tmp_dir}/state" "${tmp_dir}/cache/tmux-agent-bar/current-state"
  printf 'codex\tworking\n' > "${tmp_dir}/state/session"
  printf 'done\n' > "${tmp_dir}/cache/tmux-agent-bar/current-state/session"

  actual=$(
    STATE_DIR="${tmp_dir}/state" \
      XDG_CACHE_HOME="${tmp_dir}/cache" \
      "${TARGET_SCRIPT}" "session"
  )

  assert_equal "raw hook state wins over current-state cache" "#[fg=#82aaff] " "${actual}"
  rm -rf "${tmp_dir}"
}

run_cached_waiting_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  mkdir -p "${tmp_dir}/cache/tmux-agent-bar/current-state"
  printf 'waiting\n' > "${tmp_dir}/cache/tmux-agent-bar/current-state/session"

  actual=$(
    STATE_DIR="${tmp_dir}/state" \
      XDG_CACHE_HOME="${tmp_dir}/cache" \
      "${TARGET_SCRIPT}" "session"
  )

  assert_equal "cached waiting state displays as done" "#[fg=#21c7a8] " "${actual}"
  rm -rf "${tmp_dir}"
}

run_raw_waiting_case
run_raw_state_precedence_case
run_cached_waiting_case
