#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GUARD="$PROJECT_ROOT/home/.local/bin/public-content-guard"
TMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

assert_fails() {
    if "$@" >/tmp/public-content-guard-test.log 2>&1; then
        printf 'expected command to fail: %s\n' "$*" >&2
        exit 1
    fi
}

assert_passes() {
    if ! "$@" >/tmp/public-content-guard-test.log 2>&1; then
        cat /tmp/public-content-guard-test.log >&2
        printf 'expected command to pass: %s\n' "$*" >&2
        exit 1
    fi
}

run_guard() {
    (cd "$REPO" && "$GUARD" "$@")
}

export XDG_CONFIG_HOME="$TMP_DIR/config"
mkdir -p "$XDG_CONFIG_HOME/public-content-guard"
printf 'internaltool\n' > "$XDG_CONFIG_HOME/public-content-guard/patterns"

REPO="$TMP_DIR/repo"
mkdir -p "$REPO"
git -C "$REPO" init -q
git -C "$REPO" config user.email test@example.com
git -C "$REPO" config user.name "Test User"

printf '# Test\n' > "$REPO/README.md"
git -C "$REPO" add README.md
git -C "$REPO" commit -qm 'initial'

printf 'This mentions internaltool.\n' >> "$REPO/README.md"
git -C "$REPO" add README.md
assert_fails run_guard --staged README.md
assert_fails run_guard --worktree README.md

assert_passes env PUBLIC_CONTENT_GUARD_SKIP=1 bash -c "cd '$REPO' && '$GUARD' --staged README.md"

git -C "$REPO" reset -q --hard HEAD
mkdir -p "$REPO/docs"
printf 'This mentions internaltool.\n' > "$REPO/docs/private.md"
git -C "$REPO" add docs/private.md
assert_passes run_guard --staged README.md
