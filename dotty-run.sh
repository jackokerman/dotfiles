#!/usr/bin/env bash
#
# dotty hook for personal dotfiles.
# Runs after symlinks are created. DOTTY_REPO_DIR, DOTTY_ENV, and
# DOTTY_COMMAND (install/update) are exported by dotty.

DOTFILES="$DOTTY_REPO_DIR"
source "$DOTTY_LIB"

# --- Guard

setup_guard() {
    title "Setting up commit guard"

    if command -v dotty >/dev/null 2>&1; then
        dotty guard "$DOTFILES"
    fi
}

# --- VS Code / Cursor

setup_vscode() {
    title "Setting up VS Code and Cursor"

    local vscode_user_dir="$HOME/Library/Application Support/Code/User"
    local cursor_user_dir="$HOME/Library/Application Support/Cursor/User"
    local template_settings="$DOTFILES/vscode-settings.json"

    mkdir -p "$vscode_user_dir"
    mkdir -p "$cursor_user_dir"

    merge_json "$template_settings" "$vscode_user_dir/settings.json"
    merge_json "$template_settings" "$cursor_user_dir/settings.json"

    info "Setting up Nightfly VS Code theme"

    local theme_repo="https://github.com/jackokerman/nightfly-vscode.git"
    local theme_dir="$HOME/nightfly-vscode"
    local vscode_ext_dir="$HOME/.vscode/extensions/nightfly-vscode"
    local cursor_ext_dir="$HOME/.cursor/extensions/nightfly-vscode"

    if [ -d "$theme_dir" ]; then
        info "nightfly-vscode already cloned... Pulling latest."
        git -C "$theme_dir" pull --ff-only 2>/dev/null || warning "Could not pull latest (offline or auth issue)"
    else
        info "Cloning nightfly-vscode theme"
        if git clone "$theme_repo" "$theme_dir"; then
            success "Theme cloned to $theme_dir"
        else
            warning "Could not clone nightfly-vscode (offline or auth issue). Skipping theme setup."
            return 0
        fi
    fi

    mkdir -p "$(dirname "$vscode_ext_dir")"
    create_symlink "$theme_dir" "$vscode_ext_dir"

    mkdir -p "$(dirname "$cursor_ext_dir")"
    create_symlink "$theme_dir" "$cursor_ext_dir"
}

# --- Shell tools

setup_shell() {
    title "Setting up shell"

    # bat (symlink from batcat on Linux)
    if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
        info "Creating bat symlink from batcat"
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
        export PATH="$HOME/.local/bin:$PATH"
    fi

    # bat cache (for custom theme)
    if command -v bat >/dev/null 2>&1 && [ -d "$(bat --config-dir)/themes" ]; then
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

# --- Homebrew

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

# --- macOS

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
        if command -v deno >/dev/null 2>&1; then
            info "Generating Karabiner-Elements configuration"
            if deno run --allow-env --allow-read --allow-write "$DOTFILES/scripts/karabiner-config.ts"; then
                success "Karabiner-Elements configuration generated"
            else
                warning "Failed to generate Karabiner-Elements configuration"
            fi
        else
            warning "Deno not found. Skipping Karabiner-Elements configuration generation."
            info "Install Deno with: brew install deno"
        fi
    fi

    if [ -f "$DOTFILES/scripts/install-fonts.sh" ]; then
        info "Installing fonts"
        "$DOTFILES/scripts/install-fonts.sh"
    fi
}

# --- Run

setup_vscode
setup_shell

case "$DOTTY_COMMAND" in
    install)
        setup_guard
        if [[ "$(uname -s)" == "Darwin" ]]; then
            setup_brew
            setup_macos
        fi
        ;;
esac
