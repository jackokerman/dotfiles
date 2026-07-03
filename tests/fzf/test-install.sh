#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
TARGET_SCRIPT="${PROJECT_ROOT}/scripts/install-fzf.sh"
TEST_PREFIX="fzf-install-test"

# shellcheck source=/dev/null
source "${PROJECT_ROOT}/tests/tmux-agent-status/testlib.sh"

write_fake_curl() {
  local path="$1" log_file="$2" archive="$3"

  cat > "${path}" <<EOF
#!/usr/bin/env bash
set -euo pipefail

output=""
while [[ \$# -gt 0 ]]; do
  case "\$1" in
    -o)
      output="\$2"
      shift 2
      ;;
    -*)
      shift
      ;;
    *)
      printf '%s\n' "\$1" >> "${log_file}"
      shift
      ;;
  esac
done

[[ -n "\$output" ]]
cp "${archive}" "\$output"
EOF
  chmod +x "${path}"
}

create_fzf_archive() {
  local archive="$1" payload_dir=""

  payload_dir="$(mktemp -d)"
  cat > "${payload_dir}/fzf" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "--version" ]]; then
  printf '%s\n' "0.73.1 (test)"
fi
EOF
  chmod +x "${payload_dir}/fzf"
  tar -czf "${archive}" -C "${payload_dir}" fzf
  rm -rf "${payload_dir}"
}

run_install_case() {
  local tmp_dir="" bin_dir="" fake_bin="" curl_log="" archive="" actual=""

  tmp_dir="$(mktemp -d)"
  bin_dir="${tmp_dir}/install-bin"
  fake_bin="${tmp_dir}/fake-bin"
  curl_log="${tmp_dir}/curl.log"
  archive="${tmp_dir}/fzf.tar.gz"

  mkdir -p "${fake_bin}"
  create_fzf_archive "${archive}"
  write_fake_curl "${fake_bin}/curl" "${curl_log}" "${archive}"

  PATH="${fake_bin}:${PATH}" \
    HOME="${tmp_dir}/home" \
    FZF_OS="Linux" \
    FZF_ARCH="aarch64" \
    FZF_INSTALL_BIN_DIR="${bin_dir}" \
    "${TARGET_SCRIPT}" >/dev/null

  actual="$("${bin_dir}/fzf" --version)"
  assert_equal "installer writes executable fzf" "0.73.1 (test)" "${actual}"
  assert_equal "installer downloads the matching upstream asset" \
    "https://github.com/junegunn/fzf/releases/download/v0.73.1/fzf-0.73.1-linux_arm64.tar.gz" \
    "$(<"${curl_log}")"

  : > "${curl_log}"
  PATH="${fake_bin}:${PATH}" \
    HOME="${tmp_dir}/home" \
    FZF_OS="Linux" \
    FZF_ARCH="aarch64" \
    FZF_INSTALL_BIN_DIR="${bin_dir}" \
    "${TARGET_SCRIPT}" >/dev/null

  assert_equal "installer skips download when target version is current" "" "$(<"${curl_log}")"
  rm -rf "${tmp_dir}"
}

run_install_case
