#!/usr/bin/env bash

set -euo pipefail

if [[ -n "${DOTTY_LIB:-}" && -f "${DOTTY_LIB}" ]]; then
  # shellcheck source=/dev/null
  source "${DOTTY_LIB}"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

readonly DEVTOOLS_MANIFEST="${DEVTOOLS_MANIFEST:-${PROJECT_ROOT}/.dotty/devtools.tsv}"
readonly DEVTOOLS_SRC_ROOT="${DEVTOOLS_SRC_ROOT:-$HOME/src}"
readonly DEVTOOLS_FIELD_COUNT=6

info_log() {
  if declare -F info >/dev/null 2>&1; then
    info "$@"
    return 0
  fi

  printf '[devtools] %s\n' "$*"
}

success_log() {
  if declare -F success >/dev/null 2>&1; then
    success "$@"
    return 0
  fi

  printf '[devtools] %s\n' "$*"
}

warning_log() {
  if declare -F warning >/dev/null 2>&1; then
    warning "$@"
    return 0
  fi

  printf '[devtools] warning: %s\n' "$*" >&2
}

git_no_prompt() {
  GIT_TERMINAL_PROMPT=0 git "$@"
}

manifest_field_count() {
  local line="$1" without_tabs=""

  without_tabs="${line//$'\t'/}"
  printf '%s\n' "$(( ${#line} - ${#without_tabs} + 1 ))"
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

resolve_checkout_dir() {
  local name="$1" checkout="$2"

  case "${checkout}" in
    dev)
      printf '%s/%s\n' "${DEVTOOLS_SRC_ROOT}" "${name}"
      ;;
    /*)
      printf '%s\n' "${checkout}"
      ;;
    *)
      return 1
      ;;
  esac
}

sync_checkout() {
  local name="$1" repo_url="$2" branch="$3" checkout_dir="$4" update="$5"
  local current_branch="" origin_url="" before="" after=""

  if [[ "${update}" != "fast-forward" ]]; then
    warning_log "Skipping ${name} because update policy ${update} is unsupported"
    return 1
  fi

  if [[ ! -e "${checkout_dir}" ]]; then
    mkdir -p "$(dirname "${checkout_dir}")"
    if git_no_prompt clone --branch "${branch}" "${repo_url}" "${checkout_dir}" >/dev/null 2>&1; then
      success_log "Cloned ${name} into ${checkout_dir}"
    else
      warning_log "Skipping ${name} because ${repo_url} could not be cloned"
      return 1
    fi
    return 0
  fi

  if [[ ! -d "${checkout_dir}/.git" ]]; then
    warning_log "Skipping ${name} because ${checkout_dir} is not a git checkout"
    return 1
  fi

  current_branch=$(checkout_branch "${checkout_dir}")
  if [[ "${current_branch}" != "${branch}" ]]; then
    warning_log "Skipping ${name} update because the checkout is not on ${branch}"
    return 1
  fi

  origin_url=$(checkout_origin "${checkout_dir}")
  if [[ "${origin_url}" != "${repo_url}" ]]; then
    warning_log "Skipping ${name} update because origin does not match ${repo_url}"
    return 1
  fi

  if checkout_is_dirty "${checkout_dir}"; then
    warning_log "Skipping ${name} update because the checkout is dirty"
    return 1
  fi

  if ! git_no_prompt -C "${checkout_dir}" fetch origin "${branch}" >/dev/null 2>&1; then
    warning_log "Skipping ${name} update because fetch failed"
    return 1
  fi

  if ! checkout_can_fast_forward "${checkout_dir}" "${branch}"; then
    warning_log "Skipping ${name} update because the checkout cannot be fast-forwarded to origin/${branch}"
    return 1
  fi

  before=$(git -C "${checkout_dir}" rev-parse HEAD)
  git -C "${checkout_dir}" merge --ff-only "origin/${branch}" >/dev/null 2>&1
  after=$(git -C "${checkout_dir}" rev-parse HEAD)

  if [[ "${before}" == "${after}" ]]; then
    success_log "${name} already up to date"
  else
    success_log "Updated ${name}"
  fi
}

run_install_action() {
  local name="$1" repo_url="$2" branch="$3" checkout_dir="$4" install="$5"
  local action_type="" relative_command="" command_path="" work_dir=""

  [[ -n "${install}" ]] || return 0

  case "${install}" in
    repo:*)
      action_type="repo"
      relative_command="${install#repo:}"
      work_dir="${checkout_dir}"
      command_path="${checkout_dir}/${relative_command}"
      ;;
    dotty:*)
      action_type="dotty"
      relative_command="${install#dotty:}"
      work_dir="${PROJECT_ROOT}"
      command_path="${PROJECT_ROOT}/${relative_command}"
      ;;
    *)
      warning_log "Skipping ${name} install because ${install} is not a supported install action"
      return 0
      ;;
  esac

  if [[ -z "${relative_command}" || "${relative_command}" == /* || "${relative_command}" == *".."* ]]; then
    warning_log "Skipping ${name} install because ${action_type}: action must name a relative command"
    return 0
  fi

  if [[ ! -x "${command_path}" ]]; then
    warning_log "Skipping ${name} install because ${command_path} is missing or not executable"
    return 0
  fi

  info_log "Installing ${name}"
  (
    cd "${work_dir}"
    DOTTY_DEVTOOL_NAME="${name}" \
      DOTTY_DEVTOOL_CHECKOUT_DIR="${checkout_dir}" \
      DOTTY_DEVTOOL_REPO_URL="${repo_url}" \
      DOTTY_DEVTOOL_BRANCH="${branch}" \
      GIT_TERMINAL_PROMPT=0 \
      "${command_path}"
  )
}

sync_devtool() {
  local line="$1" field_count="$2"
  local name="" repo_url="" branch="" checkout="" update="" install="" checkout_dir=""

  if [[ "${field_count}" -ne "${DEVTOOLS_FIELD_COUNT}" ]]; then
    warning_log "Skipping malformed manifest entry: ${line}"
    return 0
  fi

  IFS=$'\t' read -r name repo_url branch checkout update install <<< "${line}"

  if [[ -z "${name}" || -z "${repo_url}" || -z "${branch}" || -z "${checkout}" || -z "${update}" ]]; then
    warning_log "Skipping malformed manifest entry: ${line}"
    return 0
  fi

  if ! checkout_dir=$(resolve_checkout_dir "${name}" "${checkout}"); then
    warning_log "Skipping ${name} because checkout target ${checkout} is unsupported"
    return 0
  fi

  if sync_checkout "${name}" "${repo_url}" "${branch}" "${checkout_dir}" "${update}"; then
    run_install_action "${name}" "${repo_url}" "${branch}" "${checkout_dir}" "${install}"
  elif [[ -n "${install}" ]]; then
    warning_log "Skipping ${name} install because checkout sync did not complete"
  fi
}

main() {
  local line="" field_count=0

  info_log "Syncing devtools"

  if [[ ! -f "${DEVTOOLS_MANIFEST}" ]]; then
    warning_log "Skipping devtools because ${DEVTOOLS_MANIFEST} is missing"
    return 0
  fi

  while IFS= read -r line || [[ -n "${line}" ]]; do
    [[ -n "${line}" && "${line}" != \#* ]] || continue

    field_count=$(manifest_field_count "${line}")
    sync_devtool "${line}" "${field_count}"
  done < "${DEVTOOLS_MANIFEST}"
}

main "$@"
