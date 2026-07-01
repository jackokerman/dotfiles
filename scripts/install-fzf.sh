#!/usr/bin/env bash

set -euo pipefail

info() {
    printf '[fzf] %s\n' "$*"
}

warning() {
    printf '[fzf] warning: %s\n' "$*" >&2
}

normalize_fzf_arch() {
    case "$1" in
        x86_64|amd64)
            printf '%s\n' "amd64"
            ;;
        arm64|aarch64)
            printf '%s\n' "arm64"
            ;;
        *)
            return 1
            ;;
    esac
}

installed_fzf_version() {
    local fzf_bin="$1"

    [[ -x "$fzf_bin" ]] || return 1
    "$fzf_bin" --version 2>/dev/null | awk '{print $1; exit}'
}

main() {
    local version="${FZF_VERSION:-0.73.1}"
    local os="${FZF_OS:-$(uname -s)}"
    local arch="" asset_version="" url="" tmp_dir="" archive_path="" target_dir="" target_path=""
    local installed_version=""

    if [[ "$os" == "Darwin" ]]; then
        info "Skipping fzf install on macOS; Homebrew owns fzf there"
        return 0
    fi

    if [[ "$os" != "Linux" ]]; then
        warning "Skipping fzf install because $os is not supported"
        return 0
    fi

    if ! arch=$(normalize_fzf_arch "${FZF_ARCH:-$(uname -m)}"); then
        warning "Skipping fzf install because architecture ${FZF_ARCH:-$(uname -m)} is not supported"
        return 0
    fi

    target_dir="${FZF_INSTALL_BIN_DIR:-$HOME/.local/bin}"
    target_path="${target_dir}/fzf"
    installed_version=$(installed_fzf_version "$target_path" || true)
    if [[ "$installed_version" == "$version" ]]; then
        info "fzf $version already installed at $target_path"
        return 0
    fi

    if ! command -v curl >/dev/null 2>&1; then
        warning "Skipping fzf install because curl is not available"
        return 0
    fi

    if ! command -v tar >/dev/null 2>&1; then
        warning "Skipping fzf install because tar is not available"
        return 0
    fi

    asset_version="${version#v}"
    url="${FZF_DOWNLOAD_URL:-https://github.com/junegunn/fzf/releases/download/v${asset_version}/fzf-${asset_version}-linux_${arch}.tar.gz}"
    tmp_dir=$(mktemp -d)
    archive_path="${tmp_dir}/fzf.tar.gz"

    if ! curl -fsSL "$url" -o "$archive_path"; then
        warning "Skipping fzf install because download failed"
        rm -rf "$tmp_dir"
        return 0
    fi

    if ! tar -xzf "$archive_path" -C "$tmp_dir"; then
        warning "Skipping fzf install because archive extraction failed"
        rm -rf "$tmp_dir"
        return 0
    fi

    if [[ ! -x "${tmp_dir}/fzf" ]]; then
        warning "Skipping fzf install because archive did not contain an executable fzf"
        rm -rf "$tmp_dir"
        return 0
    fi

    mkdir -p "$target_dir"
    mv "${tmp_dir}/fzf" "${target_path}.tmp"
    chmod 0755 "${target_path}.tmp"
    mv "${target_path}.tmp" "$target_path"
    rm -rf "$tmp_dir"
    info "Installed fzf $version at $target_path"
}

main "$@"
