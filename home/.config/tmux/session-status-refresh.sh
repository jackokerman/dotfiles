#!/usr/bin/env bash
set -euo pipefail

_tmux_agent_bar_path_helper="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/tmux-agent-bar-path.sh"

# shellcheck source=/dev/null
source "${_tmux_agent_bar_path_helper}"

_tmux_agent_bar_repo="$(tmux_agent_bar_runtime_repo_path)"
_tmux_agent_bar_bin="${_tmux_agent_bar_repo}/bin/tmux-agent-bar"
_target="${1:-}"
_mode="${2:-}"
_rendered=""

[[ -x "${_tmux_agent_bar_bin}" ]] || exit 0
[[ -n "${_target}" ]] || exit 0

if [[ "${_mode}" == "--cached" ]]; then
  _rendered="$("${_tmux_agent_bar_bin}" render-cached "${_target}" 2>/dev/null || true)"
else
  _rendered="$("${_tmux_agent_bar_bin}" render "${_target}" 2>/dev/null || true)"
fi

tmux set-option -q -t "${_target}" @tmux_agent_bar_status_right "${_rendered}" 2>/dev/null || true
