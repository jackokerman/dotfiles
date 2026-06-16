#!/usr/bin/env bash
set -euo pipefail

GSD_VERSION="${GSD_VERSION:-v1.4.0}"
GSD_PROFILE="${GSD_PROFILE:-standard}"
GSD_REPO_URL="${GSD_REPO_URL:-https://github.com/open-gsd/gsd-core.git}"
GSD_INSTALL_ROOT="${GSD_INSTALL_ROOT:-$HOME/.local/share/gsd-core}"
GSD_REPO_DIR="${GSD_REPO_DIR:-$GSD_INSTALL_ROOT/repo}"
GSD_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/gsd-core"
GSD_ENABLED_MARKER="$GSD_STATE_DIR/enabled"
GSD_DISABLED_MARKER="$GSD_STATE_DIR/disabled"
GSD_DEPENDENCY_STAMP="$GSD_STATE_DIR/package-lock.cksum"
GSD_AGENT_NAMES=(
    gsd-code-fixer
    gsd-code-reviewer
    gsd-executor
    gsd-phase-researcher
    gsd-plan-checker
    gsd-planner
)

log() {
    printf '[install-gsd-core] %s\n' "$*"
}

warn() {
    printf '[install-gsd-core] warning: %s\n' "$*" >&2
}

fail() {
    printf '[install-gsd-core] error: %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Usage: install-gsd-core.sh [--install|--auto-install|--auto-reapply|--uninstall|--status]

Installs a pinned GSD Core checkout and its Codex global integration.

Modes:
  --install       Install now, enable future reapply, and clear any disabled marker.
  --auto-install  Install unless the disabled marker exists. Used by later dotty overlays.
  --auto-reapply  Reinstall only when already enabled. Used by base dotfiles updates.
  --uninstall     Uninstall GSD from Codex, remove shims, and mark disabled.
  --status        Print local install state.
EOF
}

mode="install"
case "${1:-}" in
    ""|--install)
        mode="install"
        ;;
    --auto-install)
        mode="auto-install"
        ;;
    --auto-reapply)
        mode="auto-reapply"
        ;;
    --uninstall)
        mode="uninstall"
        ;;
    --status)
        mode="status"
        ;;
    -h|--help)
        usage
        exit 0
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac

mkdir -p "$GSD_STATE_DIR"

node_major_version() {
    node -p 'Number(process.versions.node.split(".")[0])'
}

ensure_node() {
    if ! command -v node >/dev/null 2>&1; then
        if [[ "$(uname -s)" == "Darwin" ]] && command -v brew >/dev/null 2>&1; then
            log "Node not found; installing node with Homebrew"
            brew install node
        else
            fail "Node is required. Install Node >=22, then rerun this command."
        fi
    fi

    if [[ "$(node_major_version)" -lt 22 ]]; then
        fail "Node >=22 is required; found $(node --version)."
    fi

    if ! command -v npm >/dev/null 2>&1; then
        fail "npm is required. Install npm >=10, then rerun this command."
    fi

    if [[ "$(npm --version | awk -F. '{print $1}')" -lt 10 ]]; then
        fail "npm >=10 is required; found $(npm --version)."
    fi
}

ensure_checkout() {
    mkdir -p "$GSD_INSTALL_ROOT"

    if [[ ! -e "$GSD_REPO_DIR" ]]; then
        log "Cloning GSD Core $GSD_VERSION"
        git clone --branch "$GSD_VERSION" --depth 1 "$GSD_REPO_URL" "$GSD_REPO_DIR"
        return
    fi

    if [[ ! -d "$GSD_REPO_DIR/.git" ]]; then
        fail "$GSD_REPO_DIR exists but is not a git checkout."
    fi

    local origin_url=""
    origin_url="$(git -C "$GSD_REPO_DIR" remote get-url origin 2>/dev/null || true)"
    if [[ "$origin_url" != "$GSD_REPO_URL" ]]; then
        fail "$GSD_REPO_DIR origin is $origin_url, expected $GSD_REPO_URL."
    fi

    if [[ -n "$(git -C "$GSD_REPO_DIR" status --porcelain)" ]]; then
        fail "$GSD_REPO_DIR has local changes; refusing to update managed checkout."
    fi

    git -C "$GSD_REPO_DIR" fetch --depth 1 origin "refs/tags/$GSD_VERSION:refs/tags/$GSD_VERSION" >/dev/null
    git -C "$GSD_REPO_DIR" checkout --detach "$GSD_VERSION" >/dev/null
}

