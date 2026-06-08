#!/usr/bin/env bash
#
# dotty hook for personal dotfiles.
# Runs after symlinks are created. DOTTY_REPO_DIR, DOTTY_ENV, and
# DOTTY_COMMAND (install/update) are exported by dotty.

DOTFILES="$DOTTY_REPO_DIR"
source "$DOTTY_LIB"

# Guard

setup_guard() {
    title "Setting up commit guard"

    if command -v dotty >/dev/null 2>&1; then
        dotty guard "$DOTFILES"
    fi
}

setup_git_hooks() {
    title "Installing repo-local Git hooks"

    local hook_installer="$DOTFILES/scripts/install-git-hooks.sh"
    if [[ ! -x "$hook_installer" ]]; then
        warning "Git hook installer not found at $hook_installer"
        return 0
    fi

    if "$hook_installer"; then
        success "Repo-local Git hooks installed"
    else
        warning "Failed to install repo-local Git hooks"
    fi
}

sync_repo_submodules() {
    title "Syncing repo submodules"

    if [[ ! -e "$DOTFILES/.git" ]]; then
        warning "Skipping repo submodule sync because $DOTFILES is not a git checkout"
        return 0
    fi

    if git -C "$DOTFILES" submodule update --init --recursive; then
        success "Repo submodules synced"
    else
        warning "Failed to sync repo submodules"
    fi
}

# VS Code / Cursor

setup_vscode() {
    title "Setting up VS Code and Cursor"

    local vscode_user_dir="$HOME/Library/Application Support/Code/User"
    local cursor_user_dir="$HOME/Library/Application Support/Cursor/User"
    local template_settings="$DOTFILES/vscode-settings.json"

    mkdir -p "$vscode_user_dir"
    mkdir -p "$cursor_user_dir"

    for target in "$vscode_user_dir/settings.json" "$cursor_user_dir/settings.json"; do
        if ! command -v jq &>/dev/null; then
            warning "jq not found, copying settings instead of merging"
            cp "$template_settings" "$target"
        elif [[ -f "$target" ]]; then
            jq -s '.[0] * .[1]' "$target" "$template_settings" > "$target.tmp" && mv "$target.tmp" "$target"
        else
            cp "$template_settings" "$target"
        fi
    done

}

# Shell tools

migrate_legacy_zshrc_wrapper() {
    local legacy_zshrc="$HOME/.zshrc"
    local backup_zshrc="$HOME/.zshrc.pre-zdotdir-backup"
    local backup_index=1

    [[ -f "$legacy_zshrc" && ! -L "$legacy_zshrc" ]] || return 0

    if ! grep -Eq '(^|[[:space:]])source[[:space:]].*/dotfiles/home/\.zshrc($|[[:space:]])' "$legacy_zshrc"; then
        return 0
    fi

    while [[ -e "$backup_zshrc" ]]; do
        backup_zshrc="$HOME/.zshrc.pre-zdotdir-backup.$backup_index"
        ((backup_index++))
    done

    mv "$legacy_zshrc" "$backup_zshrc"
    success "Moved stale ~/.zshrc wrapper to $backup_zshrc"
}

