#!/usr/bin/env bash
# Show coding agent session status for other tmux sessions in the status bar.
set -euo pipefail

STATE_DIR="/tmp/tmux-agent-$(id -u)"
KNOWN_AGENT_COMMANDS=(claude codex)
REMOTE_TRANSPORT_COMMANDS=(pty-cli)
_agent_pane_state_lib="${HOME}/.config/tmux/agent-pane-state.sh"

if [[ -r "${_agent_pane_state_lib}" ]]; then
  # shellcheck source=/dev/null
  source "${_agent_pane_state_lib}"
fi

_decode_session_name() {
  local safe_name="$1"
  printf '%s\n' "${safe_name//%2F/\/}"
}

_read_state_record() {
  local state_file="$1" raw="" agent="" state=""
  raw=$(<"${state_file}")
  IFS=$'\t' read -r agent state <<< "${raw}"

  # Backward compatibility with the legacy format: the file only contained
  # the state string, e.g. "working".
  if [[ -z "${state}" ]]; then
    state="${agent}"
    agent="claude"
  fi

  printf '%s\t%s\n' "${agent}" "${state}"
}

_session_has_pane_command() {
  local session="$1" cmd wanted

  while IFS= read -r cmd; do
    for wanted in "${@:2}"; do
      if [[ "${cmd}" == "${wanted}" ]]; then
        return 0
      fi
    done
  done < <(tmux list-panes -t "${session}" -F '#{pane_current_command}' 2>/dev/null)

  return 1
}

_session_has_known_agent_pane() {
  _session_has_pane_command "$1" "${KNOWN_AGENT_COMMANDS[@]}"
}

_session_has_remote_transport_pane() {
  _session_has_pane_command "$1" "${REMOTE_TRANSPORT_COMMANDS[@]}"
}

_session_has_live_agent_process() {
  local session="$1" agent="${2:-}" pane_pids="" line="" pid="" comm="" current_pid="" parent_pid=""
  local -a target_agents=()

  pane_pids=$(tmux list-panes -t "${session}" -F '#{pane_pid}' 2>/dev/null || true)
  [[ -n "${pane_pids//[[:space:]]/}" ]] || return 1

  case "${agent}" in
    claude|codex)
      target_agents=("${agent}")
      ;;
    *)
      target_agents=("${KNOWN_AGENT_COMMANDS[@]}")
      ;;
  esac

  while IFS= read -r line; do
    [[ -n "${line}" ]] || continue
    read -r pid _ppid comm <<< "${line}"
    [[ "${pid}" =~ ^[0-9]+$ ]] || continue

    case " ${target_agents[*]} " in
      *" ${comm} "*) ;;
      *) continue ;;
    esac

    current_pid="${pid}"
    while [[ -n "${current_pid}" && "${current_pid}" != "1" ]]; do
      if printf '%s\n' "${pane_pids}" | grep -qx "${current_pid}"; then
        return 0
      fi

      parent_pid=$(ps -o ppid= -p "${current_pid}" 2>/dev/null | tr -d '[:space:]')
      [[ "${parent_pid}" =~ ^[0-9]+$ ]] || break
      [[ "${parent_pid}" != "${current_pid}" ]] || break
      current_pid="${parent_pid}"
    done
  done < <(ps -eo pid=,ppid=,comm= 2>/dev/null || true)

  return 1
}

_session_agent_command() {
  local session="$1" cmd known_cmd

  while IFS= read -r cmd; do
    for known_cmd in "${KNOWN_AGENT_COMMANDS[@]}"; do
      if [[ "${cmd}" == "${known_cmd}" ]]; then
        printf '%s\n' "${known_cmd}"
        return 0
      fi
    done
  done < <(tmux list-panes -t "${session}" -F '#{pane_current_command}' 2>/dev/null)

  return 1
}

_session_live_state() {
  local session="$1" agent="${2:-}"

  if declare -F tmux_agent_session_live_state >/dev/null 2>&1; then
    tmux_agent_session_live_state "${session}" "${agent}"
    return 0
  fi

  # Prefer no live inference over drifting away from the shared classifier.
  printf '%s\n' ""
}

_state_file_has_stale_working() {
  local state_file="$1"

  if declare -F tmux_agent_state_is_stale_working >/dev/null 2>&1; then
    tmux_agent_state_is_stale_working "${state_file}"
    return $?
  fi

  return 1
}

tmux_session_status_resolve_state() {
  local explicit_state="$1" live_state="$2" has_known_agent_pane="${3:-0}" stale_working="${4:-0}" agent_mismatch="${5:-0}"
  local state="${explicit_state}"

  if [[ -n "${state}" ]]; then
    if [[ "${has_known_agent_pane}" == "1" ]]; then
      if [[ "${agent_mismatch}" == "1" ]]; then
        state="done"
      fi

      if [[ -n "${live_state}" ]]; then
        state="${live_state}"
      elif [[ "${state}" == "working" && "${stale_working}" == "1" ]]; then
        state="done"
      fi
    elif [[ "${state}" == "working" && "${stale_working}" == "1" ]]; then
      state="done"
    fi

    printf '%s\n' "${state}"
    return 0
  fi

  if [[ "${has_known_agent_pane}" != "1" ]]; then
    printf '%s\n' ""
    return 0
  fi

  if [[ -n "${live_state}" ]]; then
    printf '%s\n' "${live_state}"
  else
    printf '%s\n' "done"
  fi
}

