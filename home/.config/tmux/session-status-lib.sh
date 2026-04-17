#!/usr/bin/env bash

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

_state_file_mtime() {
  local state_file="$1" updated_at=""

  if declare -F tmux_agent_state_file_mtime >/dev/null 2>&1; then
    updated_at=$(tmux_agent_state_file_mtime "${state_file}" 2>/dev/null || true)
  fi

  if [[ ! "${updated_at}" =~ ^[0-9]+$ ]]; then
    updated_at=0
  fi

  printf '%s\n' "${updated_at}"
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

tmux_session_status_current_session() {
  tmux display-message -p '#{session_name}' 2>/dev/null || true
}

tmux_session_status_emit_record() {
  local session_label="$1" agent="$2" state="$3" source="$4" updated_at="$5"

  [[ -n "${session_label}" ]] || return 0
  [[ -n "${state}" ]] || return 0

  printf '%s\t%s\t%s\t%s\t%s\n' "${session_label}" "${agent}" "${state}" "${source}" "${updated_at}"
}

tmux_session_status_emit_local_record() {
  local session="$1" current="$2" safe="" state="" active_agent="" agent="" live_state=""
  local has_known_agent_pane=0 stale_working=0 agent_mismatch=0 state_file="" updated_at=0 source=""

  [[ "${session}" != "${current}" ]] || return 0

  safe="${session//\//%2F}"
  state_file="${STATE_DIR}/${safe}"

  if [[ -f "${state_file}" ]]; then
    IFS=$'\t' read -r agent state < <(_read_state_record "${state_file}")

    if [[ "${state}" == "done" ]] && [[ " ${KNOWN_AGENT_COMMANDS[*]} " == *" ${agent} "* ]] && \
       ! _session_has_live_agent_process "${session}" "${agent}"; then
      rm -f "${state_file}"
      return 0
    fi

    if _session_has_known_agent_pane "${session}"; then
      has_known_agent_pane=1
      active_agent=$(_session_agent_command "${session}" 2>/dev/null || true)
      if [[ -n "${active_agent}" && "${active_agent}" != "${agent}" ]]; then
        agent_mismatch=1
      fi
      live_state=$(_session_live_state "${session}" "${active_agent:-${agent}}")
      if [[ "${state}" == "working" && -z "${live_state}" ]] && _state_file_has_stale_working "${state_file}"; then
        stale_working=1
      fi
    elif [[ "${state}" == "working" ]] && _state_file_has_stale_working "${state_file}"; then
      stale_working=1
    fi

    state=$(tmux_session_status_resolve_state "${state}" "${live_state}" "${has_known_agent_pane}" "${stale_working}" "${agent_mismatch}")
    [[ -n "${state}" ]] || return 0

    updated_at=$(_state_file_mtime "${state_file}")
    source="local_explicit"
    agent="${active_agent:-${agent}}"
  elif _session_has_remote_transport_pane "${session}"; then
    return 0
  elif ! _session_has_known_agent_pane "${session}"; then
    return 0
  else
    agent=$(_session_agent_command "${session}" 2>/dev/null || true)
    live_state=$(_session_live_state "${session}" "${agent}")
    state=$(tmux_session_status_resolve_state "" "${live_state}" 1 0 0)
    [[ -n "${state}" ]] || return 0

    updated_at=0
    source="local_fallback"
  fi

  tmux_session_status_emit_record "${session}" "${agent}" "${state}" "${source}" "${updated_at}"
}

tmux_session_status_local_emit_records() {
  local current="$1" session=""

  while IFS= read -r session; do
    [[ -n "${session}" ]] || continue
    tmux_session_status_emit_local_record "${session}" "${current}"
  done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)
}

tmux_session_status_maybe_refresh_overlay() {
  if declare -F tmux_agent_overlay_maybe_refresh >/dev/null 2>&1; then
    tmux_agent_overlay_maybe_refresh || true
  fi
}

tmux_session_status_emit_overlay_records() {
  local current="$1"

  if declare -F tmux_agent_overlay_emit_records >/dev/null 2>&1; then
    tmux_agent_overlay_emit_records "${current}" 2>/dev/null || true
  fi
}

tmux_session_status_emit_all_records() {
  local current="$1"

  tmux_session_status_local_emit_records "${current}"
  tmux_session_status_emit_overlay_records "${current}"
}

tmux_session_status_format_session() {
  local name="$1" state="$2"

  case "${state}" in
    waiting) printf '%s' "#[fg=#e3d18a] ${name}#[fg=default]" ;;
    working) printf '%s' "#[fg=#82aaff] ${name}#[fg=default]" ;;
    *)       printf '%s' "#[fg=#21c7a8] ${name}#[fg=default]" ;;
  esac
}

tmux_session_status_render_records() {
  local current="$1" session="" _agent="" state="" _source="" _updated_at=""
  local output="" sep="" formatted="" rendered=""

  while IFS=$'\t' read -r session _agent state _source _updated_at || [[ -n "${session:-}${_agent:-}${state:-}${_source:-}${_updated_at:-}" ]]; do
    [[ -n "${session}" ]] || continue
    [[ "${session}" != "${current}" ]] || continue
    [[ -n "${state}" ]] || continue
    if printf '%s\n' "${rendered}" | grep -Fqx "${session}"; then
      continue
    fi

    rendered+="${session}"$'\n'
    formatted=$(tmux_session_status_format_session "${session}" "${state}")
    output+="${sep}${formatted}"
    sep="  "
  done

  if [[ -n "${output}" ]]; then
    printf '%s ' "${output}"
  fi
}

tmux_session_status_prune_orphan_state_files() {
  local state_file="" safe_name="" real_name=""

  [[ -d "${STATE_DIR}" ]] || return 0

  for state_file in "${STATE_DIR}"/*; do
    [[ -f "${state_file}" ]] || continue
    safe_name=$(basename "${state_file}")
    [[ "${safe_name}" == .* ]] && continue
    real_name="${safe_name//%2F/\/}"
    tmux has-session -t "${real_name}" 2>/dev/null || rm -f "${state_file}"
  done
}
