#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
TMUX_CONF="${PROJECT_ROOT}/home/.config/tmux/tmux.conf"
SESSION_WRAPPER="${PROJECT_ROOT}/home/.config/tmux/session-status.sh"
LEFT_WRAPPER="${PROJECT_ROOT}/home/.config/tmux/session-status-left.sh"
REFRESH_WRAPPER="${PROJECT_ROOT}/home/.config/tmux/session-status-refresh.sh"
HOOK_WRAPPER="${PROJECT_ROOT}/home/.config/tmux/agent-status-hook.sh"
CODEX_HOOK_WRAPPER="${PROJECT_ROOT}/home/.config/tmux/codex-agent-status-hook.sh"
TEST_PREFIX="tmux-agent-bar-wrapper-test"

# shellcheck source=/dev/null
source "${PROJECT_ROOT}/tests/tmux-agent-status/testlib.sh"

make_fake_runtime() {
  local runtime_dir="$1"

  mkdir -p "${runtime_dir}/bin"

  cat > "${runtime_dir}/bin/tmux-agent-bar" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  current-state|current-state-cached)
    if [[ -n "${TMUX_AGENT_BAR_EXPECTED_CURRENT_TARGET:-}" ]] && [[ "${2:-}" != "${TMUX_AGENT_BAR_EXPECTED_CURRENT_TARGET}" ]]; then
      exit 1
    fi
    printf '%s\n' "${TMUX_AGENT_BAR_FAKE_CURRENT_STATE:-}"
    ;;
  render)
    if [[ -n "${TMUX_AGENT_BAR_EXPECTED_RENDER_TARGET:-}" ]] && [[ "${2:-}" != "${TMUX_AGENT_BAR_EXPECTED_RENDER_TARGET}" ]]; then
      exit 1
    fi
    if [[ -n "${TMUX_AGENT_BAR_FAKE_INVOCATIONS_FILE:-}" ]]; then
      printf 'runtime\trender\t%s\tforce=%s\n' "${2:-}" "${TMUX_AGENT_BAR_FORCE_REFRESH:-}" >> "${TMUX_AGENT_BAR_FAKE_INVOCATIONS_FILE}"
    fi
    printf '%s' "${TMUX_AGENT_BAR_FAKE_RENDER:-}"
    ;;
  render-cached)
    if [[ -n "${TMUX_AGENT_BAR_EXPECTED_RENDER_TARGET:-}" ]] && [[ "${2:-}" != "${TMUX_AGENT_BAR_EXPECTED_RENDER_TARGET}" ]]; then
      exit 1
    fi
    if [[ -n "${TMUX_AGENT_BAR_FAKE_INVOCATIONS_FILE:-}" ]]; then
      printf 'runtime\trender-cached\t%s\tforce=%s\n' "${2:-}" "${TMUX_AGENT_BAR_FORCE_REFRESH:-}" >> "${TMUX_AGENT_BAR_FAKE_INVOCATIONS_FILE}"
    fi
    printf '%s' "${TMUX_AGENT_BAR_FAKE_RENDER_CACHED:-}"
    ;;
  *)
    printf 'session:%s\n' "$*"
    ;;
esac
EOF

  cat > "${runtime_dir}/bin/tmux-agent-bar-hook" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'hook:%s\n' "$*"
EOF

  cat > "${runtime_dir}/bin/tmux-agent-bar-codex-hook" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'codex-hook:%s\n' "$*"
EOF

  chmod +x \
    "${runtime_dir}/bin/tmux-agent-bar" \
    "${runtime_dir}/bin/tmux-agent-bar-hook" \
    "${runtime_dir}/bin/tmux-agent-bar-codex-hook"
}

run_session_wrapper_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  make_fake_runtime "${tmp_dir}/runtime"

  actual=$(TMUX_AGENT_BAR_DIR="${tmp_dir}/runtime" "${SESSION_WRAPPER}" alpha beta)
  assert_equal "session wrapper execs the managed runtime entrypoint" "session:alpha beta" "${actual}"
  rm -rf "${tmp_dir}"
}

run_hook_wrapper_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  make_fake_runtime "${tmp_dir}/runtime"

  actual=$(TMUX_AGENT_BAR_DIR="${tmp_dir}/runtime" "${HOOK_WRAPPER}" working codex)
  assert_equal "hook wrapper execs the managed runtime entrypoint" "hook:working codex" "${actual}"
  rm -rf "${tmp_dir}"
}

run_codex_hook_wrapper_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  make_fake_runtime "${tmp_dir}/runtime"

  actual=$(TMUX_AGENT_BAR_DIR="${tmp_dir}/runtime" "${CODEX_HOOK_WRAPPER}" PostToolUse)
  assert_equal "Codex hook wrapper execs the managed runtime adapter" "codex-hook:PostToolUse" "${actual}"
  rm -rf "${tmp_dir}"
}

