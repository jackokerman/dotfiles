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

    # bat cache (for custom theme) — only on install since themes rarely change
    if command -v bat >/dev/null 2>&1 \
        && [ -d "$(bat --config-dir)/themes" ] \
        && [ "$DOTTY_COMMAND" = "install" ]; then
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

setup_brew() {
    title "Installing Homebrew packages"

    if ! command -v brew >/dev/null 2>&1; then
        if [ "$(uname -s)" != "Darwin" ]; then
            info "Skipping Homebrew setup (brew not found and not on macOS)"
            return 0
        fi
        info "Homebrew not found. Installing Homebrew..."
        if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
            success "Homebrew installed successfully"
            if [ -f "/opt/homebrew/bin/brew" ]; then
                export PATH="/opt/homebrew/bin:$PATH"
            elif [ -f "/usr/local/bin/brew" ]; then
                export PATH="/usr/local/bin:$PATH"
            fi
        else
            die "Failed to install Homebrew"
        fi
    else
        info "Homebrew already installed... Skipping installation."
    fi

    info "Installing packages from Brewfile"
    if brew bundle; then
        success "Homebrew packages installed successfully"
    else
        warning "Some Homebrew packages failed to install. Continuing with remaining setup..."
    fi
}

# macOS

setup_macos() {
    if [ "$(uname -s)" != "Darwin" ]; then
        info "Skipping macOS configuration (not running on macOS)"
        return 0
    fi

    title "Configuring macOS system preferences"

    if [ -f "$DOTFILES/scripts/enable-touchid-sudo.sh" ]; then
        if "$DOTFILES/scripts/enable-touchid-sudo.sh"; then
            success "Touch ID setup completed"
        else
            warning "Touch ID setup was skipped or failed"
        fi
    fi

    if [ -f "$DOTFILES/scripts/macos.sh" ]; then
        info "Running macOS configuration script"
        if "$DOTFILES/scripts/macos.sh"; then
            success "macOS configuration completed"
        else
            die "Failed to configure macOS settings"
        fi
    else
        die "macOS configuration script not found at $DOTFILES/scripts/macos.sh"
    fi

    if [ -f "$DOTFILES/scripts/karabiner-config.ts" ]; then
        if command -v bun >/dev/null 2>&1; then
            info "Generating Karabiner-Elements configuration"
            if bun run "$DOTFILES/scripts/karabiner-config.ts"; then
                success "Karabiner-Elements configuration generated"
            else
                warning "Failed to generate Karabiner-Elements configuration"
            fi
        else
            warning "Bun not found. Skipping Karabiner-Elements configuration generation."
            info "Install Bun with: brew install oven-sh/bun/bun"
        fi
    fi

    if [ -f "$DOTFILES/scripts/install-fonts.sh" ]; then
        info "Installing fonts"
        "$DOTFILES/scripts/install-fonts.sh"
    fi
}

# Run

setup_vscode
setup_shell

# Claude: create ~/.claude as a real directory and symlink tracked config.
# The entire .claude directory is in DOTTY_LINK_IGNORE so dotty won't
# create a directory symlink (which would cause Claude runtime files like
# projects/, statsig/, todos/ to land in the repo working tree).
setup_claude() {
    local claude_dir="$HOME/.claude"
    local src_dir="$DOTFILES/home/.claude"

    # If ~/.claude is a directory symlink from a previous dotty run, replace
    # it with a real directory so runtime files stay out of the repo.
    if [[ -L "$claude_dir" ]]; then
        rm "$claude_dir"
    fi
    mkdir -p "$claude_dir"

    # Symlink tracked config files
    for item in CLAUDE.md; do
        if [[ -e "$src_dir/$item" ]]; then
            ln -sfn "$src_dir/$item" "$claude_dir/$item"
        fi
    done

    # Symlink tracked config directories as individual files so overlay
    # repos can add their own entries alongside without dotty needing
    # to explode a directory symlink.
    for dir in hooks rules skills; do
        if [[ -d "$src_dir/$dir" ]]; then
            mkdir -p "$claude_dir/$dir"
            for file in "$src_dir/$dir"/*; do
                [[ -e "$file" ]] || continue
                ln -sfn "$file" "$claude_dir/$dir/$(basename "$file")"
            done
        fi
    done

    # Copy settings (not symlink) so overlays can modify without
    # writing through into this repo's source tree.
    if [[ -f "$src_dir/settings.json" ]]; then
        cp "$src_dir/settings.json" "$claude_dir/settings.json"
    fi
}

setup_claude

case "$DOTTY_COMMAND" in
    install)
        setup_guard
        if [[ "$(uname -s)" == "Darwin" ]]; then
            setup_brew
            setup_macos
        fi
        ;;
esac
