#!/usr/bin/env bash

tmux_agent_bar_runtime_repo_path() {
  local config_dir="" path_file="" candidate="" dev_checkout=""

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

  dev_checkout="${HOME}/src/tmux-agent-bar"
  if [[ -d "${dev_checkout}" ]]; then
    printf '%s\n' "${dev_checkout}"
    return 0
  fi

  printf '%s\n' "${HOME}/.local/share/tmux-agent-bar/repo"
}
