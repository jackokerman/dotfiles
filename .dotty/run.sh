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

setup_shell() {
    title "Setting up shell"

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

# Run

setup_vscode
setup_shell

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

setup_handy

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

setup_claude

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

case "$DOTTY_COMMAND" in
    install|update)
        if [[ "$DOTTY_COMMAND" == "install" ]]; then
            setup_guard
        fi

        setup_git_hooks

        if [[ "$(uname -s)" == "Darwin" ]]; then
            if [[ "$DOTTY_COMMAND" == "install" ]]; then
                run_brew_sync
                setup_macos
            fi
        fi
        ;;
esac

setup_codex
