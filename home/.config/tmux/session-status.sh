#!/usr/bin/env bash
# Show coding agent session status for other tmux sessions in the status bar.
set -euo pipefail

STATE_DIR="/tmp/tmux-agent-$(id -u)"
KNOWN_AGENT_COMMANDS=(claude codex)
REMOTE_TRANSPORT_COMMANDS=(pty-cli)
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

_render_session() {
  local name="$1" state="$2"
  case "${state}" in
    done)    return ;;
    waiting) output="${output}${sep}#[fg=#e3d18a] ${name}#[fg=default]" ;;
    *)       output="${output}${sep}#[fg=#82aaff] ${name}#[fg=default]" ;;
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
  if _session_has_remote_transport_pane "${session}"; then
    continue
  elif [[ -f "${STATE_DIR}/${safe}" ]]; then
    if ! _session_has_known_agent_pane "${session}"; then
      rm -f "${STATE_DIR}/${safe}"
      continue
    fi
    IFS=$'\t' read -r _agent state < <(_read_state_record "${STATE_DIR}/${safe}")
    if active_agent=$(_session_agent_command "${session}" 2>/dev/null); then
      if [[ "${active_agent}" != "${_agent}" ]]; then
        state=""
      fi
    fi
  elif ! _session_has_known_agent_pane "${session}"; then
    continue
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
