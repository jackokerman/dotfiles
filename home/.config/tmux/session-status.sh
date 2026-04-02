#!/usr/bin/env bash
# Show coding agent session status for other tmux sessions in the status bar.
set -euo pipefail

STATE_DIR="/tmp/tmux-agent-$(id -u)"
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

_render_session() {
  local name="$1" state="$2"
  case "${state}" in
    done)    output="${output}${sep}#[fg=#21c7a8] ${name}#[fg=default]" ;;
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
  is_claude=false
  while IFS= read -r cmd; do
    if [[ "${cmd}" == "claude" ]]; then
      is_claude=true
      break
    fi
  done < <(tmux list-panes -t "${session}" -F '#{pane_current_command}' 2>/dev/null)
  "${is_claude}" || continue

  safe="${session//\//%2F}"
  state=""
  if [[ -f "${STATE_DIR}/${safe}" ]]; then
    IFS=$'\t' read -r _agent state < <(_read_state_record "${STATE_DIR}/${safe}")
  fi

  rendered_local["${session}"]=1
  _render_session "${session}" "${state}"
done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null)

# Remove state files for sessions that no longer exist in tmux.
if [[ -d "${STATE_DIR}" ]]; then
  for state_file in "${STATE_DIR}"/*; do
    [[ -f "${state_file}" ]] || continue
    safe_name=$(basename "${state_file}")
    [[ "${safe_name}" != ".remote-sync-ts" ]] || continue
    real_name="${safe_name//%2F/\/}"
    tmux has-session -t "${real_name}" 2>/dev/null || rm -f "${state_file}"
  done
fi

# Append remote devbox sessions from cache, skipping any already rendered in
# the local section (avoids duplicates when a local session runs Claude directly).
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
