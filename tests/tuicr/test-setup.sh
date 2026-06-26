#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
SYNC_SCRIPT="${PROJECT_ROOT}/scripts/sync-tuicr.sh"
TEST_PREFIX="tuicr-setup-test"

# shellcheck source=/dev/null
source "${PROJECT_ROOT}/tests/tmux-agent-status/testlib.sh"

create_remote_repo() {
    local root="$1" worktree="" remote=""

    worktree="${root}/work"
    remote="${root}/remote.git"

    git init --bare "${remote}" >/dev/null 2>&1
    git clone "${remote}" "${worktree}" >/dev/null 2>&1
    (
        cd "${worktree}"
        git config user.name "Test User"
        git config user.email "test@example.com"
        printf 'one\n' > README.md
        git add README.md
        git commit -m "initial" >/dev/null 2>&1
        git branch -M main
        git push origin main >/dev/null 2>&1
    )
}

append_remote_commit() {
    local root="$1" worktree=""

    worktree="${root}/work"
    (
        cd "${worktree}"
        printf 'two\n' >> README.md
        git commit -am "second" >/dev/null 2>&1
        git push origin main >/dev/null 2>&1
    )
}

write_fake_cargo() {
    local path="$1"

    cat > "${path}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" >> "${FAKE_CARGO_LOG:?}"

if [[ "${1:-}" == "install" ]]; then
    cargo_home="${CARGO_HOME:-$HOME/.cargo}"
    mkdir -p "${cargo_home}/bin"
    cat > "${cargo_home}/bin/tuicr" <<'BIN'
#!/usr/bin/env bash
exit 0
BIN
    chmod +x "${cargo_home}/bin/tuicr"
fi
EOF
}

run_setup_tuicr() {
    local home_dir="$1" repo_url="$2" install_root="$3" cargo_log="$4"

    HOME="${home_dir}" \
        PATH="${home_dir}/bin:${PATH}" \
        XDG_STATE_HOME="${home_dir}/.local/state" \
        CARGO_HOME="${home_dir}/.cargo" \
        TUICR_REPO_URL="${repo_url}" \
        TUICR_BRANCH="main" \
        TUICR_INSTALL_ROOT="${install_root}" \
        TUICR_REPO_DIR="${install_root}/repo" \
        FAKE_CARGO_LOG="${cargo_log}" \
        "${SYNC_SCRIPT}"
}

count_lines() {
    local path="$1"

    if [[ ! -f "${path}" ]]; then
        printf '0\n'
        return 0
    fi

    wc -l < "${path}" | tr -d ' '
}

run_clone_case() {
    local tmp_dir="" home_dir="" install_root="" repo_head="" installed_rev=""

    tmp_dir=$(mktemp -d)
    home_dir="${tmp_dir}/home"
    install_root="${tmp_dir}/install"

    mkdir -p "${home_dir}/bin"
    create_remote_repo "${tmp_dir}"
    write_fake_cargo "${home_dir}/bin/cargo"
    chmod +x "${home_dir}/bin/cargo"

    run_setup_tuicr "${home_dir}" "${tmp_dir}/remote.git" "${install_root}" "${tmp_dir}/cargo.log"

    repo_head=$(git -C "${install_root}/repo" rev-parse --abbrev-ref HEAD)
    installed_rev=$(sed -n '1p' "${home_dir}/.local/state/dotfiles/tuicr/install-rev")

    assert_equal "setup_tuicr clones the managed checkout on first run" "main" "${repo_head}"
    assert_equal "setup_tuicr records the installed checkout revision" \
        "$(git -C "${install_root}/repo" rev-parse HEAD)" "${installed_rev}"
    assert_equal "setup_tuicr installs a tuicr binary on first run" "1" \
        "$(if [[ -x "${home_dir}/.cargo/bin/tuicr" ]]; then printf '1'; else printf '0'; fi)"
    rm -rf "${tmp_dir}"
}

run_update_case() {
    local tmp_dir="" home_dir="" install_root=""

    tmp_dir=$(mktemp -d)
    home_dir="${tmp_dir}/home"
    install_root="${tmp_dir}/install"

    mkdir -p "${home_dir}/bin"
    create_remote_repo "${tmp_dir}"
    write_fake_cargo "${home_dir}/bin/cargo"
    chmod +x "${home_dir}/bin/cargo"

    run_setup_tuicr "${home_dir}" "${tmp_dir}/remote.git" "${install_root}" "${tmp_dir}/cargo.log"
    append_remote_commit "${tmp_dir}"
    run_setup_tuicr "${home_dir}" "${tmp_dir}/remote.git" "${install_root}" "${tmp_dir}/cargo.log"

    assert_equal "setup_tuicr fast-forwards a clean checkout" "two" \
        "$(tail -n 1 "${install_root}/repo/README.md")"
    assert_equal "setup_tuicr reinstalls after the checkout advances" "2" \
        "$(count_lines "${tmp_dir}/cargo.log")"
    rm -rf "${tmp_dir}"
}

