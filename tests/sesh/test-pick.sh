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

if [[ "${1:-}" == "has-session" ]]; then
  exit 1
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
if [[ -n "${FZF_SELECTION:-}" ]]; then
  printf '%s\n' "${FZF_SELECTION}"
fi
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
  assert_matches "sesh-pick keeps the remote refresh bind without extra entries" \
    'ctrl-x:change-prompt\(📦  \)\+reload\(.*/home/\.local/bin/sesh-pick --refresh-extra\)' \
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
  if [[ "$(cat "${tmp_dir}/fzf-with-extra.log")" =~ load:reload ]]; then
    fail "sesh-pick does not mutate the active picker after load"
  fi
  pass "sesh-pick does not mutate the active picker after load"
  rm -rf "${tmp_dir}"
}

run_extra_entries_hide_emoji_suffix_duplicates_case() {
  local tmp_dir="" home_dir="" cache_dir="" config_dir="" bin_dir="" actual="" extra_file=""

  tmp_dir=$(mktemp -d)
  home_dir="${tmp_dir}/home"
  cache_dir="${tmp_dir}/cache"
  config_dir="${tmp_dir}/config"
  bin_dir="${tmp_dir}/bin"
  extra_file="${cache_dir}/sesh-extra-entries"

  mkdir -p "${home_dir}" "${cache_dir}" "${config_dir}" "${bin_dir}"
  printf '📦 remote-session 🌮\n📦 other-remote 🥙\n' > "${extra_file}"
  write_stub_commands "${bin_dir}"

  cat > "${bin_dir}/tmux" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "list-sessions" ]]; then
  printf 'remote-session\n'
  exit 0
fi

exit 0
EOF
  chmod +x "${bin_dir}/tmux"

  actual=$(
    HOME="${home_dir}" \
      PATH="${bin_dir}:${PATH}" \
      XDG_CACHE_HOME="${cache_dir}" \
      XDG_CONFIG_HOME="${config_dir}" \
      bash "${PICKER}" --extra
  )

  assert_equal "sesh-pick hides emoji-suffixed extra entries for active tmux sessions" "📦 other-remote 🥙" "${actual}"
  rm -rf "${tmp_dir}"
}

run_all_ignores_stale_sesh_tmux_cache_case() {
  local tmp_dir="" home_dir="" cache_dir="" config_dir="" bin_dir="" actual="" extra_file=""

  tmp_dir=$(mktemp -d)
  home_dir="${tmp_dir}/home"
  cache_dir="${tmp_dir}/cache"
  config_dir="${tmp_dir}/config"
  bin_dir="${tmp_dir}/bin"
  extra_file="${cache_dir}/sesh-extra-entries"

  mkdir -p "${home_dir}" "${cache_dir}" "${config_dir}" "${bin_dir}"
  printf '📦 stale-remote 🌮\n' > "${extra_file}"
  write_stub_commands "${bin_dir}"

  cat > "${bin_dir}/sesh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "list" ]]; then
  case "${2:-}" in
    -it) printf '🪟 stale-remote\n' ;;
    -ic|-iz) ;;
  esac
  exit 0
fi

exit 1
EOF
  chmod +x "${bin_dir}/sesh"

  actual=$(
    HOME="${home_dir}" \
      PATH="${bin_dir}:${PATH}" \
      XDG_CACHE_HOME="${cache_dir}" \
      XDG_CONFIG_HOME="${config_dir}" \
      bash "${PICKER}" --all
  )

  assert_equal "sesh-pick ignores stale sesh tmux cache rows" "📦 stale-remote 🌮" "${actual}"
  rm -rf "${tmp_dir}"
}

