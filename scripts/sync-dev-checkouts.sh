#!/usr/bin/env bash

set -euo pipefail

if [[ -n "${DOTTY_LIB:-}" && -f "${DOTTY_LIB}" ]]; then
  # shellcheck source=/dev/null
  source "${DOTTY_LIB}"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

readonly DEV_CHECKOUTS_MANIFEST="${DEV_CHECKOUTS_MANIFEST:-${PROJECT_ROOT}/.dotty/dev-checkouts.tsv}"
readonly DEV_CHECKOUTS_SRC_ROOT="${DEV_CHECKOUTS_SRC_ROOT:-$HOME/src}"

info_log() {
  if declare -F info >/dev/null 2>&1; then
    info "$@"
    return 0
  fi

  printf '[dev-checkouts] %s\n' "$*"
}

success_log() {
  if declare -F success >/dev/null 2>&1; then
    success "$@"
    return 0
  fi

  printf '[dev-checkouts] %s\n' "$*"
}

warning_log() {
  if declare -F warning >/dev/null 2>&1; then
    warning "$@"
    return 0
  fi

  printf '[dev-checkouts] warning: %s\n' "$*" >&2
}

checkout_is_dirty() {
  local repo_dir="$1" status=""

  status=$(git -C "${repo_dir}" status --porcelain 2>/dev/null || true)
  [[ -n "${status}" ]]
}

checkout_branch() {
  local repo_dir="$1"

  git -C "${repo_dir}" symbolic-ref --quiet --short HEAD 2>/dev/null || true
}

checkout_origin() {
  local repo_dir="$1"

  git -C "${repo_dir}" config --get remote.origin.url 2>/dev/null || true
}

checkout_can_fast_forward() {
  local repo_dir="$1" branch="$2"

  git -C "${repo_dir}" merge-base --is-ancestor HEAD "origin/${branch}" >/dev/null 2>&1
}

sync_checkout() {
  local name="$1" repo_url="$2" branch="$3"
  local repo_dir="${DEV_CHECKOUTS_SRC_ROOT}/${name}"
  local current_branch="" origin_url="" before="" after=""

  if [[ ! -e "${repo_dir}" ]]; then
    mkdir -p "${DEV_CHECKOUTS_SRC_ROOT}"
    if git clone --branch "${branch}" "${repo_url}" "${repo_dir}" >/dev/null 2>&1; then
      success_log "Cloned ${name} into ${repo_dir}"
    else
      warning_log "Skipping ${name} because ${repo_url} could not be cloned"
    fi
    return 0
  fi

  if [[ ! -d "${repo_dir}/.git" ]]; then
    warning_log "Skipping ${name} because ${repo_dir} is not a git checkout"
    return 0
  fi

  current_branch=$(checkout_branch "${repo_dir}")
  if [[ "${current_branch}" != "${branch}" ]]; then
    warning_log "Skipping ${name} update because the checkout is not on ${branch}"
    return 0
  fi

  origin_url=$(checkout_origin "${repo_dir}")
  if [[ "${origin_url}" != "${repo_url}" ]]; then
    warning_log "Skipping ${name} update because origin does not match ${repo_url}"
    return 0
  fi

  if checkout_is_dirty "${repo_dir}"; then
    warning_log "Skipping ${name} update because the checkout is dirty"
    return 0
  fi

  if ! git -C "${repo_dir}" fetch origin "${branch}" >/dev/null 2>&1; then
    warning_log "Skipping ${name} update because fetch failed"
    return 0
  fi

  if ! checkout_can_fast_forward "${repo_dir}" "${branch}"; then
    warning_log "Skipping ${name} update because the checkout cannot be fast-forwarded to origin/${branch}"
    return 0
  fi

  before=$(git -C "${repo_dir}" rev-parse HEAD)
  git -C "${repo_dir}" merge --ff-only "origin/${branch}" >/dev/null 2>&1
  after=$(git -C "${repo_dir}" rev-parse HEAD)

  if [[ "${before}" == "${after}" ]]; then
    success_log "${name} already up to date"
  else
    success_log "Updated ${name}"
  fi
}

main() {
  local line="" name="" repo_url="" branch="" extra=""

  info_log "Syncing development checkouts"

  if [[ ! -f "${DEV_CHECKOUTS_MANIFEST}" ]]; then
    warning_log "Skipping development checkouts because ${DEV_CHECKOUTS_MANIFEST} is missing"
    return 0
  fi

  while IFS= read -r line || [[ -n "${line}" ]]; do
    [[ -n "${line}" && "${line}" != \#* ]] || continue

    name=""
    repo_url=""
    branch=""
    extra=""
    IFS=$'\t' read -r name repo_url branch extra <<< "${line}"

    if [[ -z "${name}" || -z "${repo_url}" || -z "${branch}" || -n "${extra}" ]]; then
      warning_log "Skipping malformed manifest entry: ${line}"
      continue
    fi

    sync_checkout "${name}" "${repo_url}" "${branch}"
  done < "${DEV_CHECKOUTS_MANIFEST}"
}

main "$@"
