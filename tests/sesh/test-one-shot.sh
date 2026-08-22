#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
TARGET_SCRIPT="${PROJECT_ROOT}/home/.local/bin/sesh-one-shot"
TEST_PREFIX="sesh-one-shot-test"
TMP_DIR="$(mktemp -d)"
SERVER_NAME="sesh-one-shot-test-$$"

# shellcheck source=/dev/null
source "${PROJECT_ROOT}/tests/testlib.sh"

cleanup() {
    tmux -L "${SERVER_NAME}" kill-server 2>/dev/null || true
    rm -rf "${TMP_DIR}"
}

trap cleanup EXIT

wait_for_file() {
    local name="$1" path="$2"
    local attempt=0

    while ((attempt < 100)); do
        if [[ -e "${path}" ]]; then
            return 0
        fi

        sleep 0.05
        ((attempt += 1))
    done

    fail "${name}"
}

wait_for_session_exit() {
    local name="$1" session_name="$2"
    local attempt=0

    while ((attempt < 100)); do
        if ! tmux -L "${SERVER_NAME}" has-session -t "=${session_name}" 2>/dev/null; then
            return 0
        fi

        sleep 0.05
        ((attempt += 1))
    done

    fail "${name}"
}

write_numbered_child() {
    local path="$1"

    cat > "${path}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

tmux display-message -p -t "${TMUX_PANE}" '#{session_name}' > "${OBSERVED_FILE}"
: > "${STARTED_FILE}"

while [[ ! -e "${RELEASE_FILE}" ]]; do
    sleep 0.05
done
EOF
    chmod +x "${path}"
}

write_numbered_launcher() {
    local path="$1" template="$2" child_script="$3"
    local observed_file="$4" started_file="$5" release_file="$6"
    local test_home="$7" cache_home="$8"

    {
        printf '#!/usr/bin/env bash\n'
        printf 'set -euo pipefail\n'
        printf 'export HOME=%q\n' "${test_home}"
        printf 'export XDG_CACHE_HOME=%q\n' "${cache_home}"
        printf 'export OBSERVED_FILE=%q\n' "${observed_file}"
        printf 'export STARTED_FILE=%q\n' "${started_file}"
        printf 'export RELEASE_FILE=%q\n' "${release_file}"
        printf 'exec %q --numbered-session %q -- %q\n' "${TARGET_SCRIPT}" "${template}" "${child_script}"
    } > "${path}"
    chmod +x "${path}"
}

run_unnumbered_case() {
    local test_home="${TMP_DIR}/unnumbered-home"
    local cache_home="${TMP_DIR}/unnumbered-cache"
    local cache_file="${cache_home}/sesh/sessions.gob"
    local observed_file="${TMP_DIR}/unnumbered-observed"

    mkdir -p "${test_home}" "${cache_home}/sesh"
    : > "${cache_file}"

    HOME="${test_home}" XDG_CACHE_HOME="${cache_home}" \
        "${TARGET_SCRIPT}" bash -c 'printf "%s" "$1" > "$2"' _ "argument preserved" "${observed_file}"

    assert_equal "unnumbered invocation preserves command arguments" "argument preserved" "$(<"${observed_file}")"
    assert_equal "unnumbered invocation invalidates the cache on exit" "0" \
        "$(if [[ -e "${cache_file}" ]]; then printf '1'; else printf '0'; fi)"
}

run_numbered_allocation_case() {
    local test_home="${TMP_DIR}/numbered-home"
    local cache_home="${TMP_DIR}/numbered-cache"
    local cache_file="${cache_home}/sesh/sessions.gob"
    local child_script="${TMP_DIR}/numbered-child.sh"
    local launcher_script="${TMP_DIR}/numbered-launcher.sh"
    local observed_file="${TMP_DIR}/numbered-observed"
    local started_file="${TMP_DIR}/numbered-started"
    local release_file="${TMP_DIR}/numbered-release"
    local sessions=""

    mkdir -p "${test_home}" "${cache_home}/sesh"
    write_numbered_child "${child_script}"
    write_numbered_launcher \
        "${launcher_script}" \
        'Scratch {n}' \
        "${child_script}" \
        "${observed_file}" \
        "${started_file}" \
        "${release_file}" \
        "${test_home}" \
        "${cache_home}"

    tmux -L "${SERVER_NAME}" new-session -d -s "Scratch 1" 'while :; do sleep 1; done'
    tmux -L "${SERVER_NAME}" new-session -d -s "Scratch 3" 'while :; do sleep 1; done'
    : > "${cache_file}"
    tmux -L "${SERVER_NAME}" new-session -d -s "New Scratch" "${launcher_script}"

    wait_for_file "numbered child starts" "${started_file}"
    assert_equal "numbered child observes the allocated session name" "Scratch 2" "$(<"${observed_file}")"
    assert_equal "numbered rename invalidates the cache before child exit" "0" \
        "$(if [[ -e "${cache_file}" ]]; then printf '1'; else printf '0'; fi)"

    sessions="$(tmux -L "${SERVER_NAME}" list-sessions -F '#{session_name}' | sort)"
    assert_equal "numbered allocation preserves concurrent instances" $'Scratch 1\nScratch 2\nScratch 3' "${sessions}"

    : > "${cache_file}"
    : > "${release_file}"
    wait_for_session_exit "numbered one-shot exits with its child" "Scratch 2"
    assert_equal "numbered child exit invalidates the cache" "0" \
        "$(if [[ -e "${cache_file}" ]]; then printf '1'; else printf '0'; fi)"

    tmux -L "${SERVER_NAME}" kill-session -t "=Scratch 1"
    rm -f "${observed_file}" "${started_file}" "${release_file}"
    write_numbered_launcher \
        "${launcher_script}" \
        'Scratch {n}' \
        "${child_script}" \
        "${observed_file}" \
        "${started_file}" \
        "${release_file}" \
        "${test_home}" \
        "${cache_home}"

    tmux -L "${SERVER_NAME}" new-session -d -s "New Scratch" "${launcher_script}"
    wait_for_file "replacement numbered child starts" "${started_file}"
    assert_equal "numbered allocation reuses the lowest available number" "Scratch 1" "$(<"${observed_file}")"

    : > "${release_file}"
    wait_for_session_exit "replacement numbered one-shot exits" "Scratch 1"
}

