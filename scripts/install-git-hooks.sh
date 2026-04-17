#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
TRACKED_HOOKS_DIR="$PROJECT_ROOT/.githooks"

if [[ ! -d "$TRACKED_HOOKS_DIR" ]]; then
    echo "Tracked hooks directory not found at $TRACKED_HOOKS_DIR" >&2
    exit 1
fi

resolve_hook_dir() {
    if [[ -f "$PROJECT_ROOT/.git" ]]; then
        local worktree_git_dir
        local common_dir

        worktree_git_dir="$(grep "gitdir:" "$PROJECT_ROOT/.git" | cut -d' ' -f2)"
        common_dir="$(cat "$worktree_git_dir/commondir" 2>/dev/null || echo "..")"
        printf '%s\n' "$worktree_git_dir/$common_dir/hooks"
        return 0
    fi

    if [[ -d "$PROJECT_ROOT/.git" ]]; then
        printf '%s\n' "$PROJECT_ROOT/.git/hooks"
        return 0
    fi

    return 1
}

is_managed_hook() {
    local hook_path="$1"
    grep -q "managed-by: codex-install-git-hooks" "$hook_path" 2>/dev/null
}

next_legacy_hook_path() {
    local hook_name="$1"
    local candidate="$HOOK_DIR/${hook_name}.local"
    local index=1

    while [[ -e "$candidate" ]]; do
        candidate="$HOOK_DIR/${hook_name}.local.${index}"
        index=$((index + 1))
    done

    printf '%s\n' "$candidate"
}

install_hook() {
    local hook_name="$1"
    local tracked_hook="$TRACKED_HOOKS_DIR/$hook_name"
    local target_hook="$HOOK_DIR/$hook_name"

    chmod +x "$tracked_hook"

    if [[ -e "$target_hook" ]] && ! is_managed_hook "$target_hook"; then
        mv "$target_hook" "$(next_legacy_hook_path "$hook_name")"
    fi

    cat > "$target_hook" <<'EOF'
#!/usr/bin/env bash
# managed-by: codex-install-git-hooks

set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
hook_name="$(basename "$0")"
hook_dir="$(cd -- "$(dirname -- "$0")" && pwd -P)"
tracked_hook="$repo_root/.githooks/$hook_name"
stdin_file=""
export DOTTY_GIT_HOOK_PARENT_PID="${DOTTY_GIT_HOOK_PARENT_PID:-$PPID}"

cleanup() {
    [[ -n "$stdin_file" ]] && rm -f "$stdin_file"
}
trap cleanup EXIT

if [[ ! -t 0 ]]; then
    stdin_file="$(mktemp "${TMPDIR:-/tmp}/git-hook.${hook_name}.XXXXXX")"
    cat > "$stdin_file"
fi

run_hook() {
    local hook_path="$1"
    shift

    if [[ -n "$stdin_file" ]]; then
        "$hook_path" "$@" < "$stdin_file"
    else
        "$hook_path" "$@"
    fi
}

shopt -s nullglob
legacy_hooks=("$hook_dir/${hook_name}.local" "$hook_dir/${hook_name}.local".*)
for legacy_hook in "${legacy_hooks[@]}"; do
    [[ -x "$legacy_hook" ]] || continue
    run_hook "$legacy_hook" "$@"
done
shopt -u nullglob

if [[ -n "$stdin_file" ]]; then
    exec "$tracked_hook" "$@" < "$stdin_file"
fi

exec "$tracked_hook" "$@"
EOF

    chmod +x "$target_hook"
}

HOOK_DIR="$(resolve_hook_dir)"
mkdir -p "$HOOK_DIR"

installed_hooks=()
while IFS= read -r tracked_hook_path; do
    [[ -n "$tracked_hook_path" ]] || continue
    hook_name="$(basename "$tracked_hook_path")"
    install_hook "$hook_name"
    installed_hooks+=("$hook_name")
done < <(find "$TRACKED_HOOKS_DIR" -mindepth 1 -maxdepth 1 -type f | sort)

if [[ ${#installed_hooks[@]} -eq 0 ]]; then
    echo "No tracked hooks found in $TRACKED_HOOKS_DIR" >&2
    exit 1
fi

printf '[install-git-hooks] Installed tracked hooks for %s:' "$PROJECT_ROOT"
for hook_name in "${installed_hooks[@]}"; do
    printf ' %s' "$hook_name"
done
printf '\n'
