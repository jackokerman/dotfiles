#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
SESSION_WRAPPER="${PROJECT_ROOT}/home/.config/tmux/session-status.sh"
LEFT_WRAPPER="${PROJECT_ROOT}/home/.config/tmux/session-status-left.sh"
REFRESH_WRAPPER="${PROJECT_ROOT}/home/.config/tmux/session-status-refresh.sh"
HOOK_WRAPPER="${PROJECT_ROOT}/home/.config/tmux/agent-status-hook.sh"
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
    printf '%s' "${TMUX_AGENT_BAR_FAKE_RENDER:-}"
    ;;
  render-cached)
    if [[ -n "${TMUX_AGENT_BAR_EXPECTED_RENDER_TARGET:-}" ]] && [[ "${2:-}" != "${TMUX_AGENT_BAR_EXPECTED_RENDER_TARGET}" ]]; then
      exit 1
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

  chmod +x "${runtime_dir}/bin/tmux-agent-bar" "${runtime_dir}/bin/tmux-agent-bar-hook"
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

run_missing_runtime_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  actual=$(TMUX_AGENT_BAR_DIR="${tmp_dir}/missing" "${SESSION_WRAPPER}" alpha beta)
  assert_equal "wrappers exit cleanly when the runtime is missing" "" "${actual}"
  rm -rf "${tmp_dir}"
}

run_session_wrapper_case
run_hook_wrapper_case
run_left_wrapper_case
run_left_wrapper_fallback_case
run_refresh_wrapper_cached_case
run_refresh_wrapper_full_case
run_missing_runtime_case
