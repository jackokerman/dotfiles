#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
TARGET_SCRIPT="${PROJECT_ROOT}/scripts/sync-tmux-agent-bar.sh"
TEST_PREFIX="tmux-agent-bar-sync-test"

# shellcheck source=/dev/null
source "${PROJECT_ROOT}/tests/tmux-agent-status/testlib.sh"

create_remote_repo() {
  local root="$1" worktree="" remote=""

  worktree="${root}/work"
  remote="${root}/remote.git"

  git init --bare "${remote}" >/dev/null 2>&1
  git clone "${remote}" "${worktree}" >/dev/null 2>&1
  (
    cd "${worktree}"
    git config user.name "Test User"
    git config user.email "test@example.com"
    printf 'one\n' > README.md
    git add README.md
    git commit -m "initial" >/dev/null 2>&1
    git branch -M main
    git push origin main >/dev/null 2>&1
  )
}

append_remote_commit() {
  local root="$1" worktree=""

  worktree="${root}/work"

  (
    cd "${worktree}"
    printf 'two\n' >> README.md
    git commit -am "second" >/dev/null 2>&1
    git push origin main >/dev/null 2>&1
  )
}

run_clone_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  create_remote_repo "${tmp_dir}"

  TMUX_AGENT_BAR_REPO_URL="${tmp_dir}/remote.git" \
    TMUX_AGENT_BAR_INSTALL_ROOT="${tmp_dir}/install" \
    "${TARGET_SCRIPT}" >/dev/null 2>&1

  actual=$(git -C "${tmp_dir}/install/repo" rev-parse --abbrev-ref HEAD)
  assert_equal "sync script clones the managed checkout on first run" "main" "${actual}"
  rm -rf "${tmp_dir}"
}

run_update_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  create_remote_repo "${tmp_dir}"

  TMUX_AGENT_BAR_REPO_URL="${tmp_dir}/remote.git" \
    TMUX_AGENT_BAR_INSTALL_ROOT="${tmp_dir}/install" \
    "${TARGET_SCRIPT}" >/dev/null 2>&1

  append_remote_commit "${tmp_dir}"

  TMUX_AGENT_BAR_REPO_URL="${tmp_dir}/remote.git" \
    TMUX_AGENT_BAR_INSTALL_ROOT="${tmp_dir}/install" \
    "${TARGET_SCRIPT}" >/dev/null 2>&1

  actual=$(tail -n 1 "${tmp_dir}/install/repo/README.md")
  assert_equal "sync script fast-forwards a clean checkout" "two" "${actual}"
  rm -rf "${tmp_dir}"
}

run_dirty_skip_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  create_remote_repo "${tmp_dir}"

  TMUX_AGENT_BAR_REPO_URL="${tmp_dir}/remote.git" \
    TMUX_AGENT_BAR_INSTALL_ROOT="${tmp_dir}/install" \
    "${TARGET_SCRIPT}" >/dev/null 2>&1

  append_remote_commit "${tmp_dir}"
  printf 'local\n' >> "${tmp_dir}/install/repo/README.md"

  actual=$(
    TMUX_AGENT_BAR_REPO_URL="${tmp_dir}/remote.git" \
      TMUX_AGENT_BAR_INSTALL_ROOT="${tmp_dir}/install" \
      "${TARGET_SCRIPT}" 2>&1 || true
  )

  assert_matches "sync script warns instead of overwriting a dirty checkout" 'dirty' "${actual}"
  rm -rf "${tmp_dir}"
}

run_clone_case
run_update_case
run_dirty_skip_case
