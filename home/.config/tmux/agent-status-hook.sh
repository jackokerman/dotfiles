#!/usr/bin/env bash
# Stable tmux entrypoint for explicit agent state writes.
set -euo pipefail

_agent_status_hook="$(cd "$(dirname "${BASH_SOURCE[0]}")/agent-status" && pwd)/hook.sh"

# shellcheck source=/dev/null
source "${_agent_status_hook}"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  tmux_agent_status_hook_main "$@"
fi
