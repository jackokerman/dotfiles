#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
TARGET_SCRIPT="${PROJECT_ROOT}/.dotty/commands/install-jackie-plan"
TEST_PREFIX="jackie-plan-install-test"

# shellcheck source=/dev/null
source "${PROJECT_ROOT}/tests/tmux-agent-status/testlib.sh"

write_fake_jackie_plan_install() {
  local install_script="$1"

  cat > "${install_script}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

mkdir -p "${HOME}/.local/bin" "${HOME}/.dotty/bin" "${HOME}/.bun/bin"
ln -sfn "${HOME}/.bun/bin/jp" "${HOME}/.local/bin/jp"
ln -sfn "${HOME}/.bun/bin/jackie-plan" "${HOME}/.local/bin/jackie-plan"
ln -sfn "${HOME}/.bun/bin/jp" "${HOME}/.dotty/bin/jp"
ln -sfn "${HOME}/.bun/bin/jackie-plan" "${HOME}/.dotty/bin/jackie-plan"
EOF
  chmod +x "${install_script}"
}

write_fake_bun() {
  local bun_path="$1" log_file="$2"

  cat > "${bun_path}" <<EOF
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "\$@" > "${log_file}"
EOF
  chmod +x "${bun_path}"
}

assert_wrapper_file() {
  local path="$1"

  [[ -x "${path}" ]] || fail "${path} should be executable"
  [[ ! -L "${path}" ]] || fail "${path} should be a wrapper file, not a symlink"
  assert_matches "${path} exports BUN_INSTALL" 'BUN_INSTALL=' "$(<"${path}")"
  assert_matches "${path} runs Bun by absolute install path" 'exec "\$\{BUN_INSTALL\}/bin/bun"' "$(<"${path}")"
}

run_wrapper_case() {
  local tmp_dir="" home_dir="" repo_dir="" bun_log="" actual=""

  tmp_dir="$(mktemp -d)"
  home_dir="${tmp_dir}/home"
  repo_dir="${tmp_dir}/src/jackie-plan"
  bun_log="${tmp_dir}/bun.log"

  mkdir -p "${repo_dir}/scripts" "${repo_dir}/src" "${home_dir}/.bun/bin"
  : > "${repo_dir}/src/cli.ts"
  write_fake_jackie_plan_install "${repo_dir}/scripts/install.sh"
  write_fake_bun "${home_dir}/.bun/bin/bun" "${bun_log}"

  env -u BUN_INSTALL \
    HOME="${home_dir}" \
    PATH="/usr/bin:/bin" \
    JACKIE_PLAN_SRC_ROOT="${tmp_dir}/src" \
    JACKIE_PLAN_REPO_DIR="${repo_dir}" \
    JACKIE_PLAN_COMPAT_REPO_DIR="${tmp_dir}/compat/repo" \
    "${TARGET_SCRIPT}" >/dev/null

  assert_wrapper_file "${home_dir}/.local/bin/jp"
  assert_wrapper_file "${home_dir}/.local/bin/jackie-plan"
  assert_wrapper_file "${home_dir}/.dotty/bin/jp"
  assert_wrapper_file "${home_dir}/.dotty/bin/jackie-plan"

  env -u BUN_INSTALL HOME="${home_dir}" PATH="/usr/bin:/bin" "${home_dir}/.local/bin/jp" --help
  actual="$(<"${bun_log}")"
  assert_equal "jp wrapper runs without bun on PATH" "${repo_dir}/src/cli.ts"$'\n'"--help" "${actual}"

  env -u BUN_INSTALL HOME="${home_dir}" PATH="/usr/bin:/bin" "${home_dir}/.dotty/bin/jackie-plan" status
  actual="$(<"${bun_log}")"
  assert_equal "jackie-plan wrapper runs without bun on PATH" "${repo_dir}/src/cli.ts"$'\n'"status" "${actual}"

  rm -rf "${tmp_dir}"
}

run_wrapper_case
