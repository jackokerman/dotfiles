#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
TARGET_SCRIPT="${PROJECT_ROOT}/.dotty/run.sh"

# shellcheck source=/dev/null
source "${PROJECT_ROOT}/tests/tmux-agent-status/testlib.sh"

write_fake_dotty_lib() {
    local path="$1"

    cat > "${path}" <<'EOF'
#!/usr/bin/env bash
title() { :; }
info() { :; }
success() { :; }
warning() { printf '%s\n' "$*" >&2; }
die() { printf '%s\n' "$*" >&2; exit 1; }
create_symlink() { ln -sfn "$1" "$2"; }
EOF
}

run_setup_television() {
    local home_dir="$1" repo_dir="$2" dotty_lib="$3"

    HOME="${home_dir}" \
        TARGET_SCRIPT="${TARGET_SCRIPT}" \
        DOTTY_REPO_DIR="${repo_dir}" \
        DOTTY_LIB="${dotty_lib}" \
        DOTTY_COMMAND="update" \
        bash -c 'source "$TARGET_SCRIPT"; setup_television'
}

run_real_directory_case() {
    local tmp_dir="" home_dir="" repo_dir="" dotty_lib=""

    tmp_dir=$(mktemp -d)
    home_dir="${tmp_dir}/home"
    repo_dir="${tmp_dir}/dotfiles"
    dotty_lib="${tmp_dir}/dotty-lib.sh"

    mkdir -p \
        "${home_dir}/.config/television/cable" \
        "${repo_dir}/home/.config/television/themes"

    printf '%s\n' 'generated = true' > "${home_dir}/.config/television/config.toml"
    printf '%s\n' '# local channel' > "${home_dir}/.config/television/cable/local.toml"
    printf '%s\n' 'theme = "nightfly"' > "${repo_dir}/home/.config/television/config.toml"
    printf '%s\n' 'background = "#011627"' > "${repo_dir}/home/.config/television/themes/nightfly.toml"

    write_fake_dotty_lib "${dotty_lib}"
    chmod +x "${dotty_lib}"

    run_setup_television "${home_dir}" "${repo_dir}" "${dotty_lib}"

    assert_equal "setup_television keeps ~/.config/television as a real directory" "1" \
        "$(if [[ -d "${home_dir}/.config/television" && ! -L "${home_dir}/.config/television" ]]; then printf '1'; else printf '0'; fi)"
    assert_equal "setup_television preserves mutable cable files" "# local channel" \
        "$(cat "${home_dir}/.config/television/cable/local.toml")"
    assert_equal "setup_television links tracked config" "${repo_dir}/home/.config/television/config.toml" \
        "$(readlink "${home_dir}/.config/television/config.toml")"
    assert_equal "setup_television links tracked Nightfly theme" "${repo_dir}/home/.config/television/themes/nightfly.toml" \
        "$(readlink "${home_dir}/.config/television/themes/nightfly.toml")"

    rm -rf "${tmp_dir}"
}

run_real_directory_case
