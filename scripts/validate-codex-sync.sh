#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SYNC_SCRIPT="$SCRIPT_DIR/sync-codex.ts"
REGISTRY_PATH="${HOME}/.dotty/registry"

log() {
    printf '[validate-codex-sync] %s\n' "$*" >&2
}

detect_env() {
    if [[ -n "${DOTTY_ENV:-}" ]]; then
        printf '%s\n' "$DOTTY_ENV"
    elif [[ -n "${remote_name:-}" || -n "${remote_emoji:-}" ]]; then
        printf 'remote\n'
    else
        printf 'laptop\n'
    fi
}

repo_in_registry() {
    local repo_path="$1"
    [[ -f "$REGISTRY_PATH" ]] || return 1

    while IFS='=' read -r _name path; do
        [[ -n "$_name" && -n "$path" ]] || continue
        if [[ "$path" == "$repo_path" ]]; then
            return 0
        fi
    done < "$REGISTRY_PATH"

    return 1
}

collect_sources() {
    local kind="$1"
    local file_name="$2"
    local env_name="$3"
    local -a sources=()

    if repo_in_registry "$PROJECT_ROOT"; then
        while IFS='=' read -r _name repo_path; do
            [[ -n "$_name" && -d "$repo_path" ]] || continue
            local candidate="$repo_path/home/.codex/$file_name"
            [[ -f "$candidate" ]] && sources+=("$candidate")
        done < "$REGISTRY_PATH"

        local env_candidate="$PROJECT_ROOT/$env_name/home/.codex/$file_name"
        [[ -f "$env_candidate" ]] && sources+=("$env_candidate")

        log "Validating $kind across the current dotty chain"
    else
        local local_candidate="$PROJECT_ROOT/home/.codex/$file_name"
        local env_candidate="$PROJECT_ROOT/$env_name/home/.codex/$file_name"

        [[ -f "$local_candidate" ]] && sources+=("$local_candidate")
        [[ -f "$env_candidate" ]] && sources+=("$env_candidate")

        log "Validating $kind in the current repo only"
    fi

    printf '%s\n' "${sources[@]}"
}

validate_kind() {
    local kind="$1"
    local file_name="$2"
    local env_name="$3"
    local -a sources=()
    local source

    while IFS= read -r source; do
        [[ -n "$source" ]] || continue
        sources+=("$source")
    done < <(collect_sources "$kind" "$file_name" "$env_name")

    if [[ ${#sources[@]} -eq 0 ]]; then
        return 0
    fi

    local -a args=("$kind" "--validate-only")
    for source in "${sources[@]}"; do
        args+=("--source" "$source")
    done

    bun run "$SYNC_SCRIPT" "${args[@]}"
}

main() {
    command -v bun >/dev/null 2>&1 || {
        echo "bun is required to validate Codex sync output" >&2
        exit 1
    }

    local env_name
    env_name="$(detect_env)"

    validate_kind agents AGENTS.md "$env_name"
    validate_kind config config.toml "$env_name"
    validate_kind hooks hooks.json "$env_name"
}

main "$@"
