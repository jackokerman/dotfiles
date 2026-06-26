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

run_update_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  create_remote_repo "${tmp_dir}"
  mkdir -p "${tmp_dir}/src"
  git clone --branch main "${tmp_dir}/remote.git" "${tmp_dir}/src/tmux-agent-bar" >/dev/null 2>&1

  append_remote_commit "${tmp_dir}"

  TMUX_AGENT_BAR_DEV_DIR="${tmp_dir}/src/tmux-agent-bar" \
    "${TARGET_SCRIPT}" >/dev/null 2>&1

  actual=$(tail -n 1 "${tmp_dir}/src/tmux-agent-bar/README.md")
  assert_equal "sync script fast-forwards the development checkout" "two" "${actual}"
  rm -rf "${tmp_dir}"
}

run_missing_checkout_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)

  actual=$(
    TMUX_AGENT_BAR_DEV_DIR="${tmp_dir}/src/tmux-agent-bar" \
      "${TARGET_SCRIPT}" 2>&1
  )

  assert_matches "sync script warns when the development checkout is missing" 'not a git checkout' "${actual}"
  rm -rf "${tmp_dir}"
}

run_dirty_skip_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  create_remote_repo "${tmp_dir}"
  mkdir -p "${tmp_dir}/src"
  git clone --branch main "${tmp_dir}/remote.git" "${tmp_dir}/src/tmux-agent-bar" >/dev/null 2>&1

  append_remote_commit "${tmp_dir}"
  printf 'local\n' >> "${tmp_dir}/src/tmux-agent-bar/README.md"

  actual=$(
    TMUX_AGENT_BAR_DEV_DIR="${tmp_dir}/src/tmux-agent-bar" \
      "${TARGET_SCRIPT}" 2>&1 || true
  )

  assert_matches "sync script warns instead of overwriting a dirty checkout" 'dirty' "${actual}"
  rm -rf "${tmp_dir}"
}

run_diverged_skip_case() {
  local tmp_dir="" actual="" head=""

  tmp_dir=$(mktemp -d)
  create_remote_repo "${tmp_dir}"
  mkdir -p "${tmp_dir}/src"
  git clone --branch main "${tmp_dir}/remote.git" "${tmp_dir}/src/tmux-agent-bar" >/dev/null 2>&1

  (
    cd "${tmp_dir}/src/tmux-agent-bar"
    git config user.name "Test User"
    git config user.email "test@example.com"
    printf 'local\n' >> README.md
    git commit -am "local" >/dev/null 2>&1
  )
  head=$(git -C "${tmp_dir}/src/tmux-agent-bar" rev-parse --short HEAD)

  append_remote_commit "${tmp_dir}"

  actual=$(
    TMUX_AGENT_BAR_DEV_DIR="${tmp_dir}/src/tmux-agent-bar" \
      "${TARGET_SCRIPT}" 2>&1
  )

  assert_matches "sync script warns instead of failing on a diverged checkout" 'cannot be fast-forwarded' "${actual}"
  assert_equal "sync script keeps the local diverged checkout intact" "local" "$(tail -n 1 "${tmp_dir}/src/tmux-agent-bar/README.md")"
  assert_matches "sync script leaves the local diverged commit checked out" "${head}" "$(git -C "${tmp_dir}/src/tmux-agent-bar" rev-parse --short HEAD)"
  rm -rf "${tmp_dir}"
}

run_update_case
run_missing_checkout_case
run_dirty_skip_case
run_diverged_skip_case
