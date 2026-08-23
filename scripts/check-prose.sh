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

Runs Markdown prose-density checks. Advisory mode is the default and reports
findings without failing. Strict mode exits nonzero when it finds a long
paragraph.
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
    local strict=0

    if [[ "$STRICT" == "true" ]]; then
        strict=1
    fi

    log "Checking prose density"
    for path in "${PROSE_PATHS[@]}"; do
        [[ -f "$path" ]] || continue
        awk -v strict="$strict" '
            function report_long_paragraph() {
                if (words > 120) {
                    printf "%s:%d: long paragraph (%d words); consider splitting or moving detail into docs.\n", FILENAME, start, words
                    found = 1
                }
                words = 0
                start = 0
            }
            BEGIN { words = 0; start = 0 }
            /^[[:space:]]*$/ {
                report_long_paragraph()
                next
            }
            /^```/ {
                if (in_code == 0) {
                    report_long_paragraph()
                } else {
                    words = 0
                    start = 0
                }
                in_code = !in_code
                next
            }
            in_code == 1 { next }
            /^#/ || /^[[:space:]]*[-*] / || /^[[:space:]]*[0-9]+[.][[:space:]]/ {
                report_long_paragraph()
            }
            {
                if (start == 0) {
                    start = FNR
                }
                words += split($0, parts, /[[:space:]]+/)
            }
            END {
                report_long_paragraph()
                exit strict && found
            }
        ' "$path"
    done
}

PROSE_PATHS=()
parse_args "$@"

if [[ ${#PROSE_PATHS[@]} -eq 0 ]]; then
    default_paths
fi

run_density_summary
