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

replace_file_if_changed() {
    local tmp_path="$1"
    local target_path="$2"

    if [[ -f "$target_path" && ! -L "$target_path" ]] && cmp -s "$tmp_path" "$target_path"; then
        rm -f "$tmp_path"
    else
        mv "$tmp_path" "$target_path"
    fi
}

later_repo_has_claude_settings() {
    local registry_path="$HOME/.dotty/registry"
    local name="" repo_path="" seen_current=false

    [[ -f "$registry_path" ]] || return 1

    while IFS='=' read -r name repo_path; do
        [[ -n "$name" && -d "$repo_path" ]] || continue

        if [[ "$repo_path" == "$DOTFILES" ]]; then
            seen_current=true
            continue
        fi

        if [[ "$seen_current" == "true" && -f "$repo_path/home/.claude/settings.json" ]]; then
            return 0
        fi
    done < "$registry_path"

    return 1
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
        local tmp_target="$target.tmp"
        if ! command -v jq &>/dev/null; then
            warning "jq not found, copying settings instead of merging"
            cp "$template_settings" "$tmp_target"
            replace_file_if_changed "$tmp_target" "$target"
        elif [[ -f "$target" ]]; then
            if jq -s '.[0] * .[1]' "$target" "$template_settings" > "$tmp_target"; then
                replace_file_if_changed "$tmp_target" "$target"
            else
                rm -f "$tmp_target"
                warning "Failed to merge settings for $target"
            fi
        else
            cp "$template_settings" "$tmp_target"
            replace_file_if_changed "$tmp_target" "$target"
        fi
    done

}

# Shell tools

bat_cache_needs_build() {
    local bat_bin="$1"
    local config_dir=""
    config_dir="$("$bat_bin" --config-dir 2>/dev/null)" || return 1

    [[ -d "$config_dir/themes" ]] || return 1

    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/bat"
    local metadata_path="$cache_dir/metadata.yaml"
    if [[ ! -s "$cache_dir/themes.bin" || ! -s "$cache_dir/syntaxes.bin" || ! -s "$metadata_path" ]]; then
        return 0
    fi

    local bat_version=""
    local cached_version=""
    bat_version="$("$bat_bin" --version 2>/dev/null | awk '{print $2; exit}')"
    cached_version="$(awk '/^bat_version:/ {print $2; exit}' "$metadata_path" 2>/dev/null || true)"
    if [[ -z "$bat_version" || "$cached_version" != "$bat_version" ]]; then
        return 0
    fi

    local source_dir=""
    local source_file=""
    for source_dir in "$config_dir/themes" "$config_dir/syntaxes"; do
        [[ -d "$source_dir" ]] || continue
        if [[ "$source_dir" -nt "$metadata_path" ]]; then
            return 0
        fi
        while IFS= read -r -d '' source_file; do
            if [[ "$source_file" -nt "$metadata_path" ]]; then
                return 0
            fi
        done < <(find "$source_dir" -type f -print0 2>/dev/null)
    done

    return 1
}

