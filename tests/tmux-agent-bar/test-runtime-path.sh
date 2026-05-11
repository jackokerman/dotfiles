#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
TARGET_SCRIPT="${PROJECT_ROOT}/home/.config/tmux/tmux-agent-bar-path.sh"
TEST_PREFIX="tmux-agent-bar-path-test"

# shellcheck source=/dev/null
source "${PROJECT_ROOT}/tests/tmux-agent-status/testlib.sh"

run_default_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)

  actual=$(
    HOME="${tmp_dir}/home" \
    XDG_CONFIG_HOME="${tmp_dir}/config" \
    "${BASH}" -c 'set -euo pipefail; source "$1"; tmux_agent_bar_runtime_repo_path' bash "${TARGET_SCRIPT}"
  )

  assert_equal "default path uses managed runtime checkout" "${tmp_dir}/home/.local/share/tmux-agent-bar/repo" "${actual}"
  rm -rf "${tmp_dir}"
}

run_path_local_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  mkdir -p "${tmp_dir}/config/tmux-agent-bar"
  printf '%s\n' "${tmp_dir}/dev/tmux-agent-bar" > "${tmp_dir}/config/tmux-agent-bar/path.local"

  actual=$(
    HOME="${tmp_dir}/home" \
    XDG_CONFIG_HOME="${tmp_dir}/config" \
    "${BASH}" -c 'set -euo pipefail; source "$1"; tmux_agent_bar_runtime_repo_path' bash "${TARGET_SCRIPT}"
  )

  assert_equal "path.local overrides the managed runtime path" "${tmp_dir}/dev/tmux-agent-bar" "${actual}"
  rm -rf "${tmp_dir}"
}

run_env_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  mkdir -p "${tmp_dir}/config/tmux-agent-bar"
  printf '%s\n' "${tmp_dir}/dev/from-file" > "${tmp_dir}/config/tmux-agent-bar/path.local"

  actual=$(
    HOME="${tmp_dir}/home" \
    XDG_CONFIG_HOME="${tmp_dir}/config" \
    TMUX_AGENT_BAR_DIR="${tmp_dir}/dev/from-env" \
    "${BASH}" -c 'set -euo pipefail; source "$1"; tmux_agent_bar_runtime_repo_path' bash "${TARGET_SCRIPT}"
  )

  assert_equal "environment override wins over path.local" "${tmp_dir}/dev/from-env" "${actual}"
  rm -rf "${tmp_dir}"
}

run_default_case
run_path_local_case
run_env_case
