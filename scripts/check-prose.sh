#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STRICT=false

log() {
    printf '[prose] %s\n' "$*"
}

usage() {
    cat <<'EOF'
Usage: scripts/check-prose.sh [--advisory|--strict] [path ...]

Runs Vale with the dotfiles prose style. Advisory mode is the default and never
fails the command.
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --advisory)
                STRICT=false
                ;;
            --strict)
                STRICT=true
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                PROSE_PATHS+=("$1")
                ;;
        esac
        shift
    done
}

default_paths() {
    PROSE_PATHS=()

    [[ -f "$PROJECT_ROOT/README.md" ]] && PROSE_PATHS+=("$PROJECT_ROOT/README.md")
    if [[ -d "$PROJECT_ROOT/docs" ]]; then
        while IFS= read -r -d '' path; do
            PROSE_PATHS+=("$path")
        done < <(find "$PROJECT_ROOT/docs" -maxdepth 1 -type f -name '*.md' -print0)
    fi
}

run_density_summary() {
    local path

    log "Checking prose density"
    for path in "${PROSE_PATHS[@]}"; do
        [[ -f "$path" ]] || continue
        awk '
            BEGIN { paragraph = ""; words = 0; start = 0 }
            /^[[:space:]]*$/ {
                if (words > 120) {
                    printf "%s:%d: long paragraph (%d words); consider splitting or moving detail into docs.\n", FILENAME, start, words
                }
                paragraph = ""; words = 0; start = 0
                next
            }
            /^```/ {
                if (in_code == 0 && words > 120) {
                    printf "%s:%d: long paragraph (%d words); consider splitting or moving detail into docs.\n", FILENAME, start, words
                }
                in_code = !in_code
                paragraph = ""; words = 0; start = 0
                next
            }
            in_code == 1 { next }
            /^#/ || /^[[:space:]]*[-*] / || /^[[:space:]]*[0-9]+[.][[:space:]]/ {
                if (words > 120) {
                    printf "%s:%d: long paragraph (%d words); consider splitting or moving detail into docs.\n", FILENAME, start, words
                }
                paragraph = ""; words = 0; start = 0
            }
            {
                if (start == 0) {
                    start = FNR
                }
                words += split($0, parts, /[[:space:]]+/)
            }
            END {
                if (words > 120) {
                    printf "%s:%d: long paragraph (%d words); consider splitting or moving detail into docs.\n", FILENAME, start, words
                }
            }
        ' "$path"
    done
}

run_vale() {
    if ! command -v vale >/dev/null 2>&1; then
        log "Vale is not installed; skipping advisory prose checks. Run dotty run brew-sync on macOS to install it."
        return 0
    fi

    if [[ ${#PROSE_PATHS[@]} -eq 0 ]]; then
        log "No Markdown files selected for prose checks"
        return 0
    fi

    log "Running Vale"
    if "$STRICT"; then
        vale --config "$PROJECT_ROOT/.vale.ini" "${PROSE_PATHS[@]}"
    else
        vale --config "$PROJECT_ROOT/.vale.ini" --no-exit "${PROSE_PATHS[@]}"
    fi
}

PROSE_PATHS=()
parse_args "$@"

if [[ ${#PROSE_PATHS[@]} -eq 0 ]]; then
    default_paths
fi

run_density_summary
run_vale