run_codex_hook_missing_runtime_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  make_fake_runtime "${tmp_dir}/runtime"
  rm "${tmp_dir}/runtime/bin/tmux-agent-bar-codex-hook"

  actual=$(TMUX_AGENT_BAR_DIR="${tmp_dir}/runtime" "${CODEX_HOOK_WRAPPER}" PermissionRequest)
  assert_equal "Codex hook wrapper exits cleanly when the runtime adapter is missing" "" "${actual}"
  rm -rf "${tmp_dir}"
}

run_left_wrapper_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  make_fake_runtime "${tmp_dir}/runtime"

  actual=$(
    TMUX_AGENT_BAR_DIR="${tmp_dir}/runtime" \
    TMUX_AGENT_BAR_EXPECTED_CURRENT_TARGET='$23' \
    TMUX_AGENT_BAR_FAKE_CURRENT_STATE="working" \
    "${LEFT_WRAPPER}" '$23'
  )
  assert_equal "left wrapper renders the targeted current-state prefix" "#[fg=#82aaff] " "${actual}"
  rm -rf "${tmp_dir}"
}

run_left_wrapper_fallback_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  make_fake_runtime "${tmp_dir}/runtime"

  actual=$(
    TMUX_AGENT_BAR_DIR="${tmp_dir}/runtime" \
    TMUX_AGENT_BAR_FAKE_CURRENT_STATE="" \
    "${LEFT_WRAPPER}"
  )
  assert_equal "left wrapper falls back to the plain prefix style when there is no state" "#[fg=#f78c6c]⠶ #[fg=#82aaff]" "${actual}"
  rm -rf "${tmp_dir}"
}

run_refresh_wrapper_cached_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  make_fake_runtime "${tmp_dir}/runtime"
  mkdir -p "${tmp_dir}/bin"

  cat > "${tmp_dir}/bin/tmux" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "set-option" && "${2:-}" == "-q" && "${3:-}" == "-t" ]]; then
  printf '%s\t%s\t%s\n' "${4:-}" "${5:-}" "${6:-}" > "${TMUX_FAKE_SET_OPTION_FILE}"
  exit 0
fi
exit 1
EOF
  chmod +x "${tmp_dir}/bin/tmux"

  actual=$(
    PATH="${tmp_dir}/bin:${PATH}" \
    TMUX_AGENT_BAR_DIR="${tmp_dir}/runtime" \
    TMUX_AGENT_BAR_EXPECTED_RENDER_TARGET='$23' \
    TMUX_AGENT_BAR_FAKE_RENDER_CACHED="#[fg=#21c7a8] other#[fg=default] " \
    TMUX_FAKE_SET_OPTION_FILE="${tmp_dir}/set-option" \
    "${REFRESH_WRAPPER}" '$23' --cached
    cat "${tmp_dir}/set-option"
  )

  assert_equal \
    "refresh wrapper stores the cached rendered right side in the session option" \
    $'$23\t@tmux_agent_bar_status_right\t#[fg=#21c7a8] other#[fg=default] ' \
    "${actual}"

  rm -rf "${tmp_dir}"
}

run_refresh_wrapper_client_refresh_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  make_fake_runtime "${tmp_dir}/runtime"
  mkdir -p "${tmp_dir}/bin"

  cat > "${tmp_dir}/bin/tmux" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  set-option)
    if [[ "${2:-}" == "-q" && "${3:-}" == "-t" ]]; then
      printf 'set\t%s\t%s\t%s\n' "${4:-}" "${5:-}" "${6:-}" >> "${TMUX_FAKE_INVOCATIONS_FILE}"
      exit 0
    fi
    ;;
  refresh-client)
    if [[ "${2:-}" == "-S" && "${3:-}" == "-t" ]]; then
      printf 'refresh\t%s\n' "${4:-}" >> "${TMUX_FAKE_INVOCATIONS_FILE}"
      exit 0
    fi
    ;;
esac
exit 1
EOF
  chmod +x "${tmp_dir}/bin/tmux"

  actual=$(
    PATH="${tmp_dir}/bin:${PATH}" \
    TMUX_AGENT_BAR_DIR="${tmp_dir}/runtime" \
    TMUX_AGENT_BAR_EXPECTED_RENDER_TARGET='PR review 🔎' \
    TMUX_AGENT_BAR_FAKE_RENDER_CACHED="#[fg=#82aaff] PR review 🔎#[fg=default] " \
    TMUX_FAKE_INVOCATIONS_FILE="${tmp_dir}/tmux-invocations" \
    "${REFRESH_WRAPPER}" 'PR review 🔎' --cached --refresh-client --client /dev/ttys001
    cat "${tmp_dir}/tmux-invocations"
  )

  assert_equal \
    "refresh wrapper redraws the hook client after updating a named session option" \
    $'set\tPR review 🔎\t@tmux_agent_bar_status_right\t#[fg=#82aaff] PR review 🔎#[fg=default] \nrefresh\t/dev/ttys001' \
    "${actual}"

  rm -rf "${tmp_dir}"
}

