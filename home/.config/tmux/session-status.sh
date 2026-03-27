#!/usr/bin/env bash
# Show Claude session status for other tmux sessions in the status bar.
set -euo pipefail

STATE_DIR="/tmp/tmux-claude-$(id -u)"
# Trigger remote devbox sync if the overlay script exists.
_remote_sync="${HOME}/.config/tmux/remote-claude-sync.sh"
_sync_ts="${STATE_DIR}/.remote-sync-ts"
if [[ -x "${_remote_sync}" ]]; then
  _now=$(date +%s)
  if [[ ! -f "${_sync_ts}" ]] || (( _now - $(<"${_sync_ts}") > 10 )); then
    echo "${_now}" > "${_sync_ts}"
    ("${_remote_sync}" &)
  fi
fi

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
  is_claude=false
  while IFS= read -r cmd; do
    if [[ "${cmd}" == "claude" ]]; then
      is_claude=true
      break
    fi
  done < <(tmux list-panes -t "${session}" -F '#{pane_current_command}' 2>/dev/null)
  "${is_claude}" || continue

  state=""
  if [[ -f "${STATE_DIR}/${session}" ]]; then
    state=$(<"${STATE_DIR}/${session}")
  fi

  rendered_local["${session}"]=1
  _render_session "${session}" "${state}"
done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null)

# Remove state files for sessions that no longer exist in tmux.
if [[ -d "${STATE_DIR}" ]]; then
  for state_file in "${STATE_DIR}"/*; do
    [[ -f "${state_file}" ]] || continue
    basename=$(basename "${state_file}")
    [[ "${basename}" != ".remote-sync-ts" ]] || continue
    tmux has-session -t "${basename}" 2>/dev/null || rm -f "${state_file}"
  done
fi

# Append remote devbox sessions from cache, skipping any already rendered in
# the local section (avoids duplicates when a local session runs Claude directly).
if [[ -d "${STATE_DIR}/remote" ]]; then
  for state_file in "${STATE_DIR}/remote"/*; do
    [[ -f "${state_file}" ]] || continue
    session=$(basename "${state_file}")
    [[ -z "${rendered_local[${session}]+x}" ]] || continue
    state=$(<"${state_file}")
    _render_session "${session}" "${state}"
  done
fi

if [[ -n "${output}" ]]; then
  printf '%s ' "${output}"
fi
