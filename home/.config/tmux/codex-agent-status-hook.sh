#!/usr/bin/env bash
set -euo pipefail

_tmux_agent_bar_path_helper="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/tmux-agent-bar-path.sh"

# shellcheck source=/dev/null
source "${_tmux_agent_bar_path_helper}"

_tmux_agent_bar_repo="$(tmux_agent_bar_runtime_repo_path)"
_tmux_agent_bar_bin="${_tmux_agent_bar_repo}/bin/tmux-agent-bar-codex-hook"
_refresh_wrapper="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/session-status-refresh.sh"

[[ -x "${_tmux_agent_bar_bin}" ]] || exit 0

"${_tmux_agent_bar_bin}" "$@"

if [[ -x "${_refresh_wrapper}" ]]; then
  "${_refresh_wrapper}" --all-clients --cached --refresh-client >/dev/null 2>&1 || true
fi
