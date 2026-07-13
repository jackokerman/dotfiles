#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
BREWFILE="${PROJECT_ROOT}/Brewfile"
TEST_PREFIX="brewfile-gh-provider-test"
RUBY_BIN="${RUBY_BIN:-$(command -v ruby)}"
SYSTEM_PATH="/usr/bin:/bin"

# shellcheck source=/dev/null
source "${PROJECT_ROOT}/tests/tmux-agent-status/testlib.sh"

write_fake_command() {
    local path="$1"

    mkdir -p "$(dirname "${path}")"
    printf '#!/usr/bin/env bash\nexit 0\n' > "${path}"
    chmod +x "${path}"
}

brewfile_formulae() {
    local homebrew_prefix="$1"
    local path_value="$2"
    local host_path_value="$3"
    local dotfiles_env="${4:-remote}"

    HOMEBREW_PREFIX="${homebrew_prefix}" \
        HOMEBREW_DOTFILES_ENV="${dotfiles_env}" \
        HOMEBREW_DOTFILES_HOST_PATH="${host_path_value}" \
        PATH="${path_value}" \
        "${RUBY_BIN}" - "${BREWFILE}" <<'RUBY'
module OS
  def self.mac?
    false
  end
end

$formulae = []

def tap(*); end
def cask(*); end

def brew(name, *)
  $formulae << name
end

load ARGV.fetch(0)
puts $formulae
RUBY
}

assert_gh_presence() {
    local name="$1" expected="$2" formulae="$3"
    local actual="absent"

    if grep -qx "gh" <<< "${formulae}"; then
        actual="present"
    fi

    assert_equal "${name}" "${expected}" "${actual}"
}

assert_formula_presence() {
    local name="$1" formula="$2" expected="$3" formulae="$4"
    local actual="absent"

    if grep -qx "${formula}" <<< "${formulae}"; then
        actual="present"
    fi

    assert_equal "${name}" "${expected}" "${actual}"
}

run_case() {
    local name="$1" provider="$2" expected="$3"
    local tmp_dir="" homebrew_prefix="" homebrew_bin="" host_bin="" path_value="" host_path_value="" formulae=""

    tmp_dir="$(mktemp -d)"
    homebrew_prefix="${tmp_dir}/homebrew"
    homebrew_bin="${homebrew_prefix}/bin"
    host_bin="${tmp_dir}/host/bin"
    mkdir -p "${homebrew_bin}" "${host_bin}"

    case "${provider}" in
        none)
            path_value="${homebrew_bin}:${host_bin}:${SYSTEM_PATH}"
            host_path_value="${path_value}"
            ;;
        homebrew)
            write_fake_command "${homebrew_bin}/gh"
            path_value="${homebrew_bin}:${host_bin}:${SYSTEM_PATH}"
            host_path_value="${path_value}"
            ;;
        host)
            write_fake_command "${host_bin}/gh"
            path_value="${homebrew_bin}:${host_bin}:${SYSTEM_PATH}"
            host_path_value="${path_value}"
            ;;
        both)
            write_fake_command "${homebrew_bin}/gh"
            write_fake_command "${host_bin}/gh"
            path_value="${homebrew_bin}:${host_bin}:${SYSTEM_PATH}"
            host_path_value="${path_value}"
            ;;
        preserved-host)
            write_fake_command "${host_bin}/gh"
            path_value="${homebrew_bin}:${SYSTEM_PATH}"
            host_path_value="${host_bin}:${SYSTEM_PATH}"
            ;;
        *)
            fail "unknown provider case: ${provider}"
            ;;
    esac

    formulae="$(brewfile_formulae "${homebrew_prefix}" "${path_value}" "${host_path_value}")"
    assert_gh_presence "${name}" "${expected}" "${formulae}"
    rm -rf "${tmp_dir}"
}

run_profile_case() {
    local name="$1" dotfiles_env="$2" formula="$3" expected="$4"
    local tmp_dir="" homebrew_prefix="" formulae=""

    tmp_dir="$(mktemp -d)"
    homebrew_prefix="${tmp_dir}/homebrew"
    mkdir -p "${homebrew_prefix}/bin"

    formulae="$(brewfile_formulae "${homebrew_prefix}" "${homebrew_prefix}/bin:${SYSTEM_PATH}" "${SYSTEM_PATH}" "${dotfiles_env}")"
    assert_formula_presence "${name}" "${formula}" "${expected}" "${formulae}"
    rm -rf "${tmp_dir}"
}

run_case "Brewfile installs gh when no provider exists" "none" "present"
run_case "Brewfile keeps gh managed when only Homebrew provides it" "homebrew" "present"
run_case "Brewfile skips gh when host provides it" "host" "absent"
run_case "Brewfile skips gh when host and Homebrew both provide it" "both" "absent"
run_case "Brewfile skips gh when host provider is only in preserved host PATH" "preserved-host" "absent"
run_profile_case "Brewfile excludes Python from managed laptop profile" "laptop" "python" "absent"
run_profile_case "Brewfile excludes Python from remote profile" "remote" "python" "absent"
run_profile_case "Brewfile includes Python in personal profile" "personal" "python" "present"
