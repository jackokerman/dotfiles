#!/usr/bin/env bash
set -euo pipefail

_session_name="${1:-}"
_state_dir="${STATE_DIR:-/tmp/tmux-agent-$(id -u)}"
_safe_name="${_session_name//\//%2F}"
_state_file="${_state_dir}/${_safe_name}"
_current_state_file="${XDG_CACHE_HOME:-$HOME/.cache}/tmux-agent-bar/current-state/${_safe_name}"
_agent=""
_state=""

if [[ -n "${_session_name}" && -f "${_state_file}" ]]; then
  IFS=$'\t' read -r _agent _state < "${_state_file}" || true
  if [[ -z "${_state}" ]]; then
    _state="${_agent}"
  fi
elif [[ -n "${_session_name}" && -f "${_current_state_file}" ]]; then
  IFS= read -r _state < "${_current_state_file}" || true
fi

case "${_state}" in
  waiting)
    printf '%s' "#[fg=#e3d18a] "
    ;;
  working)
    printf '%s' "#[fg=#82aaff] "
    ;;
  done)
    printf '%s' "#[fg=#21c7a8] "
    ;;
  *)
    printf '%s' "#[fg=#f78c6c]⠶ #[fg=#82aaff]"
    ;;
esac
