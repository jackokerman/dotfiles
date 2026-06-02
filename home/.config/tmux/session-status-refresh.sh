#!/usr/bin/env bash
set -euo pipefail

_tmux_agent_bar_path_helper="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/tmux-agent-bar-path.sh"

# shellcheck source=/dev/null
source "${_tmux_agent_bar_path_helper}"

_tmux_agent_bar_repo="$(tmux_agent_bar_runtime_repo_path)"
_tmux_agent_bar_bin="${_tmux_agent_bar_repo}/bin/tmux-agent-bar"
_target="${1:-}"
_mode_cached=0
_force_refresh=0
_refresh_client=0
_client=""
_rendered=""

[[ -x "${_tmux_agent_bar_bin}" ]] || exit 0
[[ -n "${_target}" ]] || exit 0

shift || true
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --cached)
      _mode_cached=1
      ;;
    --force-refresh)
      _force_refresh=1
      ;;
    --refresh-client)
      _refresh_client=1
      ;;
    --client)
      shift
      _client="${1:-}"
      ;;
  esac
  shift || true
done

refresh_client() {
  if (( ! _refresh_client )); then
    return 0
  fi

  if [[ -n "${_client}" ]]; then
    tmux refresh-client -S -t "${_client}" 2>/dev/null || true
  else
    tmux refresh-client -S 2>/dev/null || true
  fi
}

store_rendered_status() {
  local mode="$1"

  if [[ "${mode}" == "cached" ]]; then
    _rendered="$("${_tmux_agent_bar_bin}" render-cached "${_target}" 2>/dev/null || true)"
  else
    _rendered="$(TMUX_AGENT_BAR_FORCE_REFRESH=1 "${_tmux_agent_bar_bin}" render "${_target}" 2>/dev/null || true)"
  fi

  tmux set-option -q -t "${_target}" @tmux_agent_bar_status_right "${_rendered}" 2>/dev/null || true
}

if (( _force_refresh )); then
  store_rendered_status "cached"
  refresh_client
  store_rendered_status "fresh"
elif (( _mode_cached )); then
  _rendered="$("${_tmux_agent_bar_bin}" render-cached "${_target}" 2>/dev/null || true)"
  tmux set-option -q -t "${_target}" @tmux_agent_bar_status_right "${_rendered}" 2>/dev/null || true
else
  _rendered="$("${_tmux_agent_bar_bin}" render "${_target}" 2>/dev/null || true)"
  tmux set-option -q -t "${_target}" @tmux_agent_bar_status_right "${_rendered}" 2>/dev/null || true
fi

refresh_client
