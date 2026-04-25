#!/usr/bin/env bash

set -euo pipefail

if [[ -n "${DOTTY_LIB:-}" && -f "${DOTTY_LIB}" ]]; then
    # shellcheck source=/dev/null
    source "${DOTTY_LIB}"
else
    title()   { printf '● %s\n' "$1"; }
    info()    { printf '%s\n' "$1"; }
    success() { printf '✔ %s\n' "$1"; }
    warning() { printf '⚠ %s\n' "$1" >&2; }
    die()     { printf '✖ %s\n' "$1" >&2; exit 1; }
fi

usage() {
    cat <<'EOF'
Usage: macos-setup.sh

Reapply tracked macOS setup:
  - Touch ID for sudo
  - macOS defaults
  - Karabiner config generation
  - font installation
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

if [[ "$(uname -s)" != "Darwin" ]]; then
    info "Skipping macOS setup (not running on macOS)"
    exit 0
fi

title "Running macOS setup"

run_touchid_setup() {
    local script="$REPO_ROOT/scripts/enable-touchid-sudo.sh"

    if [[ ! -x "$script" ]]; then
        warning "Touch ID setup script not found at $script"
        return 0
    fi

    if "$script"; then
        success "Touch ID setup completed"
    else
        warning "Touch ID setup was skipped or failed"
    fi
}

run_macos_defaults() {
    local script="$REPO_ROOT/scripts/macos.sh"

    [[ -x "$script" ]] || die "macOS configuration script not found at $script"

    info "Running macOS configuration script"
    "$script"
    success "macOS configuration completed"
}

run_karabiner_generation() {
    local script="$REPO_ROOT/scripts/karabiner-config.ts"

    [[ -f "$script" ]] || return 0

    if ! command -v bun >/dev/null 2>&1; then
        warning "Bun not found. Skipping Karabiner-Elements configuration generation."
        info "Install Bun with: brew install oven-sh/bun/bun"
        return 0
    fi

    info "Generating Karabiner-Elements configuration"
    if bun run "$script"; then
        success "Karabiner-Elements configuration generated"
    else
        warning "Failed to generate Karabiner-Elements configuration"
    fi
}

run_font_install() {
    local script="$REPO_ROOT/scripts/install-fonts.sh"

    [[ -x "$script" ]] || return 0

    info "Installing fonts"
    "$script"
}

run_touchid_setup
run_macos_defaults
run_karabiner_generation
run_font_install
