#!/usr/bin/env bash
set -euo pipefail

is_legacy_wrapper() {
    local candidate="$1"

    [[ -f "${candidate}" && ! -L "${candidate}" ]] || return 1

    awk '
        BEGIN {
            valid = 1
            first_prefix = "  exec \"${BUN_INSTALL}/bin/bun\" \""
            second_prefix = "exec bun \""
            suffix = "\" \"$@\""
        }
        NR == 1 && $0 != "#!/usr/bin/env bash" { valid = 0 }
        NR == 2 && $0 != "set -euo pipefail" { valid = 0 }
        NR == 3 && $0 != "" { valid = 0 }
        NR == 4 && $0 != "export BUN_INSTALL=\"${BUN_INSTALL:-$HOME/.bun}\"" { valid = 0 }
        NR == 5 && $0 != "export PATH=\"${BUN_INSTALL}/bin:${PATH}\"" { valid = 0 }
        NR == 6 && $0 != "" { valid = 0 }
        NR == 7 && $0 != "if [[ -x \"${BUN_INSTALL}/bin/bun\" ]]; then" { valid = 0 }
        NR == 8 {
            if (index($0, first_prefix) != 1 || substr($0, length($0) - length(suffix) + 1) != suffix) {
                valid = 0
                next
            }
            first_path = substr($0, length(first_prefix) + 1, length($0) - length(first_prefix) - length(suffix))
            if (first_path !~ /\/src\/jackie-plan\/src\/cli\.ts$/) {
                valid = 0
            }
        }
        NR == 9 && $0 != "fi" { valid = 0 }
        NR == 10 && $0 != "" { valid = 0 }
        NR == 11 {
            if (index($0, second_prefix) != 1 || substr($0, length($0) - length(suffix) + 1) != suffix) {
                valid = 0
                next
            }
            second_path = substr($0, length(second_prefix) + 1, length($0) - length(second_prefix) - length(suffix))
            if (second_path != first_path) {
                valid = 0
            }
        }
        NR > 11 { valid = 0 }
        END { exit !(valid && NR == 11) }
    ' "${candidate}"
}

readonly WRAPPER_PATHS=(
    "${HOME}/.dotty/bin/jp"
    "${HOME}/.dotty/bin/jackie-plan"
    "${HOME}/.local/bin/jp"
    "${HOME}/.local/bin/jackie-plan"
)

for wrapper_path in "${WRAPPER_PATHS[@]}"; do
    is_legacy_wrapper "${wrapper_path}" || continue

    if [[ "${DOTTY_DRY_RUN:-false}" == "true" ]]; then
        printf '[dry-run] Would remove obsolete Jackie Plan wrapper %s\n' "${wrapper_path}"
        continue
    fi

    rm -f "${wrapper_path}"
    printf 'Removed obsolete Jackie Plan wrapper %s\n' "${wrapper_path}"
done
