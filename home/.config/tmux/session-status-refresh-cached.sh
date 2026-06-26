#!/usr/bin/env bash
set -euo pipefail

_refresh_wrapper="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/session-status-refresh.sh"
_timeout_wrapper="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/tmux-run-with-timeout.sh"
_lock_dir="${XDG_CACHE_HOME:-$HOME/.cache}/tmux-agent-bar/session-status-refresh-cached.lock"
_lock_pid_file="${_lock_dir}/pid"

refresh_lock_is_stale() {
  local lock_pid=""

  [[ -f "${_lock_pid_file}" ]] || return 0

  lock_pid=$(<"${_lock_pid_file}")
  [[ "${lock_pid}" =~ ^[0-9]+$ ]] || return 0

  ! kill -0 "${lock_pid}" 2>/dev/null
}

acquire_refresh_lock() {
  mkdir -p "$(dirname "${_lock_dir}")"

  if mkdir "${_lock_dir}" 2>/dev/null; then
    printf '%s\n' "$$" > "${_lock_pid_file}"
    return 0
  fi

  if refresh_lock_is_stale; then
    rm -rf "${_lock_dir}"
    if mkdir "${_lock_dir}" 2>/dev/null; then
      printf '%s\n' "$$" > "${_lock_pid_file}"
      return 0
    fi
  fi

  return 1
}

release_refresh_lock() {
  rm -rf "${_lock_dir}" 2>/dev/null || true
}

[[ -x "${_refresh_wrapper}" ]] || exit 0
[[ -x "${_timeout_wrapper}" ]] || exit 0

acquire_refresh_lock || exit 0
trap 'release_refresh_lock' EXIT

"${_timeout_wrapper}" 2 "${_refresh_wrapper}" --all-clients --cached