_render_session() {
  local name="$1" state="$2"
  case "${state}" in
    waiting) output="${output}${sep}#[fg=#e3d18a] ${name}#[fg=default]" ;;
    working) output="${output}${sep}#[fg=#82aaff] ${name}#[fg=default]" ;;
    *)       output="${output}${sep}#[fg=#21c7a8] ${name}#[fg=default]" ;;
  esac
  sep="  "
}

tmux_session_status_main() {
  local current="" _remote_sync="" _sync_ts="" _now="" session="" safe="" state="" active_agent="" _agent="" live_state=""
  local has_known_agent_pane=0 stale_working=0 agent_mismatch=0
  local output="" sep="" state_file="" safe_name="" real_name=""
  declare -A rendered_local=()

  current=$(tmux display-message -p '#{session_name}')

  # Trigger remote devbox sync if the overlay script exists.
  _remote_sync="${HOME}/.config/tmux/remote-agent-sync.sh"
  _sync_ts="${STATE_DIR}/.remote-sync-ts"
  if [[ -x "${_remote_sync}" ]]; then
    _now=$(date +%s)
    if [[ ! -f "${_sync_ts}" ]] || (( _now - $(<"${_sync_ts}") > 10 )); then
      echo "${_now}" > "${_sync_ts}"
      ("${_remote_sync}" &)
    fi
  fi

  while IFS= read -r session; do
    [[ "${session}" != "${current}" ]] || continue

    safe="${session//\//%2F}"
    state=""
    active_agent=""
    live_state=""
    _agent=""
    has_known_agent_pane=0
    stale_working=0
    agent_mismatch=0

    if [[ -f "${STATE_DIR}/${safe}" ]]; then
      IFS=$'\t' read -r _agent state < <(_read_state_record "${STATE_DIR}/${safe}")

      if [[ "${state}" == "done" ]] && [[ " ${KNOWN_AGENT_COMMANDS[*]} " == *" ${_agent} "* ]] && \
         ! _session_has_live_agent_process "${session}" "${_agent}"; then
        rm -f "${STATE_DIR}/${safe}"
        continue
      fi

      if _session_has_known_agent_pane "${session}"; then
        has_known_agent_pane=1
        active_agent=$(_session_agent_command "${session}" 2>/dev/null || true)
        if [[ -n "${active_agent}" && "${active_agent}" != "${_agent}" ]]; then
          agent_mismatch=1
        fi
        live_state=$(_session_live_state "${session}" "${active_agent:-${_agent}}")
        if [[ "${state}" == "working" ]] && [[ -z "${live_state}" ]] && _state_file_has_stale_working "${STATE_DIR}/${safe}"; then
          # Hooks give us fast transitions into working, but without a matching
          # live signal that state should not stick forever.
          stale_working=1
        fi
      elif [[ "${state}" == "working" ]] && _state_file_has_stale_working "${STATE_DIR}/${safe}"; then
        # For shell-wrapped or remote-mirrored agents, trust the explicit state
        # file but keep the same stale-working guard as known local agents.
        stale_working=1
      fi

      state=$(tmux_session_status_resolve_state "${state}" "${live_state}" "${has_known_agent_pane}" "${stale_working}" "${agent_mismatch}")
    elif _session_has_remote_transport_pane "${session}"; then
      continue
    elif ! _session_has_known_agent_pane "${session}"; then
      continue
    else
      active_agent=$(_session_agent_command "${session}" 2>/dev/null || true)
      live_state=$(_session_live_state "${session}" "${active_agent}")
      state=$(tmux_session_status_resolve_state "" "${live_state}" 1 0 0)
    fi

    rendered_local["${session}"]=1
    _render_session "${session}" "${state}"
  done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null)

  # Remove state files for sessions that no longer exist in tmux.
  if [[ -d "${STATE_DIR}" ]]; then
    for state_file in "${STATE_DIR}"/*; do
      [[ -f "${state_file}" ]] || continue
      safe_name=$(basename "${state_file}")
      [[ "${safe_name}" == ".remote-sync-ts" ]] && continue
      real_name="${safe_name//%2F/\/}"
      tmux has-session -t "${real_name}" 2>/dev/null || rm -f "${state_file}"
    done
  fi

  # Append remote devbox sessions from cache, skipping any already rendered in
  # the local section (avoids duplicates when a local session runs an agent directly).
  if [[ -d "${STATE_DIR}/remote" ]]; then
    for state_file in "${STATE_DIR}/remote"/*; do
      [[ -f "${state_file}" ]] || continue
      safe_name=$(basename "${state_file}")
      session=$(_decode_session_name "${safe_name}")
      [[ "${session}" != "${current}" ]] || continue
      [[ -z "${rendered_local[${session}]+x}" ]] || continue
      IFS=$'\t' read -r _agent state < <(_read_state_record "${state_file}")
      _render_session "${session}" "${state}"
    done
  fi

  if [[ -n "${output}" ]]; then
    printf '%s ' "${output}"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  tmux_session_status_main "$@"
fi
