#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
SESSION_WRAPPER="${PROJECT_ROOT}/home/.config/tmux/session-status.sh"
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
printf 'session:%s\n' "$*"
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

run_missing_runtime_case() {
  local tmp_dir="" actual=""

  tmp_dir=$(mktemp -d)
  actual=$(TMUX_AGENT_BAR_DIR="${tmp_dir}/missing" "${SESSION_WRAPPER}" alpha beta)
  assert_equal "wrappers exit cleanly when the runtime is missing" "" "${actual}"
  rm -rf "${tmp_dir}"
}

run_session_wrapper_case
run_hook_wrapper_case
run_missing_runtime_case
