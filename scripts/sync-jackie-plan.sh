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

  printf '[jackie-plan] %s\n' "$*"
}

success_log() {
  if declare -F success >/dev/null 2>&1; then
    success "$@"
    return 0
  fi

  printf '[jackie-plan] %s\n' "$*"
}

warning_log() {
  if declare -F warning >/dev/null 2>&1; then
    warning "$@"
    return 0
  fi

  printf '[jackie-plan] warning: %s\n' "$*" >&2
}

readonly JACKIE_PLAN_REPO_URL="${JACKIE_PLAN_REPO_URL:-https://github.com/jackokerman/jackie-plan.git}"
readonly JACKIE_PLAN_BRANCH="${JACKIE_PLAN_BRANCH:-main}"
readonly JACKIE_PLAN_INSTALL_ROOT="${JACKIE_PLAN_INSTALL_ROOT:-$HOME/.local/share/jackie-plan}"
readonly JACKIE_PLAN_REPO_DIR="${JACKIE_PLAN_REPO_DIR:-${JACKIE_PLAN_INSTALL_ROOT}/repo}"

clone_jackie_plan() {
  mkdir -p "${JACKIE_PLAN_INSTALL_ROOT}"
  if git clone --branch "${JACKIE_PLAN_BRANCH}" "${JACKIE_PLAN_REPO_URL}" "${JACKIE_PLAN_REPO_DIR}"; then
    return 0
  fi

  warning_log "Skipping Jackie Plan install because ${JACKIE_PLAN_REPO_URL} could not be cloned"
  return 1
}

jackie_plan_checkout_is_dirty() {
  local status=""

  status=$(git -C "${JACKIE_PLAN_REPO_DIR}" status --porcelain 2>/dev/null || true)
  [[ -n "${status}" ]]
}

jackie_plan_checkout_branch() {
  git -C "${JACKIE_PLAN_REPO_DIR}" symbolic-ref --quiet --short HEAD 2>/dev/null || true
}

jackie_plan_checkout_can_fast_forward() {
  git -C "${JACKIE_PLAN_REPO_DIR}" merge-base --is-ancestor HEAD "origin/${JACKIE_PLAN_BRANCH}" >/dev/null 2>&1
}

update_jackie_plan() {
  local before="" after=""

  if ! git -C "${JACKIE_PLAN_REPO_DIR}" fetch origin "${JACKIE_PLAN_BRANCH}" >/dev/null 2>&1; then
    warning_log "Skipping Jackie Plan update because fetch failed"
    return 0
  fi

  if ! jackie_plan_checkout_can_fast_forward; then
    warning_log "Skipping Jackie Plan update because the checkout cannot be fast-forwarded to origin/${JACKIE_PLAN_BRANCH}"
    return 0
  fi

  before=$(git -C "${JACKIE_PLAN_REPO_DIR}" rev-parse HEAD)
  git -C "${JACKIE_PLAN_REPO_DIR}" merge --ff-only "origin/${JACKIE_PLAN_BRANCH}" >/dev/null 2>&1
  after=$(git -C "${JACKIE_PLAN_REPO_DIR}" rev-parse HEAD)

  if [[ "${before}" == "${after}" ]]; then
    success_log "Jackie Plan already up to date"
  else
    success_log "Updated Jackie Plan"
  fi
}

link_jackie_plan() {
  if ! command -v bun >/dev/null 2>&1; then
    warning_log "Skipping Jackie Plan link because bun is not installed"
    return 0
  fi

  bun install --cwd "${JACKIE_PLAN_REPO_DIR}" >/dev/null
  (cd "${JACKIE_PLAN_REPO_DIR}" && bun link) >/dev/null
  success_log "Linked jp CLI"
}

main() {
  local branch=""

  title "Syncing Jackie Plan"

  if [[ ! -e "${JACKIE_PLAN_REPO_DIR}" ]]; then
    if ! clone_jackie_plan; then
      return 0
    fi
    success_log "Installed Jackie Plan"
    link_jackie_plan
    return 0
  fi

  if [[ ! -d "${JACKIE_PLAN_REPO_DIR}/.git" ]]; then
    warning_log "Skipping Jackie Plan sync because ${JACKIE_PLAN_REPO_DIR} is not a git checkout"
    return 0
  fi

  branch=$(jackie_plan_checkout_branch)
  if [[ "${branch}" != "${JACKIE_PLAN_BRANCH}" ]]; then
    warning_log "Skipping Jackie Plan update because the checkout is not on ${JACKIE_PLAN_BRANCH}"
    link_jackie_plan
    return 0
  fi

  if jackie_plan_checkout_is_dirty; then
    warning_log "Skipping Jackie Plan update because the checkout is dirty"
    link_jackie_plan
    return 0
  fi

  update_jackie_plan
  link_jackie_plan
}

main "$@"