run_dirty_skip_case() {
    local tmp_dir="" home_dir="" install_root="" actual=""

    tmp_dir=$(mktemp -d)
    home_dir="${tmp_dir}/home"
    install_root="${tmp_dir}/install"

    mkdir -p "${home_dir}/bin"
    create_remote_repo "${tmp_dir}"
    write_fake_cargo "${home_dir}/bin/cargo"
    chmod +x "${home_dir}/bin/cargo"

    run_setup_tuicr "${home_dir}" "${tmp_dir}/remote.git" "${install_root}" "${tmp_dir}/cargo.log"
    append_remote_commit "${tmp_dir}"
    printf 'local\n' >> "${install_root}/repo/README.md"

    actual=$(
        run_setup_tuicr "${home_dir}" "${tmp_dir}/remote.git" "${install_root}" "${tmp_dir}/cargo.log" 2>&1 || true
    )

    assert_matches "setup_tuicr warns instead of overwriting a dirty checkout" 'dirty' "${actual}"
    assert_equal "setup_tuicr does not reinstall from a dirty checkout" "1" \
        "$(count_lines "${tmp_dir}/cargo.log")"
    rm -rf "${tmp_dir}"
}

run_branch_skip_case() {
    local tmp_dir="" home_dir="" install_root="" actual=""

    tmp_dir=$(mktemp -d)
    home_dir="${tmp_dir}/home"
    install_root="${tmp_dir}/install"

    mkdir -p "${home_dir}/bin"
    create_remote_repo "${tmp_dir}"
    write_fake_cargo "${home_dir}/bin/cargo"
    chmod +x "${home_dir}/bin/cargo"

    run_setup_tuicr "${home_dir}" "${tmp_dir}/remote.git" "${install_root}" "${tmp_dir}/cargo.log"
    git -C "${install_root}/repo" checkout -b feature >/dev/null 2>&1

    actual=$(
        run_setup_tuicr "${home_dir}" "${tmp_dir}/remote.git" "${install_root}" "${tmp_dir}/cargo.log" 2>&1 || true
    )

    assert_matches "setup_tuicr warns instead of updating a non-main checkout" 'not on main' "${actual}"
    assert_equal "setup_tuicr does not reinstall from a non-main checkout" "1" \
        "$(count_lines "${tmp_dir}/cargo.log")"
    rm -rf "${tmp_dir}"
}

run_origin_skip_case() {
    local tmp_dir="" home_dir="" install_root="" actual=""

    tmp_dir=$(mktemp -d)
    home_dir="${tmp_dir}/home"
    install_root="${tmp_dir}/install"

    mkdir -p "${home_dir}/bin"
    create_remote_repo "${tmp_dir}"
    write_fake_cargo "${home_dir}/bin/cargo"
    chmod +x "${home_dir}/bin/cargo"

    run_setup_tuicr "${home_dir}" "${tmp_dir}/remote.git" "${install_root}" "${tmp_dir}/cargo.log"
    git -C "${install_root}/repo" remote set-url origin https://example.com/tuicr.git

    actual=$(
        run_setup_tuicr "${home_dir}" "${tmp_dir}/remote.git" "${install_root}" "${tmp_dir}/cargo.log" 2>&1 || true
    )

    assert_matches "setup_tuicr warns instead of updating a checkout with a custom origin" 'origin does not match' "${actual}"
    assert_equal "setup_tuicr does not reinstall from a checkout with a custom origin" "1" \
        "$(count_lines "${tmp_dir}/cargo.log")"
    rm -rf "${tmp_dir}"
}

run_skip_install_case() {
    local tmp_dir="" home_dir="" install_root=""

    tmp_dir=$(mktemp -d)
    home_dir="${tmp_dir}/home"
    install_root="${tmp_dir}/install"

    mkdir -p "${home_dir}/bin"
    create_remote_repo "${tmp_dir}"
    write_fake_cargo "${home_dir}/bin/cargo"
    chmod +x "${home_dir}/bin/cargo"

    run_setup_tuicr "${home_dir}" "${tmp_dir}/remote.git" "${install_root}" "${tmp_dir}/cargo.log"

    run_setup_tuicr "${home_dir}" "${tmp_dir}/remote.git" "${install_root}" "${tmp_dir}/cargo.log"
    assert_equal "setup_tuicr skips reinstall when the stamp and binary are current" "1" \
        "$(count_lines "${tmp_dir}/cargo.log")"
    rm -rf "${tmp_dir}"
}

run_clone_case
run_update_case
run_dirty_skip_case
run_branch_skip_case
run_origin_skip_case
run_skip_install_case
