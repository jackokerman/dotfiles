#!/usr/bin/env bash
set -euo pipefail

_tmux_agent_bar_path_helper="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/tmux-agent-bar-path.sh"

# shellcheck source=/dev/null
source "${_tmux_agent_bar_path_helper}"

_tmux_agent_bar_repo="$(tmux_agent_bar_runtime_repo_path)"
_tmux_agent_bar_bin="${_tmux_agent_bar_repo}/bin/tmux-agent-bar"
_current_target="${1:-}"

if [[ -n "${_current_target}" ]]; then
  _current_session="$(tmux display-message -p -t "${_current_target}" '#{session_name}' 2>/dev/null || printf '%s\n' "${_current_target}")"
else
  _current_session="$(tmux display-message -p '#{session_name}' 2>/dev/null || true)"
fi

[[ -x "${_tmux_agent_bar_bin}" ]] || exit 0
[[ -n "${_current_session}" ]] || exit 0

if [[ -n "${_current_target}" ]]; then
  _state="$("${_tmux_agent_bar_bin}" current-state "${_current_target}" 2>/dev/null || true)"
else
  _state="$("${_tmux_agent_bar_bin}" current-state 2>/dev/null || true)"
fi

case "${_state}" in
  waiting)
    printf '%s' "#[fg=#e3d18a] ${_current_session}#[fg=default] "
    ;;
  working)
    printf '%s' "#[fg=#82aaff] ${_current_session}#[fg=default] "
    ;;
  done)
    printf '%s' "#[fg=#21c7a8] ${_current_session}#[fg=default] "
    ;;
  *)
    printf '%s' "#[fg=#f78c6c]⠶ #[fg=#82aaff]${_current_session}#[fg=default] "
    ;;
esac
