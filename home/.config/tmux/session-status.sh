#!/usr/bin/env bash
# Show Claude session status for other tmux sessions in the status bar.
set -euo pipefail

STATE_DIR="/tmp/tmux-claude-$(id -u)"
current=$(tmux display-message -p '#{session_name}' 2>/dev/null) || exit 0

output=""
sep=""

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

  state=""
  if [[ -f "${STATE_DIR}/${session}" ]]; then
    state=$(<"${STATE_DIR}/${session}")
  fi

  case "${state}" in
    done)    output="${output}${sep}#[fg=#21c7a8] ${session}#[fg=default]" ;;
    waiting) output="${output}${sep}#[fg=#e3d18a] ${session}#[fg=default]" ;;
    *)       output="${output}${sep}#[fg=#82aaff] ${session}#[fg=default]" ;;
  esac
  sep="  "
done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null)

if [[ -n "${output}" ]]; then
  printf '%s ' "${output}"
fi
