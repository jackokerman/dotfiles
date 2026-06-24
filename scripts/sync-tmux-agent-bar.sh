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

TMUX_AGENT_BAR_REPO_URL="${TMUX_AGENT_BAR_REPO_URL:-https://github.com/jackokerman/tmux-agent-bar.git}"
TMUX_AGENT_BAR_BRANCH="${TMUX_AGENT_BAR_BRANCH:-main}"
TMUX_AGENT_BAR_INSTALL_ROOT="${TMUX_AGENT_BAR_INSTALL_ROOT:-$HOME/.local/share/tmux-agent-bar}"
TMUX_AGENT_BAR_REPO_DIR="${TMUX_AGENT_BAR_REPO_DIR:-${TMUX_AGENT_BAR_INSTALL_ROOT}/repo}"

clone_tmux_agent_bar() {
  mkdir -p "${TMUX_AGENT_BAR_INSTALL_ROOT}"
  git clone --branch "${TMUX_AGENT_BAR_BRANCH}" "${TMUX_AGENT_BAR_REPO_URL}" "${TMUX_AGENT_BAR_REPO_DIR}"
}

tmux_agent_bar_checkout_is_dirty() {
  local status=""

  status=$(git -C "${TMUX_AGENT_BAR_REPO_DIR}" status --porcelain 2>/dev/null || true)
  [[ -n "${status}" ]]
}

tmux_agent_bar_checkout_branch() {
  git -C "${TMUX_AGENT_BAR_REPO_DIR}" symbolic-ref --quiet --short HEAD 2>/dev/null || true
}

tmux_agent_bar_checkout_can_fast_forward() {
  git -C "${TMUX_AGENT_BAR_REPO_DIR}" merge-base --is-ancestor HEAD "origin/${TMUX_AGENT_BAR_BRANCH}" >/dev/null 2>&1
}

update_tmux_agent_bar() {
  local before="" after=""

  git -C "${TMUX_AGENT_BAR_REPO_DIR}" fetch origin "${TMUX_AGENT_BAR_BRANCH}" >/dev/null 2>&1

  if ! tmux_agent_bar_checkout_can_fast_forward; then
    warning_log "Skipping tmux-agent-bar update because the checkout cannot be fast-forwarded to origin/${TMUX_AGENT_BAR_BRANCH}"
    return 0
  fi

  before=$(git -C "${TMUX_AGENT_BAR_REPO_DIR}" rev-parse HEAD)
  git -C "${TMUX_AGENT_BAR_REPO_DIR}" merge --ff-only "origin/${TMUX_AGENT_BAR_BRANCH}" >/dev/null 2>&1
  after=$(git -C "${TMUX_AGENT_BAR_REPO_DIR}" rev-parse HEAD)

  if [[ "${before}" == "${after}" ]]; then
    success_log "tmux-agent-bar already up to date"
  else
    success_log "Updated tmux-agent-bar"
  fi
}

main() {
  local branch=""

  title "Syncing tmux-agent-bar"

  if [[ ! -e "${TMUX_AGENT_BAR_REPO_DIR}" ]]; then
    clone_tmux_agent_bar
    success_log "Installed tmux-agent-bar"
    return 0
  fi

  if [[ ! -d "${TMUX_AGENT_BAR_REPO_DIR}/.git" ]]; then
    warning_log "Skipping tmux-agent-bar sync because ${TMUX_AGENT_BAR_REPO_DIR} is not a git checkout"
    return 0
  fi

  branch=$(tmux_agent_bar_checkout_branch)
  if [[ "${branch}" != "${TMUX_AGENT_BAR_BRANCH}" ]]; then
    warning_log "Skipping tmux-agent-bar update because the checkout is not on ${TMUX_AGENT_BAR_BRANCH}"
    return 0
  fi

  if tmux_agent_bar_checkout_is_dirty; then
    warning_log "Skipping tmux-agent-bar update because the checkout is dirty"
    return 0
  fi

  update_tmux_agent_bar
}

main "$@"
