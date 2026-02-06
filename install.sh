#!/usr/bin/env bash

# Originally adapted from Nick Nisi's dotfiles

DOTFILES="$(pwd)"

# Source shared utilities (includes logging and symlink/merge functions)
source "$DOTFILES/scripts/utils.sh"

# Create symlinks for all dotfiles in home/ directory
setup_symlinks() {
    title "Creating symlinks"

    # Handle .zshrc specially - if it exists as a regular file, append a source line
    if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
        info "Existing .zshrc found, appending source line for dotfiles config"
        if grep -q "source.*/dotfiles/zsh/.zshrc" "$HOME/.zshrc"; then
            # Migrate old path to new path
            sed -i '' 's|dotfiles/zsh/.zshrc|dotfiles/home/.zshrc|' "$HOME/.zshrc"
            success "Updated .zshrc source path to new location"
        elif ! grep -q "source.*dotfiles/home/.zshrc" "$HOME/.zshrc"; then
            echo "" >> "$HOME/.zshrc"
            echo "# Load personal dotfiles configuration" >> "$HOME/.zshrc"
            echo "source $DOTFILES/home/.zshrc" >> "$HOME/.zshrc"
            success "Appended source line to existing .zshrc"
        else
            info "~/.zshrc already sources dotfiles config... Skipping."
        fi
    fi

    # Symlink dotfiles: home/ → ~/, config/ → ~/.config/
    create_symlinks_from_dir "$DOTFILES/home" "$HOME"
    create_symlinks_from_dir "$DOTFILES/config" "$HOME/.config"
}

# Merge VS Code and Cursor settings template into existing config
setup_vscode_settings() {
    title "Setting up VS Code and Cursor settings"

    local vscode_user_dir="$HOME/Library/Application Support/Code/User"
    local cursor_user_dir="$HOME/Library/Application Support/Cursor/User"
    local template_settings="$DOTFILES/vscode-settings.json"

    # Ensure the User directories exist
    mkdir -p "$vscode_user_dir"
    mkdir -p "$cursor_user_dir"

    # Helper function to merge settings
    merge_settings() {
        local target_file="$1"
        local editor_name="$2"

        if [ -f "$target_file" ]; then
            info "Merging template settings into existing $editor_name configuration"
            # Use jq to merge JSON (preserves existing settings, updates template keys)
            if jq -s '.[0] * .[1]' "$target_file" "$template_settings" > "$target_file.tmp"; then
                mv "$target_file.tmp" "$target_file"
                success "$editor_name settings merged successfully"
            else
                rm -f "$target_file.tmp"
                error "Failed to merge $editor_name settings"
            fi
        else
            info "Creating new $editor_name settings from template"
            cp "$template_settings" "$target_file"
            success "$editor_name settings created from template"
        fi
    }

    # Merge settings for both editors
    merge_settings "$vscode_user_dir/settings.json" "VS Code"
    merge_settings "$cursor_user_dir/settings.json" "Cursor"
}

# Create symlinks for directory configurations
setup_directory() {
    local config_dir="$1"
    
    if [ -z "$config_dir" ]; then
        error "No directory specified. Usage: ./install.sh link-dir <directory>"
    fi
    
    title "Creating symlinks from $config_dir"
    
    create_symlinks_from_dir "$config_dir" "$HOME"
}

# Install and configure shell tools (fzf, bat)
setup_shell() {
    title "Setting up shell"

    # fzf setup
    if command -v brew >/dev/null && [[ -f "$(brew --prefix)/opt/fzf/install" ]]; then
        info "Setting up fzf"
        "$(brew --prefix)"/opt/fzf/install --key-bindings --completion --no-update-rc --no-bash --no-fish
    fi

    # symlink bat if it is installed as batcat
    if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
        info "Creating bat symlink from batcat"
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"

        # Set for current session only so that bat cache can be built
        export PATH="$HOME/.local/bin:$PATH"
    fi

    # build the bat cache so custom theme can be applied
    if command -v bat >/dev/null 2>&1 && [ -d "$(bat --config-dir)/themes" ]; then
        info "Setting up bat"
        bat cache --build
    fi

    # Initialize zsh to trigger plugin installation during setup
    # This prevents plugin installation output on first interactive shell
    if command -v zsh >/dev/null 2>&1 && [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/.zshrc" ]; then
        info "Initializing ZSH plugins..."
        # Run zsh with full .zshrc to trigger zfetch plugin installation
        # Output goes to setup logs, not first interactive SSH
        zsh -i -c 'exit 0' 2>&1 || true
        success "ZSH plugins initialized"
    fi
}

# Install applications and packages from Brewfile
setup_brew() {
    title "Installing Homebrew packages"

    # Install Homebrew if not already installed
    if ! command -v brew >/dev/null 2>&1; then
        # Only auto-install on macOS
        if [ "$(uname -s)" != "Darwin" ]; then
            info "Skipping Homebrew setup (brew not found and not on macOS)"
            return 0
        fi
        info "Homebrew not found. Installing Homebrew..."
        if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
            success "Homebrew installed successfully"
            
            # Add Homebrew to PATH for current session
            if [ -f "/opt/homebrew/bin/brew" ]; then
                export PATH="/opt/homebrew/bin:$PATH"
            elif [ -f "/usr/local/bin/brew" ]; then
                export PATH="/usr/local/bin:$PATH"
            fi
        else
            error "Failed to install Homebrew"
        fi
    else
        info "Homebrew already installed... Skipping installation."
    fi
    
    # Install packages from Brewfile
    info "Installing packages from Brewfile"
    if brew bundle; then
        success "Homebrew packages installed successfully"
    else
        warning "Some Homebrew packages failed to install. Continuing with remaining setup..."
    fi
}

# Configure macOS system preferences
setup_macos() {
    # Check if we're running on macOS
    if [ "$(uname -s)" != "Darwin" ]; then
        info "Skipping macOS configuration (not running on macOS)"
        return 0
    fi

    title "Configuring macOS system preferences"

    # Enable Touch ID for sudo commands (must run before other sudo commands)
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
            error "Failed to configure macOS settings"
        fi
    else
        error "macOS configuration script not found at $DOTFILES/scripts/macos.sh"
    fi

    # Generate Karabiner-Elements configuration if available
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

    # Install fonts
    if [ -f "$DOTFILES/scripts/install-fonts.sh" ]; then
        info "Installing fonts"
        "$DOTFILES/scripts/install-fonts.sh"
    fi
}

# Main function that handles command line arguments and orchestrates the setup
main() {
    case "${1:-}" in
        link)
            setup_symlinks
            setup_vscode_settings
            ;;
        link-dir)
            setup_directory "$2"
            ;;
        shell)
            setup_shell
            ;;
        brew)
            setup_brew
            ;;
        macos)
            setup_macos
            ;;
        all)
            setup_symlinks
            setup_vscode_settings
            setup_brew
            setup_shell
            setup_macos
            ;;
        *)
            echo -e "\nUsage: $(basename "$0") {link|link-dir|shell|brew|macos|all}\n"
            echo "  link       - Create symlinks for dotfiles (home/ → ~/)"
            echo "  link-dir   - Create symlinks for directory configs (usage: link-dir <directory>)"
            echo "  shell      - Set up shell tools (fzf, bat)"
            echo "  brew       - Install applications and packages from Brewfile"
            echo "  macos      - Configure macOS system preferences (includes fonts)"
            echo "  all        - Run all setup steps (link, shell, brew, macos)"
            echo
            exit 1
            ;;
    esac

    success "Done."
}

main "$@"
