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
HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
LINUXBREW_PREFIX="${HOMEBREW_PREFIX:-/home/linuxbrew/.linuxbrew}"
export HOMEBREW_DOTFILES_HOST_PATH="${HOMEBREW_DOTFILES_HOST_PATH:-${PATH}}"

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

host_os="$(uname -s)"

activate_linuxbrew() {
    local brew_bin="${LINUXBREW_PREFIX}/bin/brew"

    if [[ -x "${brew_bin}" ]]; then
        eval "$("${brew_bin}" shellenv)"
        return 0
    fi

    if command -v brew >/dev/null 2>&1; then
        eval "$(brew shellenv)"
        return 0
    fi

    return 1
}

install_homebrew() {
    info "Homebrew not found. Installing Homebrew..."

    if NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL "${HOMEBREW_INSTALL_URL}")"; then
        success "Homebrew installed successfully"
        return 0
    fi

    die "Failed to install Homebrew"
}

ensure_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        info "Homebrew already installed... Skipping installation."
    elif [[ "${host_os}" == "Linux" && -x "${LINUXBREW_PREFIX}/bin/brew" ]]; then
        info "Linuxbrew already installed... Adding it to PATH."
    elif [[ "${host_os}" == "Darwin" || "${host_os}" == "Linux" ]]; then
        install_homebrew
    else
        info "Skipping Homebrew setup (brew not found on ${host_os})"
        exit 0
    fi

    if [[ "${host_os}" == "Linux" ]]; then
        activate_linuxbrew || die "Failed to activate Linuxbrew at ${LINUXBREW_PREFIX}"
    elif ! command -v brew >/dev/null 2>&1; then
        if [[ -x "/opt/homebrew/bin/brew" ]]; then
            export PATH="/opt/homebrew/bin:$PATH"
        elif [[ -x "/usr/local/bin/brew" ]]; then
            export PATH="/usr/local/bin:$PATH"
        fi
    fi

    command -v brew >/dev/null 2>&1 || die "Homebrew installed but brew is not on PATH"
}

trust_formula_if_needed() {
    local formula="$1"

    if ! grep -Eq "^[[:space:]]*brew[[:space:]]+\"${formula}\"" "${BREWFILE}"; then
        return 0
    fi

    info "Trusting Homebrew formula ${formula}"
    brew trust --formula "${formula}"
}

ensure_homebrew
trust_formula_if_needed "oven-sh/bun/bun"
trust_formula_if_needed "agavra/tap/tuicr"

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
