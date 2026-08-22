#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
TARGET_SCRIPT="${PROJECT_ROOT}/.dotty/cleanups/2026-08-remove-obsolete-jackie-plan-wrappers/run.sh"
TEST_PREFIX="jackie-plan-wrapper-cleanup-test"

# shellcheck source=/dev/null
source "${PROJECT_ROOT}/tests/testlib.sh"

write_legacy_wrapper() {
    local wrapper_path="$1"
    local checkout_path="$2"

    mkdir -p "$(dirname "${wrapper_path}")"
    {
        printf '%s\n' \
            '#!/usr/bin/env bash' \
            'set -euo pipefail' \
            '' \
            'export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"' \
            'export PATH="${BUN_INSTALL}/bin:${PATH}"' \
            '' \
            'if [[ -x "${BUN_INSTALL}/bin/bun" ]]; then'
        printf '  exec "${BUN_INSTALL}/bin/bun" "%s/src/cli.ts" "$@"\n' "${checkout_path}"
        printf '%s\n' 'fi' ''
        printf 'exec bun "%s/src/cli.ts" "$@"\n' "${checkout_path}"
    } > "${wrapper_path}"
    chmod +x "${wrapper_path}"
}

populate_legacy_wrappers() {
    local home_dir="$1"
    local bin_dir=""
    local command_name=""

    for bin_dir in "${home_dir}/.dotty/bin" "${home_dir}/.local/bin"; do
        for command_name in jp jackie-plan; do
            write_legacy_wrapper "${bin_dir}/${command_name}" "${home_dir}/src/jackie-plan"
        done
    done
}

run_removal_case() {
    local temp_dir=""
    local home_dir=""
    local wrapper_path=""

    temp_dir="$(mktemp -d)"
    home_dir="${temp_dir}/home"
    populate_legacy_wrappers "${home_dir}"

    HOME="${home_dir}" "${TARGET_SCRIPT}" >/dev/null

    for wrapper_path in \
        "${home_dir}/.dotty/bin/jp" \
        "${home_dir}/.dotty/bin/jackie-plan" \
        "${home_dir}/.local/bin/jp" \
        "${home_dir}/.local/bin/jackie-plan"; do
        assert_equal "matching wrapper is removed: ${wrapper_path##*/}" "0" \
            "$(if [[ -e "${wrapper_path}" ]]; then printf '1'; else printf '0'; fi)"
    done

    rm -rf "${temp_dir}"
}

run_dry_run_case() {
    local temp_dir=""
    local home_dir=""
    local output=""

    temp_dir="$(mktemp -d)"
    home_dir="${temp_dir}/home"
    populate_legacy_wrappers "${home_dir}"

    output="$(HOME="${home_dir}" DOTTY_DRY_RUN=true "${TARGET_SCRIPT}")"

    assert_equal "dry-run keeps all matching wrappers" "4" \
        "$(find "${home_dir}" -type f | wc -l | tr -d ' ')"
    assert_equal "dry-run reports all matching wrappers" "4" \
        "$(printf '%s\n' "${output}" | grep -c 'Would remove obsolete Jackie Plan wrapper')"

    rm -rf "${temp_dir}"
}

run_unowned_file_case() {
    local temp_dir=""
    local home_dir=""
    local custom_wrapper=""
    local linked_wrapper=""

    temp_dir="$(mktemp -d)"
    home_dir="${temp_dir}/home"
    custom_wrapper="${home_dir}/.dotty/bin/jp"
    linked_wrapper="${home_dir}/.local/bin/jackie-plan"
    mkdir -p "$(dirname "${custom_wrapper}")" "$(dirname "${linked_wrapper}")" "${home_dir}/.bun/bin"
    printf '%s\n' '#!/usr/bin/env bash' 'printf custom' > "${custom_wrapper}"
    printf '%s\n' '#!/usr/bin/env bash' 'printf linked' > "${home_dir}/.bun/bin/jackie-plan"
    ln -s "${home_dir}/.bun/bin/jackie-plan" "${linked_wrapper}"

    HOME="${home_dir}" "${TARGET_SCRIPT}" >/dev/null

    assert_equal "unrecognized regular file is preserved" "1" \
        "$(if [[ -f "${custom_wrapper}" ]]; then printf '1'; else printf '0'; fi)"
    assert_equal "Bun link is preserved" "1" \
        "$(if [[ -L "${linked_wrapper}" ]]; then printf '1'; else printf '0'; fi)"

    rm -rf "${temp_dir}"
}

run_removal_case
run_dry_run_case
run_unowned_file_case