run_tmux_entries_sort_by_recent_activity_case() {
  local tmp_dir="" home_dir="" cache_dir="" config_dir="" bin_dir="" actual="" expected=""

  tmp_dir=$(mktemp -d)
  home_dir="${tmp_dir}/home"
  cache_dir="${tmp_dir}/cache"
  config_dir="${tmp_dir}/config"
  bin_dir="${tmp_dir}/bin"

  mkdir -p "${home_dir}" "${cache_dir}" "${config_dir}" "${bin_dir}"
  write_stub_commands "${bin_dir}"

  cat > "${bin_dir}/tmux" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "list-sessions" ]]; then
  printf '20\t\033[34m\033[39m middle\n'
  printf '10\t\033[34m\033[39m oldest\n'
  printf '30\t\033[34m\033[39m newest\n'
  exit 0
fi

exit 1
EOF
  chmod +x "${bin_dir}/tmux"

  actual=$(
    HOME="${home_dir}" \
      PATH="${bin_dir}:${PATH}" \
      XDG_CACHE_HOME="${cache_dir}" \
      XDG_CONFIG_HOME="${config_dir}" \
      bash "${PICKER}" --tmux
  )

  expected=$'\033[34m\033[39m newest\n\033[34m\033[39m middle\n\033[34m\033[39m oldest'
  assert_equal "sesh-pick sorts tmux sessions by recent activity" "${expected}" "${actual}"
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

run_async_refresh_hook_case() {
  local tmp_dir="" home_dir="" cache_dir="" config_dir="" bin_dir="" refresh_hook="" actual=""

  tmp_dir=$(mktemp -d)
  home_dir="${tmp_dir}/home"
  cache_dir="${tmp_dir}/cache"
  config_dir="${tmp_dir}/config"
  bin_dir="${tmp_dir}/bin"
  refresh_hook="${config_dir}/sesh/hooks/refresh.d/remote"

  mkdir -p "${home_dir}" "${cache_dir}" "${config_dir}/sesh/hooks/refresh.d" "${bin_dir}"
  write_stub_commands "${bin_dir}"

  cat > "${refresh_hook}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'ran\n' > "${XDG_CACHE_HOME}/async-refresh-ran"
EOF
  chmod +x "${refresh_hook}"

  HOME="${home_dir}" \
    PATH="${bin_dir}:${PATH}" \
    XDG_CACHE_HOME="${cache_dir}" \
    XDG_CONFIG_HOME="${config_dir}" \
    FZF_ARGS_LOG="${tmp_dir}/fzf-async.log" \
    bash "${PICKER}" >/dev/null

  for _ in 1 2 3 4 5; do
    [[ -f "${cache_dir}/async-refresh-ran" ]] && break
    sleep 0.1
  done

  actual="$(cat "${cache_dir}/async-refresh-ran" 2>/dev/null || true)"
  assert_equal "sesh-pick runs refresh hooks asynchronously when opened" "ran" "${actual}"
  rm -rf "${tmp_dir}"
}

run_icon_prefixed_tmux_selection_connects_by_name_case() {
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
      FZF_ARGS_LOG="${tmp_dir}/fzf-tmux.log" \
      FZF_SELECTION=$'\033[34m\033[39m alpha' \
      bash "${PICKER}"
  )

  assert_equal "sesh-pick strips presentation icons before sesh connect" "connect:alpha" "${actual}"
  rm -rf "${tmp_dir}"
}

run_icon_prefixed_config_selection_preserves_spaces_case() {
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
      FZF_ARGS_LOG="${tmp_dir}/fzf-config.log" \
      FZF_SELECTION=$'\033[35m📁\033[39m Plan capture 📝' \
      bash "${PICKER}"
  )

  assert_equal "sesh-pick keeps spaces after stripping a configured-session icon" "connect:Plan capture 📝" "${actual}"
  rm -rf "${tmp_dir}"
}

run_plain_selection_with_spaces_is_not_stripped_case() {
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
      FZF_ARGS_LOG="${tmp_dir}/fzf-path.log" \
      FZF_SELECTION="/tmp/project with spaces" \
      bash "${PICKER}"
  )

  assert_equal "sesh-pick does not strip plain paths with spaces" "connect:/tmp/project with spaces" "${actual}"
  rm -rf "${tmp_dir}"
}

