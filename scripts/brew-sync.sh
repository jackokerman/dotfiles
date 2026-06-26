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

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
BREWFILE="${REPO_ROOT}/Brewfile"
CLEANUP=false

usage() {
    cat <<'EOF'
Usage: scripts/brew-sync.sh [--cleanup]

Installs packages from the tracked Brewfile. By default this does not remove
untracked Homebrew packages, because later dotty-chain repos or local machine
setup may own additional tools.

Brewfile entries marked for personal machines only are included when
HOMEBREW_DOTFILES_ENV=personal.

Options:
  --cleanup    Remove formulae and casks not present in the active Brewfile.
  -h, --help   Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --cleanup)
            CLEANUP=true
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "Unknown argument: $1"
            ;;
    esac
    shift
done

title "Installing Homebrew packages"

if ! command -v brew >/dev/null 2>&1; then
    if [[ "$(uname -s)" != "Darwin" ]]; then
        info "Skipping Homebrew setup (brew not found and not on macOS)"
        exit 0
    fi

    info "Homebrew not found. Installing Homebrew..."
    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        success "Homebrew installed successfully"
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            export PATH="/opt/homebrew/bin:$PATH"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            export PATH="/usr/local/bin:$PATH"
        fi
    else
        die "Failed to install Homebrew"
    fi
else
    info "Homebrew already installed... Skipping installation."
fi

info "Installing packages from Brewfile"
if [[ "${HOMEBREW_DOTFILES_ENV:-}" == "personal" ]]; then
    info "Including personal-only Homebrew entries."
fi
brew bundle --file "${BREWFILE}"
success "Homebrew packages installed successfully"

if [[ "$CLEANUP" == "true" ]]; then
    info "Removing formulae and casks not present in Brewfile"
    brew bundle cleanup --file "${BREWFILE}" --force --formula --cask
    success "Homebrew cleanup completed"
else
    info "Skipping Homebrew cleanup. Run dotty run brew-sync --cleanup to remove untracked packages."
fi
