#!/usr/bin/env bash
# Write coding agent session state for tmux status bar display.
set -euo pipefail

STATE_DIR="/tmp/tmux-agent-$(id -u)"
mkdir -p "${STATE_DIR}"

# Get session from TMUX env var (set when running inside tmux), or ask tmux directly
if [[ -n "${TMUX:-}" ]]; then
  session="${TMUX##*/}"
else
  session=$(tmux display-message -p '#{session_name}' 2>/dev/null) || exit 0
fi
[[ -n "${session}" ]] || exit 0

state="${1:-}"
[[ -n "${state}" ]] || exit 0

agent="${2:-claude}"
[[ -n "${agent}" ]] || exit 0

safe="${session//\//%2F}"
printf '%s\t%s\n' "${agent}" "${state}" > "${STATE_DIR}/${safe}"

if [[ "${state}" == "done" || "${state}" == "waiting" ]]; then
  printf '\a' >/dev/tty 2>/dev/null || printf '\a'
fi
