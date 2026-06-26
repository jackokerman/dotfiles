#!/usr/bin/env bash

set -euo pipefail

if [[ -n "${DOTTY_LIB:-}" && -f "${DOTTY_LIB}" ]]; then
  # shellcheck source=/dev/null
  source "${DOTTY_LIB}"
fi

title() {
  if declare -F info >/dev/null 2>&1; then
    info "$@"
    return 0
  fi

  printf '[tmux-agent-bar] %s\n' "$*"
}

success_log() {
  if declare -F success >/dev/null 2>&1; then
    success "$@"
    return 0
  fi

  printf '[tmux-agent-bar] %s\n' "$*"
}

warning_log() {
  if declare -F warning >/dev/null 2>&1; then
    warning "$@"
    return 0
  fi

  printf '[tmux-agent-bar] warning: %s\n' "$*" >&2
}

TMUX_AGENT_BAR_BRANCH="${TMUX_AGENT_BAR_BRANCH:-main}"
TMUX_AGENT_BAR_DEV_DIR="${TMUX_AGENT_BAR_DEV_DIR:-$HOME/src/tmux-agent-bar}"

git_no_prompt() {
  GIT_TERMINAL_PROMPT=0 git "$@"
}

tmux_agent_bar_checkout_is_dirty() {
  local repo_dir="$1" status=""

  status=$(git -C "${repo_dir}" status --porcelain 2>/dev/null || true)
  [[ -n "${status}" ]]
}

tmux_agent_bar_checkout_branch() {
  local repo_dir="$1"

  git -C "${repo_dir}" symbolic-ref --quiet --short HEAD 2>/dev/null || true
}

tmux_agent_bar_checkout_can_fast_forward() {
  local repo_dir="$1"

  git -C "${repo_dir}" merge-base --is-ancestor HEAD "origin/${TMUX_AGENT_BAR_BRANCH}" >/dev/null 2>&1
}

update_tmux_agent_bar() {
  local repo_dir="$1" before="" after=""

  if ! git_no_prompt -C "${repo_dir}" fetch origin "${TMUX_AGENT_BAR_BRANCH}" >/dev/null 2>&1; then
    warning_log "Skipping tmux-agent-bar update because fetch failed"
    return 0
  fi

  if ! tmux_agent_bar_checkout_can_fast_forward "${repo_dir}"; then
    warning_log "Skipping tmux-agent-bar update because the checkout cannot be fast-forwarded to origin/${TMUX_AGENT_BAR_BRANCH}"
    return 0
  fi

  before=$(git -C "${repo_dir}" rev-parse HEAD)
  git -C "${repo_dir}" merge --ff-only "origin/${TMUX_AGENT_BAR_BRANCH}" >/dev/null 2>&1
  after=$(git -C "${repo_dir}" rev-parse HEAD)

  if [[ "${before}" == "${after}" ]]; then
    success_log "tmux-agent-bar already up to date"
  else
    success_log "Updated tmux-agent-bar"
  fi
}

main() {
  local branch=""

  title "Syncing tmux-agent-bar"

  if [[ ! -d "${TMUX_AGENT_BAR_DEV_DIR}/.git" ]]; then
    warning_log "Skipping tmux-agent-bar sync because ${TMUX_AGENT_BAR_DEV_DIR} is not a git checkout"
    return 0
  fi

  branch=$(tmux_agent_bar_checkout_branch "${TMUX_AGENT_BAR_DEV_DIR}")
  if [[ "${branch}" != "${TMUX_AGENT_BAR_BRANCH}" ]]; then
    warning_log "Skipping tmux-agent-bar update because the checkout is not on ${TMUX_AGENT_BAR_BRANCH}"
    return 0
  fi

  if tmux_agent_bar_checkout_is_dirty "${TMUX_AGENT_BAR_DEV_DIR}"; then
    warning_log "Skipping tmux-agent-bar update because the checkout is dirty"
    return 0
  fi

  update_tmux_agent_bar "${TMUX_AGENT_BAR_DEV_DIR}"
}

main "$@"
