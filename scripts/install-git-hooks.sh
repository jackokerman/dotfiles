#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
TRACKED_HOOK="$PROJECT_ROOT/.githooks/pre-commit"

if [[ ! -f "$TRACKED_HOOK" ]]; then
    echo "Tracked pre-commit hook not found at $TRACKED_HOOK" >&2
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

cleanup_stale_hook() {
    local hook_name="$1"
    local target_hook="$HOOK_DIR/$hook_name"
    local legacy_hook="$HOOK_DIR/${hook_name}.local"

    if [[ -e "$target_hook" ]] && grep -q "managed-by: codex-install-git-hooks" "$target_hook" 2>/dev/null; then
        rm -f "$target_hook"
        if [[ -e "$legacy_hook" ]]; then
            mv "$legacy_hook" "$target_hook"
        fi
    fi
}

HOOK_DIR="$(resolve_hook_dir)"
TARGET_HOOK="$HOOK_DIR/pre-commit"
LEGACY_HOOK="$HOOK_DIR/pre-commit.local"

mkdir -p "$HOOK_DIR"
chmod +x "$TRACKED_HOOK"

cleanup_stale_hook pre-push

if [[ -e "$TARGET_HOOK" ]] && ! grep -q "managed-by: codex-install-git-hooks" "$TARGET_HOOK" 2>/dev/null; then
    mv "$TARGET_HOOK" "$LEGACY_HOOK"
fi

cat > "$TARGET_HOOK" <<'EOF'
#!/usr/bin/env bash
# managed-by: codex-install-git-hooks

set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
hook_dir="$(cd -- "$(dirname -- "$0")" && pwd -P)"
legacy_hook="$hook_dir/pre-commit.local"
tracked_hook="$repo_root/.githooks/pre-commit"

if [[ -x "$legacy_hook" ]]; then
    "$legacy_hook" "$@"
fi

exec "$tracked_hook" "$@"
EOF

chmod +x "$TARGET_HOOK"

printf '[install-git-hooks] Installed tracked pre-commit hook for %s\n' "$PROJECT_ROOT"
