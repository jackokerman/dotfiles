#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
TARGET_SCRIPT="${PROJECT_ROOT}/.dotty/cleanups/2026-08-remove-tmux-agent-bar-hooks/run.sh"
TEST_PREFIX="tmux-agent-bar-hook-cleanup-test"

# shellcheck source=/dev/null
source "${PROJECT_ROOT}/tests/testlib.sh"

write_fake_tmux() {
    local target="$1"
    local log_file="$2"

    cat > "${target}" <<EOF
#!/usr/bin/env bash
set -euo pipefail

if [[ "\${1:-}" == "show-hooks" ]]; then
    hook_name="\${3:?}"
    case "\${hook_name}" in
        'client-attached[0]')
            action='run-shell "${HOME}/.config/tmux/session-status-refresh.sh #{q:client_session} --force-refresh --client #{q:hook_client}"'
            ;;
        'client-session-changed[0]')
            action='run-shell "${HOME}/.config/tmux/session-status-refresh.sh #{q:client_session} --force-refresh --client #{q:hook_client}"'
            ;;
        'session-closed[0]')
            action='run-shell "${HOME}/.config/tmux/session-status-refresh.sh --all-clients --force-refresh --refresh-client"'
            ;;
    esac

    if [[ "\${FAKE_TMUX_FOREIGN_HOOK:-}" == "\${hook_name}" ]]; then
        action='run-shell "custom-command"'
    fi

    printf '%s %s\n' "\${hook_name}" "\${action}"
    exit 0
fi

printf 'tmux %s\n' "\$*" >> "${log_file}"
EOF
    chmod +x "${target}"
}

run_removal_case() {
    local temp_dir=""
    local fake_bin=""
    local log_file=""

    temp_dir="$(mktemp -d)"
    fake_bin="${temp_dir}/bin"
    log_file="${temp_dir}/tmux.log"
    mkdir -p "${fake_bin}"
    : > "${log_file}"
    write_fake_tmux "${fake_bin}/tmux" "${log_file}"

    PATH="${fake_bin}:${PATH}" "${TARGET_SCRIPT}" >/dev/null

    assert_equal "removes only the three owned hook slots" \
        $'tmux set-hook -gu client-attached[0]\ntmux set-hook -gu client-session-changed[0]\ntmux set-hook -gu session-closed[0]' \
        "$(<"${log_file}")"

    rm -rf "${temp_dir}"
}

run_dry_run_case() {
    local temp_dir=""
    local fake_bin=""
    local log_file=""
    local output=""

    temp_dir="$(mktemp -d)"
    fake_bin="${temp_dir}/bin"
    log_file="${temp_dir}/tmux.log"
    mkdir -p "${fake_bin}"
    : > "${log_file}"
    write_fake_tmux "${fake_bin}/tmux" "${log_file}"

    output="$(PATH="${fake_bin}:${PATH}" DOTTY_DRY_RUN=true "${TARGET_SCRIPT}")"

    assert_equal "dry-run preserves the hooks" "" "$(<"${log_file}")"
    assert_equal "dry-run reports each owned hook" "3" \
        "$(printf '%s\n' "${output}" | rg -c 'Would remove obsolete tmux hook')"

    rm -rf "${temp_dir}"
}

run_foreign_hook_case() {
    local temp_dir=""
    local fake_bin=""
    local log_file=""

    temp_dir="$(mktemp -d)"
    fake_bin="${temp_dir}/bin"
    log_file="${temp_dir}/tmux.log"
    mkdir -p "${fake_bin}"
    : > "${log_file}"
    write_fake_tmux "${fake_bin}/tmux" "${log_file}"

    PATH="${fake_bin}:${PATH}" \
        FAKE_TMUX_FOREIGN_HOOK='client-attached[0]' \
        "${TARGET_SCRIPT}" >/dev/null

    assert_equal "preserves a foreign action in an old hook slot" \
        $'tmux set-hook -gu client-session-changed[0]\ntmux set-hook -gu session-closed[0]' \
        "$(<"${log_file}")"

    rm -rf "${temp_dir}"
}

run_removal_case
run_dry_run_case
run_foreign_hook_case