setup_shell() {
    title "Setting up shell"

    migrate_legacy_zshrc_wrapper

    # bat cache (for custom themes used by delta)
    if command -v bat >/dev/null 2>&1 \
        && [ -d "$(bat --config-dir)/themes" ]; then
        info "Setting up bat"
        bat cache --build
    fi

    # Initialize zsh plugins so first interactive shell is clean
    if command -v zsh >/dev/null 2>&1 && [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/.zshrc" ]; then
        info "Initializing ZSH plugins..."
        zsh -i -c 'exit 0' 2>&1 || true
        success "ZSH plugins initialized"
    fi
}

setup_tmux_agent_bar() {
    local sync_script="$DOTFILES/scripts/sync-tmux-agent-bar.sh"

    title "Syncing tmux-agent-bar"

    if [[ ! -x "$sync_script" ]]; then
        warning "tmux-agent-bar sync script not found at $sync_script"
        return 0
    fi

    if ! "$sync_script"; then
        if [[ "${DOTTY_COMMAND:-}" == "install" ]]; then
            die "Failed to sync tmux-agent-bar"
        fi
        warning "Failed to sync tmux-agent-bar"
    fi
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

setup_tuicr() {
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

    installed_rev=$(sed -n '1p' "$install_rev_file" 2>/dev/null | tr -d '\r')
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

# Homebrew

run_brew_sync() {
    local brew_sync_script="$DOTFILES/scripts/brew-sync.sh"

    if [[ ! -x "$brew_sync_script" ]]; then
        warning "Homebrew sync script not found at $brew_sync_script"
        return 0
    fi

    if "$brew_sync_script"; then
        success "Homebrew packages synced"
    else
        warning "Homebrew package sync failed"
    fi
}

# macOS

setup_macos() {
    local macos_setup_script="$DOTFILES/scripts/macos-setup.sh"

    [[ -x "$macos_setup_script" ]] || die "macOS setup script not found at $macos_setup_script"
    "$macos_setup_script"
}

setup_handy() {
    local sync_script="$DOTFILES/scripts/sync-handy-settings.sh"

    if [[ "$(uname -s)" != "Darwin" ]]; then
        return 0
    fi

    title "Syncing Handy config"

    if [[ ! -x "$sync_script" ]]; then
        warning "Handy sync script not found at $sync_script"
        return 0
    fi

    if ! "$sync_script"; then
        warning "Failed to sync Handy settings"
    fi
}

setup_nvim_js_tools() {
    local install_script="$DOTFILES/scripts/install-nvim-js-tools.sh"

    title "Installing Neovim JS tools"

    if [[ ! -x "$install_script" ]]; then
        warning "Neovim JS tool installer not found at $install_script"
        return 0
    fi

    if ! "$install_script"; then
        warning "Failed to install Neovim JS tools"
    fi
}

# Claude: create ~/.claude as a real directory and symlink tracked config.
# The entire .claude directory is in DOTTY_LINK_IGNORE so dotty won't
# create a directory symlink (which would cause Claude runtime files like
# projects/, statsig/, todos/ to land in the repo working tree).
setup_claude() {
    local claude_dir="$HOME/.claude"
    local src_dir="$DOTFILES/home/.claude"

    mkdir -p "$claude_dir"

    # Symlink tracked config files
    create_symlink "$src_dir/CLAUDE.md" "$claude_dir/CLAUDE.md"

    # Symlink tracked config directories as individual files so later
    # repos can add their own entries alongside without dotty needing
    # to explode a directory symlink.
    for dir in hooks rules skills; do
        if [[ -d "$src_dir/$dir" ]]; then
            mkdir -p "$claude_dir/$dir"
            for file in "$src_dir/$dir"/*; do
                [[ -e "$file" ]] || continue
                create_symlink "$file" "$claude_dir/$dir/$(basename "$file")"
            done
        fi
    done

    # Copy settings (not symlink) so later repos can modify without
    # writing through into this repo's source tree.
    if [[ -f "$src_dir/settings.json" ]]; then
        cp "$src_dir/settings.json" "$claude_dir/settings.json"
    fi

    # Set personal preferences in ~/.claude.json (runtime state file).
    # Only poke specific keys; don't overwrite Claude's own state.
    local claude_json="$HOME/.claude.json"
    if command -v jq &>/dev/null && [[ -f "$claude_json" ]]; then
        jq '.hasCompletedOnboarding = true | .bypassPermissionsModeAccepted = true' \
            "$claude_json" > "$claude_json.tmp" && mv "$claude_json.tmp" "$claude_json"
    elif command -v jq &>/dev/null; then
        echo '{"hasCompletedOnboarding": true, "bypassPermissionsModeAccepted": true}' > "$claude_json"
    fi
}

# Codex: keep ~/.codex as a real directory so local runtime state remains
# local, then generate the managed instruction, config, and hook files from
# tracked source fragments.
setup_codex() {
    local codex_dir="$HOME/.codex"
    local script="$DOTFILES/scripts/sync-codex.ts"
    local agents_src="$DOTFILES/home/.codex/AGENTS.md"
    local custom_agents_src_dir="$DOTFILES/home/.codex/agents"
    local config_src="$DOTFILES/home/.codex/config.toml"
    local hooks_src="$DOTFILES/home/.codex/hooks.json"
    local skills_src_dir="$DOTFILES/home/.codex/skills"
    local themes_src_dir="$DOTFILES/home/.codex/themes"

    if ! command -v bun >/dev/null 2>&1; then
        warning "Bun not found. Skipping Codex config sync."
        return 0
    fi

    mkdir -p "$codex_dir"

    if [[ -f "$agents_src" ]]; then
        bun run "$script" agents \
            --validate-only \
            --source "$agents_src"
        bun run "$script" agents \
            --output "$codex_dir/AGENTS.md" \
            --source "$agents_src"
    fi

    if [[ -f "$config_src" ]]; then
        bun run "$script" config \
            --validate-only \
            --source "$config_src"
        bun run "$script" config \
            --output "$codex_dir/config.toml" \
            --source "$config_src"
    fi

    if [[ -f "$hooks_src" ]]; then
        bun run "$script" hooks \
            --validate-only \
            --source "$hooks_src"
        bun run "$script" hooks \
            --output "$codex_dir/hooks.json" \
            --source "$hooks_src"
    fi

    if [[ -d "$skills_src_dir" ]]; then
        bun run "$script" skills \
            --validate-only \
            --source "$skills_src_dir"
        bun run "$script" skills \
            --output "$codex_dir/skills" \
            --source "$skills_src_dir"
    fi

    if [[ -d "$custom_agents_src_dir" ]]; then
        local -a custom_agent_args=(
            --source "$custom_agents_src_dir"
        )

        if [[ -d "$skills_src_dir" ]]; then
            custom_agent_args+=(
                --skill-source "$skills_src_dir"
            )
        fi

        bun run "$script" custom-agents \
            --validate-only \
            "${custom_agent_args[@]}"
        bun run "$script" custom-agents \
            --output "$codex_dir/agents" \
            --skills-output "$codex_dir/skills" \
            "${custom_agent_args[@]}"
    fi

    if [[ -d "$themes_src_dir" ]]; then
        local codex_themes_dir="$codex_dir/themes"
        local theme_file

        mkdir -p "$codex_themes_dir"

        for theme_file in "$themes_src_dir"/*.tmTheme; do
            [[ -e "$theme_file" ]] || continue
            create_symlink "$theme_file" "$codex_themes_dir/$(basename "$theme_file")"
        done
    fi
}

setup_gsd_core() {
    local install_script="$DOTFILES/scripts/install-gsd-core.sh"

    [[ -x "$install_script" ]] || return 0
    "$install_script" --auto-reapply
}

main() {
    setup_vscode
    setup_shell
    setup_handy
    setup_nvim_js_tools
    setup_claude

    case "${DOTTY_COMMAND:-}" in
        install|update)
            if [[ "$DOTTY_COMMAND" == "install" ]]; then
                setup_guard
            fi

            setup_git_hooks
            sync_repo_submodules
            setup_tuicr

            if [[ "$(uname -s)" == "Darwin" ]]; then
                if [[ "$DOTTY_COMMAND" == "install" ]]; then
                    run_brew_sync
                    setup_macos
                fi
            fi
            ;;
    esac

    setup_codex
    setup_gsd_core
    setup_tmux_agent_bar
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
