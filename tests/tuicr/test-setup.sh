#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
SYNC_SCRIPT="${PROJECT_ROOT}/scripts/sync-tuicr.sh"
TEST_PREFIX="tuicr-setup-test"

# shellcheck source=/dev/null
source "${PROJECT_ROOT}/tests/tmux-agent-status/testlib.sh"

write_fake_curl() {
    local path="$1" log_file="$2" install_script="$3"

    cat > "$path" <<EOF
#!/usr/bin/env bash
set -euo pipefail

url="\${*: -1}"
printf '%s\n' "\${url}" >> "${log_file}"

case "\${url}" in
    https://api.github.com/repos/agavra/tuicr/releases/latest)
        printf '%s\n' '{"tag_name":"v0.19.0"}'
        ;;
    https://tuicr.dev/install.sh)
        cat "${install_script}"
        ;;
    *)
        printf 'unexpected curl URL: %s\n' "\${url}" >&2
        exit 1
        ;;
esac
EOF
    chmod +x "$path"
}

write_fake_installer() {
    local path="$1" log_file="$2"

    cat > "$path" <<EOF
#!/usr/bin/env sh
set -eu

printf 'version=%s dir=%s yes=%s\n' "\${TUICR_VERSION:-}" "\${TUICR_INSTALL_DIR:-}" "\${TUICR_INSTALL_YES:-}" >> "${log_file}"
mkdir -p "\${TUICR_INSTALL_DIR:?}"
cat > "\${TUICR_INSTALL_DIR}/tuicr" <<BIN
#!/usr/bin/env sh
printf '%s\n' 'tuicr \${TUICR_VERSION}'
BIN
chmod +x "\${TUICR_INSTALL_DIR}/tuicr"
EOF
}

run_sync_tuicr() {
    local home_dir="$1" fake_bin="$2"

    HOME="$home_dir" \
        PATH="$fake_bin:/usr/bin:/bin" \
        "$SYNC_SCRIPT"
}

read_file_if_present() {
    local path="$1"

    [[ -f "$path" ]] || return 0
    cat "$path"
}

run_install_case() {
    local tmp_dir="" home_dir="" fake_bin="" curl_log="" installer_log=""

    tmp_dir=$(mktemp -d)
    home_dir="${tmp_dir}/home"
    fake_bin="${tmp_dir}/bin"
    curl_log="${tmp_dir}/curl.log"
    installer_log="${tmp_dir}/installer.log"
    mkdir -p "$fake_bin"

    write_fake_installer "${tmp_dir}/install.sh" "$installer_log"
    write_fake_curl "${fake_bin}/curl" "$curl_log" "${tmp_dir}/install.sh"

    run_sync_tuicr "$home_dir" "$fake_bin"

    assert_equal "sync_tuicr installs the latest release into ~/.local/bin" \
        "tuicr 0.19.0" \
        "$("${home_dir}/.local/bin/tuicr" --version)"
    assert_equal "sync_tuicr passes non-interactive installer env" \
        "version=0.19.0 dir=${home_dir}/.local/bin yes=1" \
        "$(<"$installer_log")"
    assert_equal "sync_tuicr resolves latest before fetching installer" \
        $'https://api.github.com/repos/agavra/tuicr/releases/latest\nhttps://tuicr.dev/install.sh' \
        "$(<"$curl_log")"

    rm -rf "$tmp_dir"
}

run_skip_current_case() {
    local tmp_dir="" home_dir="" fake_bin="" curl_log="" installer_log=""

    tmp_dir=$(mktemp -d)
    home_dir="${tmp_dir}/home"
    fake_bin="${tmp_dir}/bin"
    curl_log="${tmp_dir}/curl.log"
    installer_log="${tmp_dir}/installer.log"
    mkdir -p "$fake_bin" "${home_dir}/.local/bin"

    cat > "${home_dir}/.local/bin/tuicr" <<'EOF'
#!/usr/bin/env sh
printf '%s\n' 'tuicr 0.19.0'
EOF
    chmod +x "${home_dir}/.local/bin/tuicr"
    write_fake_installer "${tmp_dir}/install.sh" "$installer_log"
    write_fake_curl "${fake_bin}/curl" "$curl_log" "${tmp_dir}/install.sh"

    run_sync_tuicr "$home_dir" "$fake_bin"

    assert_equal "sync_tuicr skips installer when target binary is current" "" "$(read_file_if_present "$installer_log")"
    assert_equal "sync_tuicr only resolves latest when target binary is current" \
        "https://api.github.com/repos/agavra/tuicr/releases/latest" \
        "$(<"$curl_log")"

    rm -rf "$tmp_dir"
}

run_pinned_version_case() {
    local tmp_dir="" home_dir="" fake_bin="" curl_log="" installer_log=""

    tmp_dir=$(mktemp -d)
    home_dir="${tmp_dir}/home"
    fake_bin="${tmp_dir}/bin"
    curl_log="${tmp_dir}/curl.log"
    installer_log="${tmp_dir}/installer.log"
    mkdir -p "$fake_bin"

    write_fake_installer "${tmp_dir}/install.sh" "$installer_log"
    write_fake_curl "${fake_bin}/curl" "$curl_log" "${tmp_dir}/install.sh"

    HOME="$home_dir" \
        PATH="$fake_bin:/usr/bin:/bin" \
        TUICR_VERSION="v0.18.0" \
        "$SYNC_SCRIPT"

    assert_equal "sync_tuicr installs a pinned version without resolving latest" \
        "version=0.18.0 dir=${home_dir}/.local/bin yes=1" \
        "$(<"$installer_log")"
    assert_equal "sync_tuicr fetches only the installer for pinned versions" \
        "https://tuicr.dev/install.sh" \
        "$(<"$curl_log")"

    rm -rf "$tmp_dir"
}

run_legacy_cargo_cleanup_case() {
    local tmp_dir="" home_dir="" fake_bin="" curl_log="" installer_log=""

    tmp_dir=$(mktemp -d)
    home_dir="${tmp_dir}/home"
    fake_bin="${tmp_dir}/bin"
    curl_log="${tmp_dir}/curl.log"
    installer_log="${tmp_dir}/installer.log"
    mkdir -p "$fake_bin" "${home_dir}/.cargo/bin"
    touch "${home_dir}/.cargo/bin/tuicr"

    write_fake_installer "${tmp_dir}/install.sh" "$installer_log"
    write_fake_curl "${fake_bin}/curl" "$curl_log" "${tmp_dir}/install.sh"

    run_sync_tuicr "$home_dir" "$fake_bin"

    assert_equal "sync_tuicr removes the old cargo-installed binary after installer success" \
        "0" \
        "$(if [[ -e "${home_dir}/.cargo/bin/tuicr" ]]; then printf '1'; else printf '0'; fi)"

    rm -rf "$tmp_dir"
}

run_install_case
run_skip_current_case
run_pinned_version_case
run_legacy_cargo_cleanup_case
