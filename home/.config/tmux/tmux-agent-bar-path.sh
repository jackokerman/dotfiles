#!/usr/bin/env bash

tmux_agent_bar_runtime_repo_path() {
  local config_dir="" path_file="" candidate=""

  if [[ -n "${TMUX_AGENT_BAR_DIR:-}" ]]; then
    printf '%s\n' "${TMUX_AGENT_BAR_DIR}"
    return 0
  fi

  config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/tmux-agent-bar"
  path_file="${config_dir}/path.local"

  if [[ -r "${path_file}" ]]; then
    candidate=$(sed -n '1p' "${path_file}" 2>/dev/null | tr -d '\r')
    if [[ -n "${candidate}" ]]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  fi

  printf '%s\n' "${HOME}/src/tmux-agent-bar"
}
