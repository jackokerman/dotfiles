#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
GUARD="$REPO_ROOT/home/.local/bin/public-content-guard"

if [[ ! -x "$GUARD" ]]; then
    GUARD="public-content-guard"
fi

exec "$GUARD" --staged --exclude ".githooks/sensitive-content-patterns"
