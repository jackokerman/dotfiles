#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
TARGET_SCRIPT="${PROJECT_ROOT}/scripts/sync-dev-checkouts.sh"

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

write_manifest() {
  local manifest="$1" repo_url="$2"

  printf 'demo\t%s\tmain\n' "${repo_url}" > "${manifest}"
}

run_clone_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  create_remote_repo "${tmp_dir}"
  write_manifest "${tmp_dir}/dev-checkouts.tsv" "${tmp_dir}/remote.git"

  DEV_CHECKOUTS_MANIFEST="${tmp_dir}/dev-checkouts.tsv" \
    DEV_CHECKOUTS_SRC_ROOT="${tmp_dir}/src" \
    "${TARGET_SCRIPT}" >/dev/null 2>&1

  actual=$(git -C "${tmp_dir}/src/demo" rev-parse --abbrev-ref HEAD)
  assert_equal "sync script clones a missing development checkout" "main" "${actual}"
  rm -rf "${tmp_dir}"
}

run_update_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  create_remote_repo "${tmp_dir}"
  write_manifest "${tmp_dir}/dev-checkouts.tsv" "${tmp_dir}/remote.git"

  DEV_CHECKOUTS_MANIFEST="${tmp_dir}/dev-checkouts.tsv" \
    DEV_CHECKOUTS_SRC_ROOT="${tmp_dir}/src" \
    "${TARGET_SCRIPT}" >/dev/null 2>&1

  append_remote_commit "${tmp_dir}"

  DEV_CHECKOUTS_MANIFEST="${tmp_dir}/dev-checkouts.tsv" \
    DEV_CHECKOUTS_SRC_ROOT="${tmp_dir}/src" \
    "${TARGET_SCRIPT}" >/dev/null 2>&1

  actual=$(tail -n 1 "${tmp_dir}/src/demo/README.md")
  assert_equal "sync script fast-forwards a clean development checkout" "two" "${actual}"
  rm -rf "${tmp_dir}"
}

run_dirty_skip_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  create_remote_repo "${tmp_dir}"
  write_manifest "${tmp_dir}/dev-checkouts.tsv" "${tmp_dir}/remote.git"

  DEV_CHECKOUTS_MANIFEST="${tmp_dir}/dev-checkouts.tsv" \
    DEV_CHECKOUTS_SRC_ROOT="${tmp_dir}/src" \
    "${TARGET_SCRIPT}" >/dev/null 2>&1

  append_remote_commit "${tmp_dir}"
  printf 'local\n' >> "${tmp_dir}/src/demo/README.md"

  actual=$(
    DEV_CHECKOUTS_MANIFEST="${tmp_dir}/dev-checkouts.tsv" \
      DEV_CHECKOUTS_SRC_ROOT="${tmp_dir}/src" \
      "${TARGET_SCRIPT}" 2>&1 || true
  )

  assert_matches "sync script warns instead of overwriting a dirty development checkout" 'dirty' "${actual}"
  rm -rf "${tmp_dir}"
}

run_origin_mismatch_skip_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  create_remote_repo "${tmp_dir}"
  write_manifest "${tmp_dir}/dev-checkouts.tsv" "${tmp_dir}/remote.git"

  DEV_CHECKOUTS_MANIFEST="${tmp_dir}/dev-checkouts.tsv" \
    DEV_CHECKOUTS_SRC_ROOT="${tmp_dir}/src" \
    "${TARGET_SCRIPT}" >/dev/null 2>&1

  git -C "${tmp_dir}/src/demo" remote set-url origin https://example.com/demo.git

  actual=$(
    DEV_CHECKOUTS_MANIFEST="${tmp_dir}/dev-checkouts.tsv" \
      DEV_CHECKOUTS_SRC_ROOT="${tmp_dir}/src" \
      "${TARGET_SCRIPT}" 2>&1 || true
  )

  assert_matches "sync script warns instead of updating a checkout with a custom origin" 'origin does not match' "${actual}"
  rm -rf "${tmp_dir}"
}

run_clone_case
run_update_case
run_dirty_skip_case
run_origin_mismatch_skip_case
