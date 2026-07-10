#!/usr/bin/env bash

set -euo pipefail

title() {
    printf '%s\n' "$*"
}

info() {
    printf '%s\n' "$*"
}

success() {
    printf '%s\n' "$*"
}

warning() {
    printf '%s\n' "$*" >&2
}

fetch() {
    local url="$1"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url"
        return 0
    fi

    if command -v wget >/dev/null 2>&1; then
        wget -qO- "$url"
        return 0
    fi

    warning "Skipping tuicr install because neither curl nor wget is available"
    return 1
}

resolve_latest_tuicr_version() {
    local releases_url="${TUICR_RELEASES_URL:-https://api.github.com/repos/agavra/tuicr/releases/latest}"
    local tag=""

    tag=$(fetch "$releases_url" | grep -o '"tag_name": *"[^"]*"' | head -1 | sed 's/.*"\(v[^"]*\)".*/\1/') || true
    if [[ -z "$tag" ]]; then
        warning "Skipping tuicr install because the latest release could not be resolved"
        return 1
    fi

    printf '%s\n' "${tag#v}"
}

installed_tuicr_version() {
    local tuicr_bin="$1"
    local version_output=""

    [[ -x "$tuicr_bin" ]] || return 0

    version_output=$("$tuicr_bin" --version 2>/dev/null || true)
    printf '%s\n' "$version_output" | awk '{print $2; exit}'
}

run_tuicr_installer() {
    local install_url="$1"
    local install_dir="$2"
    local version="$3"

    fetch "$install_url" | TUICR_INSTALL_DIR="$install_dir" TUICR_INSTALL_YES=1 TUICR_VERSION="$version" sh
}

remove_legacy_cargo_tuicr() {
    local installed_bin="$1"
    local legacy_bin="${CARGO_HOME:-$HOME/.cargo}/bin/tuicr"

    [[ -x "$installed_bin" && -e "$legacy_bin" ]] || return 0
    rm -f "$legacy_bin"
}

sync_tuicr() {
    local install_url="${TUICR_INSTALL_URL:-https://tuicr.dev/install.sh}"
    local install_dir="${TUICR_INSTALL_DIR:-$HOME/.local/bin}"
    local tuicr_bin="$install_dir/tuicr"
    local desired_version="${TUICR_VERSION:-}"
    local current_version=""

    title "Syncing tuicr"

    if [[ -z "$desired_version" ]]; then
        desired_version=$(resolve_latest_tuicr_version) || return 0
    else
        desired_version="${desired_version#v}"
    fi

    current_version=$(installed_tuicr_version "$tuicr_bin")
    if [[ "$current_version" == "$desired_version" ]]; then
        success "tuicr already up to date"
        remove_legacy_cargo_tuicr "$tuicr_bin"
        return 0
    fi

    info "Installing tuicr $desired_version"
    if ! run_tuicr_installer "$install_url" "$install_dir" "$desired_version"; then
        warning "Failed to install tuicr"
        return 0
    fi

    remove_legacy_cargo_tuicr "$tuicr_bin"
    success "Installed tuicr $desired_version"
}

sync_tuicr "$@"