package_lock_cksum() {
    cksum "$GSD_REPO_DIR/package-lock.json" | awk '{print $1 ":" $2}'
}

ensure_dependencies() {
    local current_stamp=""
    local previous_stamp=""

    current_stamp="$(package_lock_cksum)"
    previous_stamp="$(sed -n '1p' "$GSD_DEPENDENCY_STAMP" 2>/dev/null || true)"

    if [[ -d "$GSD_REPO_DIR/node_modules" && "$current_stamp" == "$previous_stamp" ]]; then
        log "GSD dependencies already installed"
        return
    fi

    log "Installing GSD dependencies"
    (cd "$GSD_REPO_DIR" && npm ci --min-release-age=0)
    printf '%s\n' "$current_stamp" > "$GSD_DEPENDENCY_STAMP"
}

build_gsd() {
    log "Building GSD hooks"
    (cd "$GSD_REPO_DIR" && node scripts/build-hooks.js)
}

write_shims() {
    local bin_dir="$HOME/.local/bin"
    mkdir -p "$bin_dir"

    cat > "$bin_dir/gsd-tools" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exec node "$HOME/.codex/gsd-core/bin/gsd-tools.cjs" "$@"
EOF
    chmod +x "$bin_dir/gsd-tools"

    cat > "$bin_dir/gsd-core-install" <<EOF
#!/usr/bin/env bash
set -euo pipefail
exec node "$GSD_REPO_DIR/bin/install.js" "\$@"
EOF
    chmod +x "$bin_dir/gsd-core-install"
}

gsd_agent_files_exist() {
    local agent_name=""

    [[ "$GSD_PROFILE" != "core" ]] || return 0

    for agent_name in "${GSD_AGENT_NAMES[@]}"; do
        [[ -f "$HOME/.codex/agents/${agent_name}.toml" ]] || return 1
    done
}

