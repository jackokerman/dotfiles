#!/usr/bin/env bash
set -euo pipefail

readonly JACKIE_PLAN_REPO_DIR="${JACKIE_PLAN_REPO_DIR:-$HOME/src/jackie-plan}"
readonly JACKIE_PLAN_COMPAT_REPO_DIR="${JACKIE_PLAN_COMPAT_REPO_DIR:-$HOME/.local/share/jackie-plan/repo}"

warn() {
    printf '[jackie-plan] warning: %s\n' "$*" >&2
}

if [[ "${JACKIE_PLAN_COMPAT_REPO_DIR}" == "${JACKIE_PLAN_REPO_DIR}" ]]; then
    exit 0
fi

if [[ ! -e "${JACKIE_PLAN_COMPAT_REPO_DIR}" ]]; then
    exit 0
fi

if [[ -L "${JACKIE_PLAN_COMPAT_REPO_DIR}" ]]; then
    if [[ "$(readlink "${JACKIE_PLAN_COMPAT_REPO_DIR}")" == "${JACKIE_PLAN_REPO_DIR}" ]]; then
        exit 0
    fi

    warn "Skipping cleanup because ${JACKIE_PLAN_COMPAT_REPO_DIR} is a symlink to another target"
    exit 0
fi

if [[ ! -d "${JACKIE_PLAN_COMPAT_REPO_DIR}/.git" ]]; then
    warn "Skipping cleanup because ${JACKIE_PLAN_COMPAT_REPO_DIR} is not a git checkout"
    exit 0
fi

if [[ ! -d "${JACKIE_PLAN_REPO_DIR}/.git" ]]; then
    warn "Skipping cleanup because ${JACKIE_PLAN_REPO_DIR} is not a git checkout"
    exit 0
fi

if [[ -n "$(git -C "${JACKIE_PLAN_COMPAT_REPO_DIR}" status --porcelain)" ]]; then
    warn "Skipping cleanup because ${JACKIE_PLAN_COMPAT_REPO_DIR} is dirty"
    exit 0
fi

legacy_head="$(git -C "${JACKIE_PLAN_COMPAT_REPO_DIR}" rev-parse HEAD)"
if ! git -C "${JACKIE_PLAN_REPO_DIR}" merge-base --is-ancestor "${legacy_head}" HEAD >/dev/null 2>&1; then
    warn "Skipping cleanup because ${JACKIE_PLAN_COMPAT_REPO_DIR} has commits not in ${JACKIE_PLAN_REPO_DIR}"
    exit 0
fi

if [[ "${DOTTY_DRY_RUN:-false}" == "true" ]]; then
    printf '[dry-run] Would replace %s with a symlink to %s\n' "${JACKIE_PLAN_COMPAT_REPO_DIR}" "${JACKIE_PLAN_REPO_DIR}"
    exit 0
fi

rm -rf "${JACKIE_PLAN_COMPAT_REPO_DIR}"
ln -s "${JACKIE_PLAN_REPO_DIR}" "${JACKIE_PLAN_COMPAT_REPO_DIR}"
printf '[jackie-plan] Replaced %s with a symlink to %s\n' "${JACKIE_PLAN_COMPAT_REPO_DIR}" "${JACKIE_PLAN_REPO_DIR}"
