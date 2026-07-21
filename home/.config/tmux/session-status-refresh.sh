#!/usr/bin/env bash
set -euo pipefail

_tmux_agent_bar_path_helper="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/tmux-agent-bar-path.sh"

# shellcheck source=/dev/null
source "${_tmux_agent_bar_path_helper}"

_tmux_agent_bar_repo="$(tmux_agent_bar_runtime_repo_path)"
_tmux_agent_bar_bin="${_tmux_agent_bar_repo}/bin/tmux-agent-bar"
_timeout_wrapper="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/tmux-run-with-timeout.sh"
# A remote source refresh can try several session candidates with a per-probe
# budget. Keep the wrapper above that bounded source path so tmux does not kill
# a healthy fallback probe mid-refresh.
_render_timeout_seconds=50
_target=""
_all_clients=0
_mode_cached=0
_force_refresh=0
_refresh_client=0
_background_fresh=1
_client=""
_rendered=""
_current_state=""

[[ -x "${_tmux_agent_bar_bin}" ]] || exit 0

render_status() {
  local mode="$1"

  if [[ -x "${_timeout_wrapper}" ]]; then
    "${_timeout_wrapper}" "${_render_timeout_seconds}" "${_tmux_agent_bar_bin}" "${mode}" "${_target}" 2>/dev/null
    return "$?"
  fi

  "${_tmux_agent_bar_bin}" "${mode}" "${_target}" 2>/dev/null
}

current_state_cache_file() {
  local safe_target="${_target//\//%2F}"

  printf '%s/tmux-agent-bar/current-state/%s\n' "${XDG_CACHE_HOME:-$HOME/.cache}" "${safe_target}"
}

store_current_state() {
  local mode="${1:-current-state-cached}"
  local state_file=""

  [[ -n "${_target}" ]] || return 0
  if ! _current_state="$(render_status "${mode}")"; then
    return 1
  fi

  state_file=$(current_state_cache_file)
  if [[ -n "${_current_state}" ]]; then
    mkdir -p "$(dirname "${state_file}")"
    printf '%s\n' "${_current_state}" > "${state_file}"
  else
    rm -f "${state_file}" 2>/dev/null || true
  fi
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --all-clients)
      _all_clients=1
      ;;
    --cached)
      _mode_cached=1
      ;;
    --force-refresh)
      _force_refresh=1
      ;;
    --refresh-client)
      _refresh_client=1
      ;;
    --foreground-fresh)
      _background_fresh=0
      ;;
    --client)
      shift
      _client="${1:-}"
      ;;
    *)
      if [[ -z "${_target}" ]]; then
        _target="$1"
      fi
      ;;
  esac
  shift || true
done

if (( ! _all_clients )) && [[ -z "${_target}" ]]; then
  exit 0
fi

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

store_fresh_status() {
  if ! _rendered="$(TMUX_AGENT_BAR_FORCE_REFRESH=1 render_status render)"; then
    return 1
  fi

  tmux set-option -q -t "${_target}" @tmux_agent_bar_status_right "${_rendered}" 2>/dev/null || true
  store_current_state current-state || true
}

store_rendered_status() {
  local mode="$1"

  if [[ "${mode}" == "cached" ]]; then
    if ! _rendered="$(render_status render-cached)"; then
      return 1
    fi
  else
    store_fresh_status
    return 0
  fi

  tmux set-option -q -t "${_target}" @tmux_agent_bar_status_right "${_rendered}" 2>/dev/null || true
  store_current_state || true
}

refresh_fresh_later() {
  if (( _background_fresh )); then
    (
      store_fresh_status || true
      refresh_client
    ) >/dev/null 2>&1 &
    return 0
  fi

  store_fresh_status || true
  refresh_client
}

refresh_target() {
  if (( _force_refresh )); then
    store_rendered_status "cached" || true
    refresh_client
    refresh_fresh_later
    return 0
  elif (( _mode_cached )); then
    if ! _rendered="$(render_status render-cached)"; then
      return 0
    fi
    tmux set-option -q -t "${_target}" @tmux_agent_bar_status_right "${_rendered}" 2>/dev/null || true
    store_current_state || true
  else
    if ! _rendered="$(render_status render)"; then
      return 0
    fi
    tmux set-option -q -t "${_target}" @tmux_agent_bar_status_right "${_rendered}" 2>/dev/null || true
    store_current_state current-state || true
  fi

  refresh_client
}

refresh_all_clients() {
  local client_session="" client_name="" original_target="" original_client=""

  original_target="${_target}"
  original_client="${_client}"

  while IFS=$'\t' read -r client_name client_session || [[ -n "${client_name:-}${client_session:-}" ]]; do
    [[ -n "${client_session}" ]] || continue
    _target="${client_session}"
    _client="${client_name}"
    refresh_target
  done < <(tmux list-clients -F '#{client_name}'$'\t''#{client_session}' 2>/dev/null || true)

  _target="${original_target}"
  _client="${original_client}"
}

if (( _all_clients )); then
  refresh_all_clients
else
  refresh_target
fi
