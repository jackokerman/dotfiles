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

tuicr_checkout_is_dirty() {
    local repo_dir="$1"
    local status=""

    status=$(git -C "$repo_dir" status --porcelain 2>/dev/null || true)
    [[ -n "$status" ]]
}

tuicr_checkout_branch() {
    local repo_dir="$1"

    git -C "$repo_dir" symbolic-ref --quiet --short HEAD 2>/dev/null || true
}

tuicr_checkout_origin() {
    local repo_dir="$1"

    git -C "$repo_dir" remote get-url origin 2>/dev/null || true
}

ensure_tuicr_cargo() {
    export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
    export PATH="$CARGO_HOME/bin:$PATH"

    if command -v cargo >/dev/null 2>&1; then
        return 0
    fi

    if ! command -v curl >/dev/null 2>&1; then
        warning "Skipping tuicr install because curl is not available for rustup bootstrap"
        return 1
    fi

    info "Bootstrapping Rust with rustup"
    if ! curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal --no-modify-path; then
        warning "Skipping tuicr install because rustup bootstrap failed"
        return 1
    fi

    export PATH="$CARGO_HOME/bin:$PATH"
    if ! command -v cargo >/dev/null 2>&1; then
        warning "Skipping tuicr install because cargo is still unavailable after rustup bootstrap"
        return 1
    fi

    return 0
}

sync_tuicr() {
    local repo_url="${TUICR_REPO_URL:-https://github.com/agavra/tuicr.git}"
    local branch="${TUICR_BRANCH:-main}"
    local install_root="${TUICR_INSTALL_ROOT:-$HOME/.local/share/tuicr}"
    local repo_dir="${TUICR_REPO_DIR:-${install_root}/repo}"
    local state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/tuicr"
    local install_rev_file="${state_dir}/install-rev"
    local tuicr_bin="${CARGO_HOME:-$HOME/.cargo}/bin/tuicr"
    local branch_name="" origin_url="" before="" after="" current_rev="" installed_rev=""

    title "Syncing tuicr"

    mkdir -p "$install_root" "$state_dir" "$(dirname "$repo_dir")"

    if [[ ! -e "$repo_dir" ]]; then
        if ! git clone --branch "$branch" "$repo_url" "$repo_dir"; then
            warning "Failed to clone tuicr from $repo_url"
            return 0
        fi
        success "Installed tuicr checkout"
    fi

    if [[ ! -d "$repo_dir/.git" ]]; then
        warning "Skipping tuicr setup because $repo_dir is not a git checkout"
        return 0
    fi

    branch_name=$(tuicr_checkout_branch "$repo_dir")
    if [[ "$branch_name" != "$branch" ]]; then
        warning "Skipping tuicr update because the checkout is not on $branch"
        return 0
    fi

    origin_url=$(tuicr_checkout_origin "$repo_dir")
    if [[ "$origin_url" != "$repo_url" ]]; then
        warning "Skipping tuicr update because origin does not match $repo_url"
        return 0
    fi

    if tuicr_checkout_is_dirty "$repo_dir"; then
        warning "Skipping tuicr update because the checkout is dirty"
        return 0
    fi

    before=$(git -C "$repo_dir" rev-parse HEAD 2>/dev/null || true)
    if ! git -C "$repo_dir" fetch origin "$branch" >/dev/null 2>&1; then
        warning "Skipping tuicr update because fetch from origin failed"
        return 0
    fi

    if ! git -C "$repo_dir" merge --ff-only "origin/$branch" >/dev/null 2>&1; then
        warning "Skipping tuicr update because the checkout could not be fast-forwarded"
        return 0
    fi

    after=$(git -C "$repo_dir" rev-parse HEAD 2>/dev/null || true)
    if [[ -n "$before" && "$before" != "$after" ]]; then
        success "Updated tuicr checkout"
    fi

    if ! ensure_tuicr_cargo; then
        return 0
    fi

    current_rev="${after:-$before}"
    if [[ -z "$current_rev" ]]; then
        warning "Skipping tuicr install because the checkout revision could not be determined"
        return 0
    fi

    if [[ -f "$install_rev_file" ]]; then
        installed_rev=$(sed -n '1p' "$install_rev_file" | tr -d '\r')
    fi
    if [[ "$current_rev" == "$installed_rev" && -x "$tuicr_bin" ]]; then
        success "tuicr already up to date"
        return 0
    fi

    if ! cargo install --path "$repo_dir" --locked --force; then
        warning "Failed to install tuicr from $repo_dir"
        return 0
    fi

    printf '%s\n' "$current_rev" > "$install_rev_file"
    if [[ -n "$installed_rev" ]]; then
        success "Updated tuicr"
    else
        success "Installed tuicr"
    fi
}

sync_tuicr "$@"
