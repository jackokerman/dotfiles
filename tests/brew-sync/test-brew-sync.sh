#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
TARGET_SCRIPT="${PROJECT_ROOT}/scripts/brew-sync.sh"
TEST_PREFIX="brew-sync-test"

# shellcheck source=/dev/null
source "${PROJECT_ROOT}/tests/tmux-agent-status/testlib.sh"

write_fake_uname() {
    local path="$1" os="$2"

    cat > "${path}" <<EOF
#!/usr/bin/env bash
printf '%s\n' "${os}"
EOF
    chmod +x "${path}"
}

write_fake_brew() {
    local path="$1" log_file="$2" prefix="$3"

    cat > "${path}" <<EOF
#!/usr/bin/env bash
set -euo pipefail

printf 'brew %s\n' "\$*" >> "${log_file}"

case "\${1:-}" in
    shellenv)
        printf 'export PATH="%s/bin:%s/sbin:\$PATH"\n' "${prefix}" "${prefix}"
        ;;
    trust)
        ;;
    bundle)
        ;;
    *)
        printf 'unexpected brew command: %s\n' "\$*" >&2
        exit 1
        ;;
esac
EOF
    chmod +x "${path}"
}

write_fake_installer() {
    local path="$1" brew_path="$2" brew_log="$3" prefix="$4"

    cat > "${path}" <<EOF
#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$(dirname "${brew_path}")"
cat > "${brew_path}" <<'BREW'
#!/usr/bin/env bash
set -euo pipefail

printf 'brew %s\n' "\$*" >> "${brew_log}"

case "\${1:-}" in
    shellenv)
        printf 'export PATH="%s/bin:%s/sbin:\$PATH"\n' "${prefix}" "${prefix}"
        ;;
    trust)
        ;;
    bundle)
        ;;
    *)
        printf 'unexpected brew command: %s\n' "\$*" >&2
        exit 1
        ;;
esac
BREW
chmod +x "${brew_path}"
EOF
}

write_fake_curl() {
    local path="$1" log_file="$2" installer_path="$3"

    cat > "${path}" <<EOF
#!/usr/bin/env bash
set -euo pipefail

url=""
for arg in "\$@"; do
    url="\${arg}"
done
printf '%s\n' "\${url}" >> "${log_file}"
cat "${installer_path}"
EOF
    chmod +x "${path}"
}

copy_script_fixture() {
    local repo_dir="$1" brewfile_body="$2"

    mkdir -p "${repo_dir}/scripts"
    cp "${TARGET_SCRIPT}" "${repo_dir}/scripts/brew-sync.sh"
    chmod +x "${repo_dir}/scripts/brew-sync.sh"
    printf '%s\n' "${brewfile_body}" > "${repo_dir}/Brewfile"
}

run_macos_existing_brew_case() {
    local tmp_dir="" repo_dir="" fake_bin="" brew_log=""

    tmp_dir="$(mktemp -d)"
    repo_dir="${tmp_dir}/repo"
    fake_bin="${tmp_dir}/fake-bin"
    brew_log="${tmp_dir}/brew.log"
    mkdir -p "${fake_bin}"
    : > "${brew_log}"

    copy_script_fixture "${repo_dir}" 'brew "jq"'
    repo_dir="$(cd "${repo_dir}" && pwd -P)"
    write_fake_uname "${fake_bin}/uname" "Darwin"
    write_fake_brew "${fake_bin}/brew" "${brew_log}" "${tmp_dir}/homebrew"

    PATH="${fake_bin}:${PATH}" "${repo_dir}/scripts/brew-sync.sh" >/dev/null

    assert_equal "macOS existing brew only runs bundle by default" \
        "brew bundle --file ${repo_dir}/Brewfile" \
        "$(<"${brew_log}")"

    : > "${brew_log}"
    PATH="${fake_bin}:${PATH}" "${repo_dir}/scripts/brew-sync.sh" --cleanup >/dev/null

    assert_equal "cleanup is opt-in" \
        $'brew bundle --file '"${repo_dir}"$'/Brewfile\nbrew bundle cleanup --file '"${repo_dir}"$'/Brewfile --force --formula --cask' \
        "$(<"${brew_log}")"

    rm -rf "${tmp_dir}"
}

run_linux_install_case() {
    local tmp_dir="" repo_dir="" fake_bin="" brew_log="" curl_log="" prefix=""

    tmp_dir="$(mktemp -d)"
    repo_dir="${tmp_dir}/repo"
    fake_bin="${tmp_dir}/fake-bin"
    brew_log="${tmp_dir}/brew.log"
    curl_log="${tmp_dir}/curl.log"
    prefix="${tmp_dir}/linuxbrew"
    mkdir -p "${fake_bin}"
    : > "${brew_log}"
    : > "${curl_log}"

    copy_script_fixture "${repo_dir}" $'tap "oven-sh/bun"\nbrew "oven-sh/bun/bun"'
    repo_dir="$(cd "${repo_dir}" && pwd -P)"
    write_fake_uname "${fake_bin}/uname" "Linux"
    write_fake_installer "${tmp_dir}/install.sh" "${prefix}/bin/brew" "${brew_log}" "${prefix}"
    write_fake_curl "${fake_bin}/curl" "${curl_log}" "${tmp_dir}/install.sh"

    PATH="${fake_bin}:/usr/bin:/bin" \
        HOMEBREW_PREFIX="${prefix}" \
        "${repo_dir}/scripts/brew-sync.sh" >/dev/null

    assert_equal "Linux missing brew uses the official installer" \
        "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh" \
        "$(<"${curl_log}")"

    assert_equal "Linux install activates Linuxbrew, trusts Bun, then bundles" \
        $'brew shellenv\nbrew trust --formula oven-sh/bun/bun\nbrew bundle --file '"${repo_dir}"$'/Brewfile' \
        "$(<"${brew_log}")"

    rm -rf "${tmp_dir}"
}

run_macos_existing_brew_case
run_linux_install_case
