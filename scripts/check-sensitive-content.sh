#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
PATTERNS_FILE="$REPO_ROOT/.githooks/sensitive-content-patterns"

if [[ ! -f "$PATTERNS_FILE" ]]; then
    exit 0
fi

combined=""
while IFS= read -r line; do
    line="${line## }"
    line="${line%% }"
    [[ -z "$line" || "$line" == \#* ]] && continue
    [[ -n "$combined" ]] && combined+="|"
    combined+="$line"
done < "$PATTERNS_FILE"

[[ -n "$combined" ]] || exit 0

staged_files="$(git diff --cached --name-only --diff-filter=ACMR -- . ':(exclude).githooks/sensitive-content-patterns')"
[[ -n "$staged_files" ]] || exit 0

matches=""
while IFS= read -r file; do
    [[ -n "$file" ]] || continue

    file_matches="$(git diff --cached --unified=0 --no-color -- "$file" | grep -iE "^\+[^+].*($combined)" || true)"
    [[ -n "$file_matches" ]] || continue

    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        matches+="$file: $line"$'\n'
    done <<< "$file_matches"
done <<< "$staged_files"

if [[ -n "$matches" ]]; then
    echo ""
    echo "  Commit blocked. Added lines contain content this public repo should not mention."
    echo ""
    echo "  Matches found:"
    echo ""
    printf '%s' "$matches" | head -20 | while IFS= read -r line; do
        echo "    $line"
    done

    local_count="$(printf '%s' "$matches" | wc -l | tr -d ' ')"
    if [[ "$local_count" -gt 20 ]]; then
        echo "    ... and $((local_count - 20)) more"
    fi

    echo ""
    echo "  Remove or reword the added text, or bypass the hook if this is intentional."
    echo ""
    exit 1
fi
