#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
PICKER="${PROJECT_ROOT}/home/.local/bin/sesh-pick"

# shellcheck source=/dev/null
source "${PROJECT_ROOT}/tests/tmux-agent-status/testlib.sh"

write_stub_commands() {
  local bin_dir="$1"

  cat > "${bin_dir}/sesh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "list" ]]; then
  case "${2:-}" in
    -it) printf '🪟 alpha\n' ;;
    -ic) printf '📁 /tmp/project\n' ;;
    -iz) printf '⚙️ scratch\n' ;;
  esac
  exit 0
fi

if [[ "${1:-}" == "connect" ]]; then
  printf 'connect:%s\n' "${2:-}"
  exit 0
fi

exit 1
EOF

  cat > "${bin_dir}/tmux" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "list-sessions" ]]; then
  exit 0
fi

if [[ "${1:-}" == "kill-session" ]]; then
  exit 0
fi

exit 0
EOF

  cat > "${bin_dir}/fd" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '/tmp/project\n'
EOF

  cat > "${bin_dir}/fzf" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" > "${FZF_ARGS_LOG:?}"
cat >/dev/null
exit 0
EOF

  chmod +x "${bin_dir}/sesh" "${bin_dir}/tmux" "${bin_dir}/fd" "${bin_dir}/fzf"
}

run_without_extra_entries_case() {
  local tmp_dir="" home_dir="" cache_dir="" config_dir="" bin_dir="" actual=""

  tmp_dir=$(mktemp -d)
  home_dir="${tmp_dir}/home"
  cache_dir="${tmp_dir}/cache"
  config_dir="${tmp_dir}/config"
  bin_dir="${tmp_dir}/bin"

  mkdir -p "${home_dir}" "${cache_dir}" "${config_dir}" "${bin_dir}"
  write_stub_commands "${bin_dir}"

  actual=$(
    HOME="${home_dir}" \
      PATH="${bin_dir}:${PATH}" \
      XDG_CACHE_HOME="${cache_dir}" \
      XDG_CONFIG_HOME="${config_dir}" \
      FZF_ARGS_LOG="${tmp_dir}/fzf-no-extra.log" \
      bash "${PICKER}"
  )

  assert_equal "sesh-pick exits cleanly without extra entries on bash 3.2" "" "${actual}"
  assert_matches "sesh-pick does not add the remote bind without extra entries" \
    '--header=  \^a all \^t tmux \^d kill \^f find' \
    "$(cat "${tmp_dir}/fzf-no-extra.log")"
  rm -rf "${tmp_dir}"
}

run_with_extra_entries_case() {
  local tmp_dir="" home_dir="" cache_dir="" config_dir="" bin_dir="" actual="" extra_file=""

  tmp_dir=$(mktemp -d)
  home_dir="${tmp_dir}/home"
  cache_dir="${tmp_dir}/cache"
  config_dir="${tmp_dir}/config"
  bin_dir="${tmp_dir}/bin"
  extra_file="${cache_dir}/sesh-extra-entries"

  mkdir -p "${home_dir}" "${cache_dir}" "${config_dir}" "${bin_dir}"
  printf '📦 remote-session\n' > "${extra_file}"
  write_stub_commands "${bin_dir}"

  actual=$(
    HOME="${home_dir}" \
      PATH="${bin_dir}:${PATH}" \
      XDG_CACHE_HOME="${cache_dir}" \
      XDG_CONFIG_HOME="${config_dir}" \
      FZF_ARGS_LOG="${tmp_dir}/fzf-with-extra.log" \
      bash "${PICKER}"
  )

  assert_equal "sesh-pick exits cleanly with extra entries on bash 3.2" "" "${actual}"
  assert_matches "sesh-pick adds the remote bind when extra entries exist" \
    'ctrl-x:change-prompt\(📦  \)\+reload\(.*/home/\.local/bin/sesh-pick --refresh-extra\)' \
    "$(cat "${tmp_dir}/fzf-with-extra.log")"
  assert_matches "sesh-pick reloads once through refreshed entries" \
    'load:reload\(.*/home/\.local/bin/sesh-pick --refresh-all\)\+unbind\(load\)' \
    "$(cat "${tmp_dir}/fzf-with-extra.log")"
  rm -rf "${tmp_dir}"
}

run_refresh_extra_case() {
  local tmp_dir="" home_dir="" cache_dir="" config_dir="" bin_dir="" actual="" extra_file="" refresh_hook=""

  tmp_dir=$(mktemp -d)
  home_dir="${tmp_dir}/home"
  cache_dir="${tmp_dir}/cache"
  config_dir="${tmp_dir}/config"
  bin_dir="${tmp_dir}/bin"
  extra_file="${cache_dir}/sesh-extra-entries"
  refresh_hook="${config_dir}/sesh/hooks/refresh.d/remote"

  mkdir -p "${home_dir}" "${cache_dir}" "${config_dir}/sesh/hooks/refresh.d" "${bin_dir}"
  printf '📦 stale-remote\n' > "${extra_file}"
  write_stub_commands "${bin_dir}"

  cat > "${refresh_hook}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '📦 fresh-remote\n' > "${XDG_CACHE_HOME}/sesh-extra-entries"
EOF
  chmod +x "${refresh_hook}"

  actual=$(
    HOME="${home_dir}" \
      PATH="${bin_dir}:${PATH}" \
      XDG_CACHE_HOME="${cache_dir}" \
      XDG_CONFIG_HOME="${config_dir}" \
      bash "${PICKER}" --refresh-extra
  )

  assert_equal "sesh-pick --refresh-extra refreshes before printing extra entries" "📦 fresh-remote" "${actual}"
  rm -rf "${tmp_dir}"
}

run_without_extra_entries_case
run_with_extra_entries_case
run_refresh_extra_case
