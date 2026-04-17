#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
REGISTRY_PATH="${HOME}/.dotty/registry"
stdin_file=""

warn() {
    printf '[run-overlay-git-hook] %s\n' "$*" >&2
}

canonicalize_path() {
    local path="$1"
    if [[ -d "$path" ]]; then
        (cd -- "$path" && pwd -P)
    else
        printf '%s\n' "$path"
    fi
}

resolve_source_repo_name() {
    local repo_name=""
    local repo_path=""
    local project_root_canonical=""

    project_root_canonical="$(canonicalize_path "$PROJECT_ROOT")"

    [[ -f "$REGISTRY_PATH" ]] || {
        printf '%s\n' "$(basename "$PROJECT_ROOT")"
        return 0
    }

    while IFS='=' read -r repo_name repo_path; do
        [[ -n "$repo_name" && -n "$repo_path" ]] || continue
        if [[ "$(canonicalize_path "$repo_path")" == "$project_root_canonical" ]]; then
            printf '%s\n' "$repo_name"
            return 0
        fi
    done < "$REGISTRY_PATH"

    printf '%s\n' "$(basename "$PROJECT_ROOT")"
}

main() {
    local hook_name="${1:-}"
    shift || true

    [[ -n "$hook_name" ]] || {
        warn "Usage: run-overlay-git-hook.sh <hook-name> [hook-args...]"
        return 1
    }

    [[ -f "$REGISTRY_PATH" ]] || return 0

    stdin_file="$(mktemp "${TMPDIR:-/tmp}/run-overlay-git-hook.XXXXXX")"
    trap 'rm -f "$stdin_file"' EXIT
    cat > "$stdin_file"

    export DOTTY_GIT_HOOK_SOURCE_REPO_NAME="${DOTTY_GIT_HOOK_SOURCE_REPO_NAME:-$(resolve_source_repo_name)}"
    export DOTTY_GIT_HOOK_SOURCE_REPO_ROOT="${DOTTY_GIT_HOOK_SOURCE_REPO_ROOT:-$PROJECT_ROOT}"

    local repo_name=""
    local repo_path=""
    local contract=""

    while IFS='=' read -r repo_name repo_path; do
        [[ -n "$repo_name" && -d "$repo_path" ]] || continue
        [[ "$repo_path" == "$PROJECT_ROOT" ]] && continue

        contract="$repo_path/.dotty/git-hooks/$hook_name"
        [[ -x "$contract" ]] || continue

        if ! "$contract" "$@" < "$stdin_file"; then
            warn "Overlay contract failed: $contract"
        fi
    done < "$REGISTRY_PATH"
}

main "$@"