run_refresh_wrapper_full_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  make_fake_runtime "${tmp_dir}/runtime"
  mkdir -p "${tmp_dir}/bin"

  cat > "${tmp_dir}/bin/tmux" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "set-option" && "${2:-}" == "-q" && "${3:-}" == "-t" ]]; then
  printf '%s\t%s\t%s\n' "${4:-}" "${5:-}" "${6:-}" > "${TMUX_FAKE_SET_OPTION_FILE}"
  exit 0
fi
exit 1
EOF
  chmod +x "${tmp_dir}/bin/tmux"

  actual=$(
    PATH="${tmp_dir}/bin:${PATH}" \
    TMUX_AGENT_BAR_DIR="${tmp_dir}/runtime" \
    TMUX_AGENT_BAR_EXPECTED_RENDER_TARGET='$23' \
    TMUX_AGENT_BAR_FAKE_RENDER="#[fg=#82aaff] other#[fg=default] " \
    TMUX_FAKE_SET_OPTION_FILE="${tmp_dir}/set-option" \
    "${REFRESH_WRAPPER}" '$23'
    cat "${tmp_dir}/set-option"
  )

  assert_equal \
    "refresh wrapper stores the refreshed right side in the session option" \
    $'$23\t@tmux_agent_bar_status_right\t#[fg=#82aaff] other#[fg=default] ' \
    "${actual}"

  rm -rf "${tmp_dir}"
}

run_refresh_wrapper_force_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  make_fake_runtime "${tmp_dir}/runtime"
  mkdir -p "${tmp_dir}/bin"

  cat > "${tmp_dir}/bin/tmux" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  set-option)
    if [[ "${2:-}" == "-q" && "${3:-}" == "-t" ]]; then
      printf 'set\t%s\t%s\t%s\n' "${4:-}" "${5:-}" "${6:-}" >> "${TMUX_FAKE_INVOCATIONS_FILE}"
      exit 0
    fi
    ;;
  refresh-client)
    if [[ "${2:-}" == "-S" && "${3:-}" == "-t" ]]; then
      printf 'refresh\t%s\n' "${4:-}" >> "${TMUX_FAKE_INVOCATIONS_FILE}"
      exit 0
    fi
    ;;
esac
exit 1
EOF
  chmod +x "${tmp_dir}/bin/tmux"

  actual=$(
    PATH="${tmp_dir}/bin:${PATH}" \
    TMUX_AGENT_BAR_DIR="${tmp_dir}/runtime" \
    TMUX_AGENT_BAR_EXPECTED_RENDER_TARGET='remote-one' \
    TMUX_AGENT_BAR_FAKE_RENDER_CACHED="#[fg=#21c7a8] cached#[fg=default] " \
    TMUX_AGENT_BAR_FAKE_RENDER="#[fg=#82aaff] fresh#[fg=default] " \
    TMUX_AGENT_BAR_FAKE_INVOCATIONS_FILE="${tmp_dir}/tmux-invocations" \
    TMUX_FAKE_INVOCATIONS_FILE="${tmp_dir}/tmux-invocations" \
    "${REFRESH_WRAPPER}" 'remote-one' --force-refresh --foreground-fresh --refresh-client --client /dev/ttys001
    cat "${tmp_dir}/tmux-invocations"
  )

  assert_equal \
    "force refresh writes cached status first, then forces a fresh render" \
    $'runtime\trender-cached\tremote-one\tforce=\nset\tremote-one\t@tmux_agent_bar_status_right\t#[fg=#21c7a8] cached#[fg=default] \nrefresh\t/dev/ttys001\nruntime\trender\tremote-one\tforce=1\nset\tremote-one\t@tmux_agent_bar_status_right\t#[fg=#82aaff] fresh#[fg=default] \nrefresh\t/dev/ttys001' \
    "${actual}"

  rm -rf "${tmp_dir}"
}

