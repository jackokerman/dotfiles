#!/usr/bin/env bash
set -euo pipefail

_tmux_agent_bar_path_helper="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/tmux-agent-bar-path.sh"

# shellcheck source=/dev/null
source "${_tmux_agent_bar_path_helper}"

_tmux_agent_bar_repo="$(tmux_agent_bar_runtime_repo_path)"
_tmux_agent_bar_bin="${_tmux_agent_bar_repo}/bin/tmux-agent-bar"
_current_target="${1:-}"

[[ -x "${_tmux_agent_bar_bin}" ]] || exit 0

_state="$("${_tmux_agent_bar_bin}" current-state-cached "${_current_target}" 2>/dev/null || true)"

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
