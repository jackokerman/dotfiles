#!/usr/bin/env bash

# Originally adapted from Nick Nisi's dotfiles

DOTFILES="$(pwd)"

# Source shared logging utilities
source "$DOTFILES/scripts/logging.sh"

# Helper function to create symlink with proper error handling
create_symlink() {
    local source="$1"
    local target="$2"
    
    if [ -e "$target" ]; then
        if [ -L "$target" ]; then
            info "~${target#$HOME} already exists as symlink... Skipping."
        else
            warning "~${target#$HOME} already exists (not a symlink)... Skipping."
        fi
        return 0
    fi
    
    local description="$(basename "$source")"
    info "Creating symlink for $description"
    if ln -s "$source" "$target"; then
        success "Created symlink: ~${target#$HOME}"
        return 0
    else
        error "Failed to create symlink for $description"
    fi
}

# Generic function to create symlinks from a source directory
create_symlinks_from_dir() {
    local source_dir="$1"
    local target_dir="$2"
    
    if [ ! -d "$source_dir" ]; then
        error "Source directory does not exist: $source_dir"
    fi
    
    # Define patterns to exclude (version control files and install scripts)
    local exclude_patterns="-name .git -o -name .gitignore -o -name .gitmodules -o -name README.md -o -name install.sh"
    
    # Create target directory if it doesn't exist
    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir"
    fi
    
    # Link all files and directories, excluding version control files
    local items=$(find "$source_dir" -mindepth 1 -maxdepth 1 \( $exclude_patterns \) -prune -o -print 2>/dev/null)
    for item in $items; do
        local basename_item=$(basename "$item")
        local target_item="$target_dir/$basename_item"
        
        if [ -d "$item" ]; then
            # If it's a directory, recursively process it
            if [ -L "$target_item" ]; then
                # Target is already a symlink - resolve and merge if it's a directory
                local resolved_target=$(readlink -f "$target_item" 2>/dev/null || readlink "$target_item")
                if [ -d "$resolved_target" ]; then
                    # It's a symlinked directory, merge contents into it
                    create_symlinks_from_dir "$item" "$resolved_target"
                else
                    info "~${target_item#$HOME} already exists as symlink... Skipping."
                fi
            elif [ -d "$target_item" ]; then
                # Target directory exists as regular directory, merge contents
                create_symlinks_from_dir "$item" "$target_item"
            else
                # Target doesn't exist, create symlink
                create_symlink "$item" "$target_item"
            fi
        else
            # It's a file, create symlink
            create_symlink "$item" "$target_item"
        fi
    done
}

# Create symlinks for zsh config files and config directories
setup_symlinks() {
    title "Creating symlinks"

    # Handle .zshrc specially - if it exists, append a source line instead of symlinking
    if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
        info "Existing .zshrc found, appending source line for dotfiles config"
        if ! grep -q "source.*dotfiles/zsh/.zshrc" "$HOME/.zshrc"; then
            echo "" >> "$HOME/.zshrc"
            echo "# Load personal dotfiles configuration" >> "$HOME/.zshrc"
            echo "source $DOTFILES/zsh/.zshrc" >> "$HOME/.zshrc"
            success "Appended source line to existing .zshrc"
        else
            info "~/.zshrc already sources dotfiles config... Skipping."
        fi
    else
        # Normal symlink for .zshrc if it doesn't exist
        create_symlink "$DOTFILES/zsh/.zshrc" "$HOME/.zshrc"
    fi

    # Symlink other zsh files (.zshenv, .p10k.zsh, .aliases)
    for file in "$DOTFILES/zsh"/.zshenv "$DOTFILES/zsh"/.p10k.zsh "$DOTFILES/zsh"/.aliases; do
        if [ -f "$file" ]; then
            local basename_file=$(basename "$file")
            create_symlink "$file" "$HOME/$basename_file"
        fi
    done

    # Symlink aerospace arrangement config
    if [ -f "$DOTFILES/.aerospace-arrangement" ]; then
        create_symlink "$DOTFILES/.aerospace-arrangement" "$HOME/.aerospace-arrangement"
    fi

    echo -e
    info "installing to ~/.config"
    if [ ! -d "$HOME/.config" ]; then
        info "Creating ~/.config"
        mkdir -p "$HOME/.config"
    fi

    # Symlink all directories in the /config directory
    create_symlinks_from_dir "$DOTFILES/config" "$HOME/.config"
}

# Merge VS Code and Cursor settings template into existing config
setup_vscode_settings() {
    title "Setting up VS Code and Cursor settings"

    local vscode_user_dir="$HOME/Library/Application Support/Code/User"
    local cursor_user_dir="$HOME/Library/Application Support/Cursor/User"
    local template_settings="$DOTFILES/config/vscode/settings.json"

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

    echo -e
    success "VS Code and Cursor settings configured"
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

# Install and configure shell tools (Zap, fzf, bat)
setup_shell() {
    title "Setting up shell"

    # Install Zap zsh plugin manager if not already installed
    if [ ! -d "$HOME/.local/share/zap" ]; then
        info "Installing Zap"
        zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh) --keep --branch release-v1
    else
        info "Zap already installed... Skipping."
    fi

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
            echo "  link       - Create symlinks for zsh and config files"
            echo "  link-dir   - Create symlinks for directory configs (usage: link-dir <directory>)"
            echo "  shell      - Set up shell tools (Zap, fzf, bat)"
            echo "  brew       - Install applications and packages from Brewfile"
            echo "  macos      - Configure macOS system preferences (includes fonts)"
            echo "  all        - Run all setup steps (link, shell, brew, macos)"
            echo
            exit 1
            ;;
    esac

    echo -e
    success "Done."
}

main "$@"
