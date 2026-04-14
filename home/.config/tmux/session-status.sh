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
  local session="$1" agent="${2:-}" tail=""

  if declare -F tmux_agent_session_live_state >/dev/null 2>&1; then
    tmux_agent_session_live_state "${session}" "${agent}"
    return 0
  fi

  tail=$(tmux capture-pane -pt "${session}" 2>/dev/null | tail -n 12 || true)

  case "${tail}" in
    *"Do you want me to "*|*"Messages to be submitted after next tool call"*|*"Would you like to run the following command?"*|*"Press enter to confirm or esc to cancel"*|*"permission prompt"*|*"approval"*)
      printf '%s\n' "waiting"
      return 0
      ;;
    *"• Working ("*|*"esc to interrupt"*)
      printf '%s\n' "working"
      return 0
      ;;
  esac

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

_render_session() {
  local name="$1" state="$2"
  case "${state}" in
    waiting) output="${output}${sep}#[fg=#e3d18a] ${name}#[fg=default]" ;;
    working) output="${output}${sep}#[fg=#82aaff] ${name}#[fg=default]" ;;
    *)       output="${output}${sep}#[fg=#21c7a8] ${name}#[fg=default]" ;;
  esac
  sep="  "
}

output=""
sep=""
declare -A rendered_local=()

while IFS= read -r session; do
  [[ "${session}" != "${current}" ]] || continue

  safe="${session//\//%2F}"
  state=""
  active_agent=""
  if [[ -f "${STATE_DIR}/${safe}" ]]; then
    IFS=$'\t' read -r _agent state < <(_read_state_record "${STATE_DIR}/${safe}")

    if _session_has_known_agent_pane "${session}"; then
      active_agent=$(_session_agent_command "${session}" 2>/dev/null || true)
      if [[ -n "${active_agent}" ]]; then
        if [[ "${active_agent}" != "${_agent}" ]]; then
          state="done"
        fi
      fi
      live_state=$(_session_live_state "${session}" "${active_agent:-${_agent}}")
      if [[ -n "${live_state}" ]]; then
        state="${live_state}"
      elif [[ "${state}" == "working" ]] && _state_file_has_stale_working "${STATE_DIR}/${safe}"; then
        # Hooks give us fast transitions into working, but without a matching
        # live signal that state should not stick forever.
        state="done"
      fi
    elif [[ "${state}" == "working" ]] && _state_file_has_stale_working "${STATE_DIR}/${safe}"; then
      # For shell-wrapped or remote-mirrored agents, trust the explicit state
      # file but keep the same stale-working guard as known local agents.
      state="done"
    fi
  elif _session_has_remote_transport_pane "${session}"; then
    continue
  elif ! _session_has_known_agent_pane "${session}"; then
    continue
  else
    active_agent=$(_session_agent_command "${session}" 2>/dev/null || true)
    state=$(_session_live_state "${session}" "${active_agent}")
    [[ -n "${state}" ]] || state="done"
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
