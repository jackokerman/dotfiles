#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
TARGET_SCRIPT="${PROJECT_ROOT}/scripts/sync-devtools.sh"
TEST_PREFIX="devtools-sync-test"

# shellcheck source=/dev/null
source "${PROJECT_ROOT}/tests/tmux-agent-status/testlib.sh"

create_remote_repo() {
  local root="$1" with_repo_install="${2:-0}" worktree="" remote=""

  worktree="${root}/work"
  remote="${root}/remote.git"

  git init --bare "${remote}" >/dev/null 2>&1
  git clone "${remote}" "${worktree}" >/dev/null 2>&1
  (
    cd "${worktree}"
    git config user.name "Test User"
    git config user.email "test@example.com"
    printf 'one\n' > README.md

    if [[ "${with_repo_install}" == "1" ]]; then
      mkdir -p scripts
      cat > scripts/install.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf 'repo\t%s\t%s\t%s\t%s\t%s\n' \
  "$PWD" \
  "${DOTTY_DEVTOOL_NAME:-}" \
  "${DOTTY_DEVTOOL_CHECKOUT_DIR:-}" \
  "${DOTTY_DEVTOOL_REPO_URL:-}" \
  "${DOTTY_DEVTOOL_BRANCH:-}" \
  >> "${TEST_INSTALL_LOG:?TEST_INSTALL_LOG is required}"
EOF
      chmod +x scripts/install.sh
    fi

    git add .
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
  local manifest="$1" repo_url="$2" install="${3:-}"

  printf 'demo\t%s\tmain\tdev\tfast-forward\t%s\n' "${repo_url}" "${install}" > "${manifest}"
}

write_git_wrapper() {
  local wrapper="$1" log_file="$2" real_git=""

  real_git="$(command -v git)"
  cat > "${wrapper}" <<EOF
#!/usr/bin/env bash
set -euo pipefail

printf '%s\t%s\n' "\${GIT_TERMINAL_PROMPT:-unset}" "\$*" >> "${log_file}"
exec "${real_git}" "\$@"
EOF
  chmod +x "${wrapper}"
}

run_clone_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  create_remote_repo "${tmp_dir}"
  write_manifest "${tmp_dir}/devtools.tsv" "${tmp_dir}/remote.git"

  DEVTOOLS_MANIFEST="${tmp_dir}/devtools.tsv" \
    DEVTOOLS_SRC_ROOT="${tmp_dir}/src" \
    "${TARGET_SCRIPT}" >/dev/null 2>&1

  actual=$(git -C "${tmp_dir}/src/demo" rev-parse --abbrev-ref HEAD)
  assert_equal "sync script clones a missing devtool checkout" "main" "${actual}"
  rm -rf "${tmp_dir}"
}

run_checkout_only_case() {
  local tmp_dir="" install_log=""

  tmp_dir=$(mktemp -d)
  install_log="${tmp_dir}/install.log"
  create_remote_repo "${tmp_dir}"
  write_manifest "${tmp_dir}/devtools.tsv" "${tmp_dir}/remote.git"

  TEST_INSTALL_LOG="${install_log}" \
    DEVTOOLS_MANIFEST="${tmp_dir}/devtools.tsv" \
    DEVTOOLS_SRC_ROOT="${tmp_dir}/src" \
    "${TARGET_SCRIPT}" >/dev/null 2>&1

  [[ ! -e "${install_log}" ]] || fail "checkout-only devtool should not run an install action"
  pass "checkout-only devtool skips install action"
  rm -rf "${tmp_dir}"
}

run_non_interactive_git_case() {
  local tmp_dir="" actual="" git_log=""

  tmp_dir=$(mktemp -d)
  create_remote_repo "${tmp_dir}"
  write_manifest "${tmp_dir}/devtools.tsv" "${tmp_dir}/remote.git"
  mkdir -p "${tmp_dir}/bin"

  git_log="${tmp_dir}/git.log"
  write_git_wrapper "${tmp_dir}/bin/git" "${git_log}"

  PATH="${tmp_dir}/bin:${PATH}" \
    DEVTOOLS_MANIFEST="${tmp_dir}/devtools.tsv" \
    DEVTOOLS_SRC_ROOT="${tmp_dir}/src" \
    "${TARGET_SCRIPT}" >/dev/null 2>&1

  append_remote_commit "${tmp_dir}"

  PATH="${tmp_dir}/bin:${PATH}" \
    DEVTOOLS_MANIFEST="${tmp_dir}/devtools.tsv" \
    DEVTOOLS_SRC_ROOT="${tmp_dir}/src" \
    "${TARGET_SCRIPT}" >/dev/null 2>&1

  actual=$(cat "${git_log}")
  assert_matches "sync script clones without terminal Git prompts" $'0\tclone --branch main ' "${actual}"
  assert_matches "sync script fetches updates without terminal Git prompts" $'0\t-C .* fetch origin main' "${actual}"
  rm -rf "${tmp_dir}"
}

run_update_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  create_remote_repo "${tmp_dir}"
  write_manifest "${tmp_dir}/devtools.tsv" "${tmp_dir}/remote.git"

  DEVTOOLS_MANIFEST="${tmp_dir}/devtools.tsv" \
    DEVTOOLS_SRC_ROOT="${tmp_dir}/src" \
    "${TARGET_SCRIPT}" >/dev/null 2>&1

  append_remote_commit "${tmp_dir}"

  DEVTOOLS_MANIFEST="${tmp_dir}/devtools.tsv" \
    DEVTOOLS_SRC_ROOT="${tmp_dir}/src" \
    "${TARGET_SCRIPT}" >/dev/null 2>&1

  actual=$(tail -n 1 "${tmp_dir}/src/demo/README.md")
  assert_equal "sync script fast-forwards a clean devtool checkout" "two" "${actual}"
  rm -rf "${tmp_dir}"
}