run_hook_receives_normalized_extra_entry_case() {
  local tmp_dir="" home_dir="" cache_dir="" config_dir="" bin_dir="" hook="" actual=""

  tmp_dir=$(mktemp -d)
  home_dir="${tmp_dir}/home"
  cache_dir="${tmp_dir}/cache"
  config_dir="${tmp_dir}/config"
  bin_dir="${tmp_dir}/bin"
  hook="${config_dir}/sesh/hooks/connect.d/remote"

  mkdir -p "${home_dir}" "${cache_dir}" "${config_dir}/sesh/hooks/connect.d" "${bin_dir}"
  write_stub_commands "${bin_dir}"

  cat > "${hook}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'hook:%s\n' "${1:-}"
EOF
  chmod +x "${hook}"

  actual=$(
    HOME="${home_dir}" \
      PATH="${bin_dir}:${PATH}" \
      XDG_CACHE_HOME="${cache_dir}" \
      XDG_CONFIG_HOME="${config_dir}" \
      FZF_ARGS_LOG="${tmp_dir}/fzf-hook.log" \
      FZF_SELECTION=$'📦 remote-session 🌮' \
      bash "${PICKER}"
  )

  assert_equal "sesh-pick passes stable labels to connect hooks" "hook:remote-session 🌮" "${actual}"
  rm -rf "${tmp_dir}"
}

run_tmux_selection_bypasses_connect_hooks_case() {
  local tmp_dir="" home_dir="" cache_dir="" config_dir="" bin_dir="" hook="" actual=""

  tmp_dir=$(mktemp -d)
  home_dir="${tmp_dir}/home"
  cache_dir="${tmp_dir}/cache"
  config_dir="${tmp_dir}/config"
  bin_dir="${tmp_dir}/bin"
  hook="${config_dir}/sesh/hooks/connect.d/remote"

  mkdir -p "${home_dir}" "${cache_dir}" "${config_dir}/sesh/hooks/connect.d" "${bin_dir}"
  write_stub_commands "${bin_dir}"

  cat > "${bin_dir}/tmux" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "list-sessions" ]]; then
  printf 'alpha\n'
  exit 0
fi

if [[ "${1:-}" == "has-session" && "${2:-}" == "-t" && "${3:-}" == "alpha" ]]; then
  exit 0
fi

exit 1
EOF
  chmod +x "${bin_dir}/tmux"

  cat > "${hook}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'hook:%s\n' "${1:-}"
EOF
  chmod +x "${hook}"

  actual=$(
    HOME="${home_dir}" \
      PATH="${bin_dir}:${PATH}" \
      XDG_CACHE_HOME="${cache_dir}" \
      XDG_CONFIG_HOME="${config_dir}" \
      FZF_ARGS_LOG="${tmp_dir}/fzf-hook-bypass.log" \
      FZF_SELECTION=$'\033[34m\033[39m alpha' \
      bash "${PICKER}"
  )

  assert_equal "sesh-pick bypasses connect hooks for existing tmux sessions" "connect:alpha" "${actual}"
  rm -rf "${tmp_dir}"
}

run_without_extra_entries_case
run_with_extra_entries_case
run_extra_entries_hide_emoji_suffix_duplicates_case
run_all_ignores_stale_sesh_tmux_cache_case
run_tmux_entries_sort_by_recent_activity_case
run_refresh_extra_case
run_async_refresh_hook_case
run_icon_prefixed_tmux_selection_connects_by_name_case
run_icon_prefixed_config_selection_preserves_spaces_case
run_plain_selection_with_spaces_is_not_stripped_case
run_hook_receives_normalized_extra_entry_case
run_tmux_selection_bypasses_connect_hooks_case