gsd_agent_config_paths_are_current() {
    local agent_name=""
    local config_path="$HOME/.codex/config.toml"
    local expected_line=""

    [[ "$GSD_PROFILE" != "core" ]] || return 0
    [[ -f "$config_path" ]] || return 1

    for agent_name in "${GSD_AGENT_NAMES[@]}"; do
        expected_line="config_file = \"$HOME/.codex/agents/${agent_name}.toml\""
        awk -v section="[agents.${agent_name}]" -v expected_line="$expected_line" '
            $0 == section {
                in_section = 1
                next
            }

            in_section && /^\[/ {
                exit 1
            }

            in_section && $0 == expected_line {
                found = 1
                exit 0
            }

            END {
                if (!found) {
                    exit 1
                }
            }
        ' "$config_path" || return 1
    done
}

repair_gsd_agent_config_paths() {
    local agent_name=""
    local config_path="$HOME/.codex/config.toml"
    local expected_line=""
    local tmp_path=""

    [[ "$GSD_PROFILE" != "core" ]] || return 0
    [[ -f "$config_path" ]] || return 0

    for agent_name in "${GSD_AGENT_NAMES[@]}"; do
        expected_line="config_file = \"$HOME/.codex/agents/${agent_name}.toml\""
        tmp_path="${config_path}.gsd-agent-paths.$$"
        awk -v section="[agents.${agent_name}]" -v expected_line="$expected_line" '
            $0 == section {
                in_section = 1
                print
                next
            }

            in_section && /^\[/ {
                in_section = 0
            }

            in_section && /^config_file = "/ {
                print expected_line
                next
            }

            {
                print
            }
        ' "$config_path" > "$tmp_path" && mv "$tmp_path" "$config_path"
    done
}

gsd_codex_install_is_current() {
    [[ -f "$HOME/.codex/gsd-core/VERSION" ]] || return 1
    [[ "$(sed -n '1p' "$HOME/.codex/gsd-core/VERSION" 2>/dev/null)" == "${GSD_VERSION#v}" ]] || return 1
    [[ "$(sed -n '1p' "$HOME/.codex/.gsd-profile" 2>/dev/null)" == "$GSD_PROFILE" ]] || return 1
    [[ -f "$HOME/.codex/skills/gsd-new-project/SKILL.md" ]] || return 1
    gsd_agent_files_exist || return 1
    gsd_agent_config_paths_are_current || return 1
    [[ -x "$HOME/.local/bin/gsd-tools" ]] || return 1
}

install_gsd() {
    repair_gsd_agent_config_paths

    if gsd_codex_install_is_current; then
        rm -f "$GSD_DISABLED_MARKER"
        printf '%s\n' "$GSD_VERSION" > "$GSD_ENABLED_MARKER"
        log "GSD Core $GSD_VERSION already installed"
        return
    fi

    ensure_node
    ensure_checkout
    ensure_dependencies
    build_gsd

    log "Installing GSD Codex integration"
    node "$GSD_REPO_DIR/bin/install.js" --codex --global "--profile=$GSD_PROFILE"
    repair_gsd_agent_config_paths
    write_shims
    rm -f "$GSD_DISABLED_MARKER"
    printf '%s\n' "$GSD_VERSION" > "$GSD_ENABLED_MARKER"
    log "GSD Core $GSD_VERSION installed"
}

uninstall_gsd() {
    if [[ -f "$GSD_REPO_DIR/bin/install.js" ]]; then
        log "Uninstalling GSD Codex integration"
        node "$GSD_REPO_DIR/bin/install.js" --codex --global --uninstall || warn "GSD uninstall command failed"
    else
        warn "GSD checkout not found; removing local markers and shims only"
    fi

    rm -f "$HOME/.local/bin/gsd-tools" "$HOME/.local/bin/gsd-core-install"
    rm -f "$GSD_ENABLED_MARKER"
    printf '%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" > "$GSD_DISABLED_MARKER"
    log "GSD disabled. Run dotty run install-gsd-core to reinstall."
}

print_status() {
    printf 'version=%s\n' "$GSD_VERSION"
    printf 'profile=%s\n' "$GSD_PROFILE"
    printf 'repo=%s\n' "$GSD_REPO_DIR"
    printf 'enabled=%s\n' "$([[ -f "$GSD_ENABLED_MARKER" ]] && echo yes || echo no)"
    printf 'disabled=%s\n' "$([[ -f "$GSD_DISABLED_MARKER" ]] && echo yes || echo no)"
    printf 'gsd_tools=%s\n' "$([[ -x "$HOME/.local/bin/gsd-tools" ]] && echo yes || echo no)"
    printf 'gsd_agents=%s\n' "$(gsd_agent_files_exist && echo yes || echo no)"
    printf 'gsd_agent_config_paths=%s\n' "$(gsd_agent_config_paths_are_current && echo current || echo stale)"
}

case "$mode" in
    install)
        install_gsd
        ;;
    auto-install)
        if [[ -f "$GSD_DISABLED_MARKER" ]]; then
            log "GSD disabled marker exists; skipping auto-install"
            exit 0
        fi
        install_gsd
        ;;
    auto-reapply)
        if [[ ! -f "$GSD_ENABLED_MARKER" || -f "$GSD_DISABLED_MARKER" ]]; then
            exit 0
        fi
        install_gsd
        ;;
    uninstall)
        uninstall_gsd
        ;;
    status)
        print_status
        ;;
esac
