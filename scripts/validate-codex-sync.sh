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
    local relative_path="$2"
    local env_name="$3"
    local predicate="$4"
    local -a sources=()

    if repo_in_registry "$PROJECT_ROOT"; then
        while IFS='=' read -r _name repo_path; do
            [[ -n "$_name" && -d "$repo_path" ]] || continue
            local candidate="$repo_path/home/.codex/$relative_path"
            local env_candidate="$repo_path/$env_name/home/.codex/$relative_path"

            [[ "$predicate" == "file" && -f "$candidate" ]] && sources+=("$candidate")
            [[ "$predicate" == "dir" && -d "$candidate" ]] && sources+=("$candidate")
            [[ "$predicate" == "file" && -f "$env_candidate" ]] && sources+=("$env_candidate")
            [[ "$predicate" == "dir" && -d "$env_candidate" ]] && sources+=("$env_candidate")
        done < "$REGISTRY_PATH"

        log "Validating $kind across the current dotty chain"
    else
        local local_candidate="$PROJECT_ROOT/home/.codex/$relative_path"
        local env_candidate="$PROJECT_ROOT/$env_name/home/.codex/$relative_path"

        [[ "$predicate" == "file" && -f "$local_candidate" ]] && sources+=("$local_candidate")
        [[ "$predicate" == "dir" && -d "$local_candidate" ]] && sources+=("$local_candidate")
        [[ "$predicate" == "file" && -f "$env_candidate" ]] && sources+=("$env_candidate")
        [[ "$predicate" == "dir" && -d "$env_candidate" ]] && sources+=("$env_candidate")

        log "Validating $kind in the current repo only"
    fi

    printf '%s\n' "${sources[@]}"
}

validate_kind() {
    local kind="$1"
    local mode="$2"
    local relative_path="$3"
    local env_name="$4"
    local predicate="$5"
    local -a sources=()
    local source

    while IFS= read -r source; do
        [[ -n "$source" ]] || continue
        sources+=("$source")
    done < <(collect_sources "$kind" "$relative_path" "$env_name" "$predicate")

    if [[ ${#sources[@]} -eq 0 ]]; then
        return 0
    fi

    local -a args=("$mode" "--validate-only")
    for source in "${sources[@]}"; do
        args+=("--source" "$source")
    done

    bun run "$SYNC_SCRIPT" "${args[@]}"
}

validate_custom_agents() {
    local env_name="$1"
    local -a agent_sources=()
    local -a skill_sources=()
    local source

    while IFS= read -r source; do
        [[ -n "$source" ]] || continue
        agent_sources+=("$source")
    done < <(collect_sources "custom agents" "agents" "$env_name" "dir")

    if [[ ${#agent_sources[@]} -eq 0 ]]; then
        return 0
    fi

    while IFS= read -r source; do
        [[ -n "$source" ]] || continue
        skill_sources+=("$source")
    done < <(collect_sources "skills" "skills" "$env_name" "dir")

    local -a args=("custom-agents" "--validate-only")
    for source in "${agent_sources[@]}"; do
        args+=("--source" "$source")
    done
    for source in "${skill_sources[@]}"; do
        args+=("--skill-source" "$source")
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

    validate_kind "instruction fragments" agents AGENTS.md "$env_name" file
    validate_kind config config config.toml "$env_name" file
    validate_kind hooks hooks hooks.json "$env_name" file
    validate_kind skills skills skills "$env_name" dir
    validate_custom_agents "$env_name"
}

main "$@"
