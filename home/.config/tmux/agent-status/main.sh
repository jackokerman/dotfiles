#!/usr/bin/env bash
# Show coding agent session status for other tmux sessions in the status bar.
set -euo pipefail

STATE_DIR="${STATE_DIR:-/tmp/tmux-agent-$(id -u)}"
KNOWN_AGENT_COMMANDS=(claude codex)
REMOTE_TRANSPORT_COMMANDS=(pty-cli)
_agent_status_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_agent_pane_state_lib="${_agent_status_dir}/pane-state.sh"
_session_status_lib="${_agent_status_dir}/lib.sh"
_session_status_overlay_script="${TMUX_SESSION_STATUS_OVERLAY_SCRIPT:-${HOME}/.config/tmux/session-status-overlay.sh}"

# shellcheck source=/dev/null
source "${_agent_pane_state_lib}"
# shellcheck source=/dev/null
source "${_session_status_lib}"

if [[ -r "${_session_status_overlay_script}" ]]; then
  # shellcheck source=/dev/null
  source "${_session_status_overlay_script}"
fi

tmux_session_status_main() {
  local current=""

  current=$(tmux_session_status_current_session)
  tmux_session_status_maybe_refresh_overlay
  tmux_session_status_emit_all_records "${current}" | tmux_session_status_render_records "${current}"
  tmux_session_status_prune_orphan_state_files
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  tmux_session_status_main "$@"
fi