run_dirty_skip_case() {
  local tmp_dir="" actual="" install_log=""

  tmp_dir=$(mktemp -d)
  install_log="${tmp_dir}/install.log"
  create_remote_repo "${tmp_dir}" 1
  write_manifest "${tmp_dir}/devtools.tsv" "${tmp_dir}/remote.git" "repo:scripts/install.sh"

  TEST_INSTALL_LOG="${install_log}" \
    DEVTOOLS_MANIFEST="${tmp_dir}/devtools.tsv" \
    DEVTOOLS_SRC_ROOT="${tmp_dir}/src" \
    "${TARGET_SCRIPT}" >/dev/null 2>&1

  append_remote_commit "${tmp_dir}"
  printf 'local\n' >> "${tmp_dir}/src/demo/README.md"
  rm -f "${install_log}"

  actual=$(
    TEST_INSTALL_LOG="${install_log}" \
      DEVTOOLS_MANIFEST="${tmp_dir}/devtools.tsv" \
      DEVTOOLS_SRC_ROOT="${tmp_dir}/src" \
      "${TARGET_SCRIPT}" 2>&1 || true
  )

  assert_matches "sync script warns instead of overwriting a dirty devtool checkout" 'dirty' "${actual}"
  [[ ! -e "${install_log}" ]] || fail "dirty devtool checkout should not run install action"
  pass "dirty devtool checkout skips install action"
  rm -rf "${tmp_dir}"
}

run_origin_mismatch_skip_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  create_remote_repo "${tmp_dir}"
  write_manifest "${tmp_dir}/devtools.tsv" "${tmp_dir}/remote.git"

  DEVTOOLS_MANIFEST="${tmp_dir}/devtools.tsv" \
    DEVTOOLS_SRC_ROOT="${tmp_dir}/src" \
    "${TARGET_SCRIPT}" >/dev/null 2>&1

  git -C "${tmp_dir}/src/demo" remote set-url origin https://example.com/demo.git

  actual=$(
    DEVTOOLS_MANIFEST="${tmp_dir}/devtools.tsv" \
      DEVTOOLS_SRC_ROOT="${tmp_dir}/src" \
      "${TARGET_SCRIPT}" 2>&1 || true
  )

  assert_matches "sync script warns instead of updating a checkout with a custom origin" 'origin does not match' "${actual}"
  rm -rf "${tmp_dir}"
}

run_repo_install_action_case() {
  local tmp_dir="" actual="" install_log=""

  tmp_dir=$(mktemp -d)
  install_log="${tmp_dir}/install.log"
  create_remote_repo "${tmp_dir}" 1
  write_manifest "${tmp_dir}/devtools.tsv" "${tmp_dir}/remote.git" "repo:scripts/install.sh"

  TEST_INSTALL_LOG="${install_log}" \
    DEVTOOLS_MANIFEST="${tmp_dir}/devtools.tsv" \
    DEVTOOLS_SRC_ROOT="${tmp_dir}/src" \
    "${TARGET_SCRIPT}" >/dev/null 2>&1

  actual=$(cat "${install_log}")
  assert_equal \
    "repo install action receives cwd and devtool metadata" \
    "repo	${tmp_dir}/src/demo	demo	${tmp_dir}/src/demo	${tmp_dir}/remote.git	main" \
    "${actual}"
  rm -rf "${tmp_dir}"
}

run_dotty_install_action_case() {
  local tmp_dir="" actual="" install_log=""

  tmp_dir=$(mktemp -d)
  install_log="${tmp_dir}/install.log"
  create_remote_repo "${tmp_dir}"
  write_manifest \
    "${tmp_dir}/devtools.tsv" \
    "${tmp_dir}/remote.git" \
    "dotty:tests/devtools/fixtures/log-install.sh"

  TEST_INSTALL_LOG="${install_log}" \
    DEVTOOLS_MANIFEST="${tmp_dir}/devtools.tsv" \
    DEVTOOLS_SRC_ROOT="${tmp_dir}/src" \
    "${TARGET_SCRIPT}" >/dev/null 2>&1

  actual=$(cat "${install_log}")
  assert_equal \
    "dotty install action receives cwd and devtool metadata" \
    "dotty	${PROJECT_ROOT}	demo	${tmp_dir}/src/demo	${tmp_dir}/remote.git	main" \
    "${actual}"
  rm -rf "${tmp_dir}"
}

run_malformed_manifest_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  create_remote_repo "${tmp_dir}"
  printf 'demo\t%s\tmain\tdev\tfast-forward\n' "${tmp_dir}/remote.git" > "${tmp_dir}/devtools.tsv"

  actual=$(
    DEVTOOLS_MANIFEST="${tmp_dir}/devtools.tsv" \
      DEVTOOLS_SRC_ROOT="${tmp_dir}/src" \
      "${TARGET_SCRIPT}" 2>&1 || true
  )

  assert_matches "sync script warns on malformed manifest rows" 'malformed manifest entry' "${actual}"
  [[ ! -e "${tmp_dir}/src/demo" ]] || fail "malformed manifest row should not be cloned"
  pass "malformed manifest row is skipped"
  rm -rf "${tmp_dir}"
}

run_clone_case
run_checkout_only_case
run_non_interactive_git_case
run_update_case
run_dirty_skip_case
run_origin_mismatch_skip_case
run_repo_install_action_case
run_dotty_install_action_case
run_malformed_manifest_case