run_invalid_contract_cases() {
    local test_home="${TMP_DIR}/invalid-home"
    local cache_home="${TMP_DIR}/invalid-cache"
    local marker="${TMP_DIR}/invalid-command-ran"
    local output="${TMP_DIR}/invalid-output"
    local rc=0

    mkdir -p "${test_home}" "${cache_home}"

    set +e
    HOME="${test_home}" XDG_CACHE_HOME="${cache_home}" \
        "${TARGET_SCRIPT}" --numbered-session 'Scratch' -- touch "${marker}" >"${output}" 2>&1
    rc=$?
    set -e
    assert_equal "numbered template requires one placeholder" "64" "${rc}"
    assert_equal "invalid template does not run the child" "0" \
        "$(if [[ -e "${marker}" ]]; then printf '1'; else printf '0'; fi)"

    set +e
    HOME="${test_home}" XDG_CACHE_HOME="${cache_home}" \
        "${TARGET_SCRIPT}" --numbered-session 'Scratch {n} copy {n}' -- touch "${marker}" >"${output}" 2>&1
    rc=$?
    set -e
    assert_equal "numbered template rejects repeated placeholders" "64" "${rc}"

    set +e
    HOME="${test_home}" XDG_CACHE_HOME="${cache_home}" \
        "${TARGET_SCRIPT}" --numbered-session 'Scratch {n}' -- >"${output}" 2>&1
    rc=$?
    set -e
    assert_equal "numbered invocation requires a child command" "64" "${rc}"

    set +e
    (
        unset TMUX TMUX_PANE
        export HOME="${test_home}"
        export XDG_CACHE_HOME="${cache_home}"
        "${TARGET_SCRIPT}" --numbered-session 'Scratch {n}' -- touch "${marker}"
    ) >"${output}" 2>&1
    rc=$?
    set -e
    assert_equal "numbered invocation requires tmux" "1" "${rc}"
    assert_equal "missing tmux context does not run the child" "0" \
        "$(if [[ -e "${marker}" ]]; then printf '1'; else printf '0'; fi)"
}

run_unexpected_rename_failure_case() {
    local fake_bin="${TMP_DIR}/fake-bin"
    local test_home="${TMP_DIR}/rename-failure-home"
    local cache_home="${TMP_DIR}/rename-failure-cache"
    local marker="${TMP_DIR}/rename-failure-command-ran"
    local output="${TMP_DIR}/rename-failure-output"
    local rc=0

    mkdir -p "${fake_bin}" "${test_home}" "${cache_home}"
    cat > "${fake_bin}/tmux" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
    display-message)
        printf '$99\n'
        ;;
    rename-session)
        printf 'forced rename failure\n' >&2
        exit 1
        ;;
    has-session)
        exit 1
        ;;
    *)
        exit 1
        ;;
esac
EOF
    chmod +x "${fake_bin}/tmux"

    set +e
    HOME="${test_home}" XDG_CACHE_HOME="${cache_home}" TMUX_PANE="%99" PATH="${fake_bin}:${PATH}" \
        "${TARGET_SCRIPT}" --numbered-session 'Scratch {n}' -- touch "${marker}" >"${output}" 2>&1
    rc=$?
    set -e

    assert_equal "unexpected rename failure is fatal" "1" "${rc}"
    assert_matches "unexpected rename failure preserves tmux diagnostics" 'forced rename failure' "$(<"${output}")"
    assert_equal "unexpected rename failure does not run the child" "0" \
        "$(if [[ -e "${marker}" ]]; then printf '1'; else printf '0'; fi)"
}

run_unnumbered_case
run_numbered_allocation_case
run_invalid_contract_cases
run_unexpected_rename_failure_case
