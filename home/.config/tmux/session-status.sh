#!/usr/bin/env bash
# Stable tmux entrypoint for agent status rendering.
set -euo pipefail

_agent_status_main="$(cd "$(dirname "${BASH_SOURCE[0]}")/agent-status" && pwd)/main.sh"

# shellcheck source=/dev/null
source "${_agent_status_main}"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  tmux_session_status_main "$@"
fi
