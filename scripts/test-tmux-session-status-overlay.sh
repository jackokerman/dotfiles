#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
TARGET_SCRIPT="${PROJECT_ROOT}/home/.config/tmux/session-status.sh"

pass() {
  printf '[tmux-overlay-test] pass: %s\n' "$1"
}

fail() {
  printf '[tmux-overlay-test] fail: %s\n' "$1" >&2
  exit 1
}

assert_equal() {
  local name="$1" expected="$2" actual="$3"

  if [[ "${actual}" == "${expected}" ]]; then
    pass "${name}"
    return 0
  fi

  printf '[tmux-overlay-test] fail: %s\n' "${name}" >&2
  printf '[tmux-overlay-test] expected: %q\n' "${expected}" >&2
  printf '[tmux-overlay-test] actual: %q\n' "${actual}" >&2
  exit 1
}

run_case() {
  local name="$1" expected="$2" local_rows="$3" overlay_body="$4" require_marker="${5:-0}"
  local tmp_dir="" overlay_script="" marker_file="" actual=""

  tmp_dir=$(mktemp -d)
  overlay_script="${tmp_dir}/overlay.sh"
  marker_file="${tmp_dir}/refresh-marker"

  if [[ -n "${overlay_body}" ]]; then
    printf '%s\n' "${overlay_body}" > "${overlay_script}"
  else
    rm -f "${overlay_script}"
  fi

  actual=$(
    CURRENT_SESSION="current" \
    LOCAL_ROWS="${local_rows}" \
    OVERLAY_MARKER="${marker_file}" \
    TMUX_SESSION_STATUS_OVERLAY_SCRIPT="${overlay_script}" \
    TARGET_SCRIPT="${TARGET_SCRIPT}" \
    "${BASH}" <<'EOF'
set -euo pipefail

source "${TARGET_SCRIPT}"

tmux_session_status_current_session() {
  printf '%s\n' "${CURRENT_SESSION}"
}

tmux_session_status_local_emit_records() {
  printf '%b' "${LOCAL_ROWS}"
}

tmux_session_status_prune_orphan_state_files() {
  :
}

tmux_session_status_main
EOF
  )

  assert_equal "${name}" "${expected}" "${actual}"

  if [[ "${require_marker}" == "1" ]] && [[ ! -f "${marker_file}" ]]; then
    fail "${name} refresh hook was not called"
  fi

  rm -rf "${tmp_dir}"
}

run_case \
  "overlay records render and local records win on duplicate labels" \
  $'#[fg=#82aaff] local-only#[fg=default]  #[fg=#e3d18a] shared#[fg=default]  #[fg=#21c7a8] overlay-only#[fg=default] ' \
  $'local-only\tcodex\tworking\tlocal_explicit\t10\nshared\tcodex\twaiting\tlocal_explicit\t20\ncurrent\tcodex\tworking\tlocal_explicit\t30\n' \
  $'tmux_agent_overlay_maybe_refresh() {\n  : > "${OVERLAY_MARKER}"\n}\n\ntmux_agent_overlay_emit_records() {\n  printf \'shared\\tcodex\\tdone\\tremote_mirror\\t40\\n\'\n  printf \'overlay-only\\tclaude\\tdone\\tremote_mirror\\t50\\n\'\n}\n' \
  "1"

run_case \
  "session status works without any overlay script" \
  $'#[fg=#21c7a8] solo#[fg=default] ' \
  $'current\tcodex\tworking\tlocal_explicit\t10\nsolo\tclaude\tdone\tlocal_fallback\t0\n' \
  ""