setup_shell() {
    title "Setting up shell"

    # bat cache (for custom themes used by delta)
    if command -v bat >/dev/null 2>&1 \
        && bat_cache_needs_build "$(command -v bat)"; then
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

setup_fzf() {
    local install_script="$DOTFILES/scripts/install-fzf.sh"

    if [[ "$(uname -s)" == "Darwin" ]]; then
        return 0
    fi

    title "Installing fzf"

    if [[ ! -x "$install_script" ]]; then
        warning "fzf installer not found at $install_script"
        return 0
    fi

    if ! "$install_script"; then
        warning "Failed to install fzf"
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

setup_sesh() {
    local target_dir="$HOME/.config/sesh"
    local target="$target_dir/sesh.toml"
    local registry_path="$HOME/.dotty/registry"
    local current_source="$DOTFILES/home/.config/sesh/sesh.toml"
    local name="" repo_path="" candidate="" source="" tmp_target=""
    local -a sources=()

    [[ -f "$current_source" ]] || return 0

    if [[ -f "$registry_path" ]]; then
        while IFS='=' read -r name repo_path; do
            [[ -n "$name" && -d "$repo_path" ]] || continue
            candidate="$repo_path/home/.config/sesh/sesh.toml"
            [[ -f "$candidate" ]] || continue
            sources+=("$candidate")
        done < "$registry_path"
    fi

    if [[ ${#sources[@]} -eq 0 ]]; then
        sources+=("$current_source")
    fi

    # Keep ~/.config/sesh as a real directory so the generated sesh.toml
    # does not write back into tracked source fragments through a symlink.
    if [[ -L "$target_dir" ]]; then
        rm -f "$target_dir"
    fi

    mkdir -p "$target_dir"
    tmp_target="$(mktemp "$target.XXXXXX")"

    {
        printf '%s\n' '# Generated by dotty from tracked sesh config fragments.'
        printf '%s\n' '# Edit a tracked home/.config/sesh/sesh.toml source, then run `dotty update`.'
        printf '\n'

        for source in "${sources[@]}"; do
            cat "$source"
            printf '\n'
        done
    } > "$tmp_target"

    replace_file_if_changed "$tmp_target" "$target"
}

setup_glow() {
    local target_dir="$HOME/.config/glow"
    local config_target="$target_dir/glow.yml"
    local style_source="$DOTFILES/home/.config/glow/nightfly.json"
    local style_target="$target_dir/nightfly.json"
    local tmp_target=""

    [[ -f "$style_source" ]] || return 0

    # This is path materialization, not config composition. Glow does not
    # reliably resolve custom JSON style paths relative to glow.yml, so the
    # live config needs an absolute path without tracking a user-specific
    # /Users/... path in the repo.
    if [[ -L "$target_dir" ]]; then
        rm -f "$target_dir"
    fi

    mkdir -p "$target_dir"
    create_symlink "$style_source" "$style_target"
    tmp_target="$(mktemp "$config_target.XXXXXX")"

    {
        printf '%s\n' '# Generated by dotty from tracked glow config.'
        printf '%s\n' '# Edit home/.config/glow/nightfly.json or .dotty/run.sh, then run `dotty update`.'
        printf '%s\n' 'style: "'"$style_target"'"'
        printf '%s\n' 'pager: true'
        printf '%s\n' 'all: false'
    } > "$tmp_target"

    replace_file_if_changed "$tmp_target" "$config_target"
}

setup_television() {
    local target_dir="$HOME/.config/television"
    local config_source="$DOTFILES/home/.config/television/config.toml"
    local config_target="$target_dir/config.toml"
    local theme_source="$DOTFILES/home/.config/television/themes/nightfly.toml"
    local theme_target="$target_dir/themes/nightfly.toml"

    [[ -f "$config_source" ]] || return 0

    # Keep ~/.config/television as a real directory because tv stores mutable
    # channel files under cable/.
    if [[ -L "$target_dir" ]]; then
        rm -f "$target_dir"
    fi

    mkdir -p "$target_dir/cable" "$target_dir/themes"
    if [[ -e "$config_target" && ! -L "$config_target" ]]; then
        rm -f "$config_target"
    fi
    create_symlink "$config_source" "$config_target"

    if [[ -f "$theme_source" ]]; then
        if [[ -e "$theme_target" && ! -L "$theme_target" ]]; then
            rm -f "$theme_target"
        fi
        create_symlink "$theme_source" "$theme_target"
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

    # Symlink tracked config files when present. CLAUDE.md is normally generated
    # later by the portable Ruler path.
    if [[ -f "$src_dir/CLAUDE.md" ]]; then
        create_symlink "$src_dir/CLAUDE.md" "$claude_dir/CLAUDE.md"
    fi

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
    if [[ -f "$src_dir/settings.json" ]] && ! later_repo_has_claude_settings; then
        cp "$src_dir/settings.json" "$claude_dir/settings.json.tmp"
        replace_file_if_changed "$claude_dir/settings.json.tmp" "$claude_dir/settings.json"
    fi

    # Set personal preferences in ~/.claude.json (runtime state file).
    # Only poke specific keys; don't overwrite Claude's own state.
    local claude_json="$HOME/.claude.json"
    if command -v jq &>/dev/null && [[ -f "$claude_json" ]]; then
        jq '.hasCompletedOnboarding = true | .bypassPermissionsModeAccepted = true' \
            "$claude_json" > "$claude_json.tmp" && replace_file_if_changed "$claude_json.tmp" "$claude_json"
    elif command -v jq &>/dev/null; then
        echo '{"hasCompletedOnboarding": true, "bypassPermissionsModeAccepted": true}' > "$claude_json.tmp"
        replace_file_if_changed "$claude_json.tmp" "$claude_json"
    fi
}

# Codex: keep ~/.codex as a real directory so local runtime state remains
# local, then generate the managed instruction, config, and hook files from
# tracked source fragments.
run_dotfiles_bun_script() {
    bun --install=fallback run "$@"
}

setup_codex() {
    local codex_dir="$HOME/.codex"
    local script="$DOTFILES/scripts/ts/sync-codex.ts"
    local ruler_script="$DOTFILES/scripts/ts/sync-ruler.ts"
    local agents_src="$DOTFILES/home/.codex/AGENTS.md"
    local ruler_agents_src="$DOTFILES/home/.ruler/AGENTS.md"
    local portable_skills_src_dir="$DOTFILES/home/.ruler/skills"
    local custom_agents_src_dir="$DOTFILES/home/.codex/agents"
    local config_src="$DOTFILES/home/.codex/config.toml"
    local hooks_src="$DOTFILES/home/.codex/hooks.json"
    local skills_src_dir="$DOTFILES/home/.codex/skills"
    local themes_src_dir="$DOTFILES/home/.codex/themes"
    local -a portable_skill_source_args=()
    local -a generated_skill_source_args=()

    if ! command -v bun >/dev/null 2>&1; then
        warning "Bun not found. Skipping Codex config sync."
        return 0
    fi

    mkdir -p "$codex_dir"

    if [[ -d "$portable_skills_src_dir" ]]; then
        portable_skill_source_args+=(--skill-source "$portable_skills_src_dir")
        generated_skill_source_args+=(--source "$portable_skills_src_dir")
    fi

    local use_portable_ruler=false
    if [[ "${DOTTY_CODEX_RULER:-1}" != "0" && -f "$ruler_agents_src" && -d "$portable_skills_src_dir" && -f "$ruler_script" ]]; then
        use_portable_ruler=true
    fi

    if [[ "$use_portable_ruler" != "true" && "${DOTTY_CODEX_RULER:-1}" != "0" && -f "$ruler_agents_src" && -f "$ruler_script" ]]; then
        run_dotfiles_bun_script "$ruler_script" codex-agents \
            --validate-only \
            --source "$ruler_agents_src" \
            || die "Failed to validate Ruler-backed Codex instructions"
        run_dotfiles_bun_script "$ruler_script" codex-agents \
            --output "$codex_dir/AGENTS.md" \
            --source "$ruler_agents_src" \
            || die "Failed to generate Ruler-backed Codex instructions"
    elif [[ -f "$agents_src" ]]; then
        run_dotfiles_bun_script "$script" agents \
            --validate-only \
            --source "$agents_src"
        run_dotfiles_bun_script "$script" agents \
            --output "$codex_dir/AGENTS.md" \
            --source "$agents_src"
    fi

    if [[ -f "$config_src" ]]; then
        run_dotfiles_bun_script "$script" config \
            --validate-only \
            --source "$config_src"
        run_dotfiles_bun_script "$script" config \
            --output "$codex_dir/config.toml" \
            --source "$config_src"
    fi

    if [[ -f "$hooks_src" ]]; then
        run_dotfiles_bun_script "$script" hooks \
            --validate-only \
            --source "$hooks_src"
        run_dotfiles_bun_script "$script" hooks \
            --output "$codex_dir/hooks.json" \
            --source "$hooks_src"
    fi

    if [[ -d "$skills_src_dir" ]]; then
        run_dotfiles_bun_script "$script" skills \
            --validate-only \
            --source "$skills_src_dir"
        run_dotfiles_bun_script "$script" skills \
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
        custom_agent_args+=("${portable_skill_source_args[@]}")

        run_dotfiles_bun_script "$script" custom-agents \
            --validate-only \
            "${custom_agent_args[@]}"
        run_dotfiles_bun_script "$script" custom-agents \
            --output "$codex_dir/agents" \
            --skills-output "$codex_dir/skills" \
            "${custom_agent_args[@]}"
    fi

    if [[ "$use_portable_ruler" == "true" ]]; then
        local claude_dir="$HOME/.claude"
        mkdir -p "$claude_dir"
        run_dotfiles_bun_script "$ruler_script" portable \
            --validate-only \
            --source "$ruler_agents_src" \
            "${portable_skill_source_args[@]}" \
            || die "Failed to validate portable Ruler outputs"
        run_dotfiles_bun_script "$ruler_script" portable \
            --codex-agents-output "$codex_dir/AGENTS.md" \
            --claude-output "$claude_dir/CLAUDE.md" \
            --codex-skills-output "$codex_dir/skills" \
            --claude-skills-output "$claude_dir/skills" \
            --source "$ruler_agents_src" \
            "${portable_skill_source_args[@]}" \
            || die "Failed to generate portable Ruler outputs"

        if [[ -d "$skills_src_dir" ]]; then
            run_dotfiles_bun_script "$script" skills \
                --validate-only \
                "${generated_skill_source_args[@]}" \
                --source "$skills_src_dir"
            run_dotfiles_bun_script "$script" skills \
                --output "$codex_dir/skills" \
                "${generated_skill_source_args[@]}" \
                --source "$skills_src_dir"
        fi
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

setup_jackie_plan() {
    local install_script="$DOTFILES/.dotty/commands/install-jackie-plan"

    [[ -x "$install_script" ]] || return 0
    "$install_script"
}

setup_godspeed_js() {
    local repo_dir="${GODSPEED_JS_REPO_DIR:-$HOME/src/godspeed-js}"

    if [[ ! -d "$repo_dir" ]]; then
        warning "Skipping GodspeedJS install because $repo_dir is missing"
        return 0
    fi

    if ! command -v bun >/dev/null 2>&1; then
        warning "Skipping GodspeedJS install because Bun is not available"
        return 0
    fi

    if [[ ! -f "$repo_dir/package.json" ]]; then
        warning "Skipping GodspeedJS install because $repo_dir/package.json is missing"
        return 0
    fi

    info "Installing GodspeedJS CLIs"
    bun install --cwd "$repo_dir" --frozen-lockfile --silent \
        || die "Failed to install GodspeedJS dependencies"
    bun run --cwd "$repo_dir" install:local \
        || die "Failed to link GodspeedJS CLIs"
}

setup_dev_checkouts() {
    local sync_script="$DOTFILES/scripts/sync-dev-checkouts.sh"

    [[ -x "$sync_script" ]] || return 0
    "$sync_script"
}

main() {
    setup_vscode
    setup_fzf
    setup_shell
    setup_handy
    setup_nvim_js_tools
    setup_sesh
    setup_glow
    setup_television
    setup_claude

    case "${DOTTY_COMMAND:-}" in
        install|update)
            if [[ "$DOTTY_COMMAND" == "install" ]]; then
                setup_guard
            fi

            setup_git_hooks
            sync_repo_submodules

            if [[ "$(uname -s)" == "Darwin" ]]; then
                if [[ "$DOTTY_COMMAND" == "install" ]]; then
                    run_brew_sync
                    setup_macos
                fi
            fi
            ;;
    esac

    setup_dev_checkouts
    setup_jackie_plan
    setup_godspeed_js
    setup_codex
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