run_refresh_wrapper_all_clients_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  make_fake_runtime "${tmp_dir}/runtime"
  mkdir -p "${tmp_dir}/bin"

  cat > "${tmp_dir}/bin/tmux" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  list-clients)
    if [[ "${2:-}" == "-F" ]]; then
      printf '%s\t%s\n' "/dev/ttys001" "current one"
      printf '%s\t%s\n' "/dev/ttys002" "current two"
      exit 0
    fi
    ;;
  set-option)
    if [[ "${2:-}" == "-q" && "${3:-}" == "-t" ]]; then
      printf 'set\t%s\t%s\t%s\n' "${4:-}" "${5:-}" "${6:-}" >> "${TMUX_FAKE_INVOCATIONS_FILE}"
      exit 0
    fi
    ;;
  refresh-client)
    if [[ "${2:-}" == "-S" && "${3:-}" == "-t" ]]; then
      printf 'refresh\t%s\n' "${4:-}" >> "${TMUX_FAKE_INVOCATIONS_FILE}"
      exit 0
    fi
    ;;
esac
exit 1
EOF
  chmod +x "${tmp_dir}/bin/tmux"

  actual=$(
    PATH="${tmp_dir}/bin:${PATH}" \
    TMUX_AGENT_BAR_DIR="${tmp_dir}/runtime" \
    TMUX_AGENT_BAR_FAKE_RENDER_CACHED="#[fg=#21c7a8] cached#[fg=default] " \
    TMUX_AGENT_BAR_FAKE_RENDER="#[fg=#82aaff] fresh#[fg=default] " \
    TMUX_AGENT_BAR_FAKE_INVOCATIONS_FILE="${tmp_dir}/tmux-invocations" \
    TMUX_FAKE_INVOCATIONS_FILE="${tmp_dir}/tmux-invocations" \
    "${REFRESH_WRAPPER}" --all-clients --force-refresh --foreground-fresh --refresh-client
    cat "${tmp_dir}/tmux-invocations"
  )

  assert_equal \
    "all-clients force refresh updates each attached client's current session" \
    $'runtime\trender-cached\tcurrent one\tforce=\nset\tcurrent one\t@tmux_agent_bar_status_right\t#[fg=#21c7a8] cached#[fg=default] \nrefresh\t/dev/ttys001\nruntime\trender\tcurrent one\tforce=1\nset\tcurrent one\t@tmux_agent_bar_status_right\t#[fg=#82aaff] fresh#[fg=default] \nrefresh\t/dev/ttys001\nruntime\trender-cached\tcurrent two\tforce=\nset\tcurrent two\t@tmux_agent_bar_status_right\t#[fg=#21c7a8] cached#[fg=default] \nrefresh\t/dev/ttys002\nruntime\trender\tcurrent two\tforce=1\nset\tcurrent two\t@tmux_agent_bar_status_right\t#[fg=#82aaff] fresh#[fg=default] \nrefresh\t/dev/ttys002' \
    "${actual}"

  rm -rf "${tmp_dir}"
}

run_session_switch_hook_case() {
  local actual=""

  actual=$(grep -E '^set-hook -g (client-(session-changed|attached)|session-closed)' "${TMUX_CONF}" || true)

  assert_matches \
    "session switch hook targets the changed client's session name" \
    'client-session-changed.*#\{q:client_session\}.*--force-refresh.*--refresh-client.*#\{q:hook_client\}' \
    "${actual}"
  assert_matches \
    "client attach hook targets the attached client's session name" \
    'client-attached.*#\{q:client_session\}.*--force-refresh.*--refresh-client.*#\{q:hook_client\}' \
    "${actual}"
  assert_matches \
    "session close hook refreshes all attached client sessions" \
    'session-closed.*--all-clients.*--force-refresh.*--refresh-client' \
    "${actual}"
}

run_status_right_uses_cached_option_case() {
  local actual=""

  actual=$(grep -E 'status-right.*tmux_agent_bar_status_right' "${TMUX_CONF}" || true)

  assert_matches \
    "status-right reads the cached tmux option" \
    'status-right.*#\{@tmux_agent_bar_status_right\}' \
    "${actual}"

  if grep -Eq 'status-right.*session-status-refresh\.sh' "${TMUX_CONF}"; then
    fail "status-right should not poll session-status-refresh.sh"
  fi
}

run_missing_runtime_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  actual=$(TMUX_AGENT_BAR_DIR="${tmp_dir}/missing" "${SESSION_WRAPPER}" alpha beta)
  assert_equal "wrappers exit cleanly when the runtime is missing" "" "${actual}"
  rm -rf "${tmp_dir}"
}

run_session_wrapper_case
run_hook_wrapper_case
run_codex_hook_wrapper_case
run_codex_hook_missing_runtime_case
run_left_wrapper_case
run_left_wrapper_fallback_case
run_refresh_wrapper_cached_case
run_refresh_wrapper_client_refresh_case
run_refresh_wrapper_full_case
run_refresh_wrapper_force_case
run_refresh_wrapper_all_clients_case
run_session_switch_hook_case
run_status_right_uses_cached_option_case
run_missing_runtime_case
