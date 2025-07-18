#!/usr/bin/env bash

# Originally adapted from Nick Nisi's dotfiles

DOTFILES="$(pwd)"

# Colors for logging output
COLOR_BLUE="\033[34m"
COLOR_GREEN="\033[32m"
COLOR_RED="\033[31m"
COLOR_PURPLE="\033[35m"
COLOR_YELLOW="\033[33m"
COLOR_NONE="\033[0m"

# Logging functions
title() {
    echo -e "\n${COLOR_PURPLE}$1${COLOR_NONE}\n"
}

error() {
    echo -e "${COLOR_RED}Error: ${COLOR_NONE}$1" >&2
    exit 1
}

warning() {
    echo -e "${COLOR_YELLOW}Warning: ${COLOR_NONE}$1" >&2
}

info() {
    echo -e "${COLOR_BLUE}Info: ${COLOR_NONE}$1"
}

success() {
    echo -e "${COLOR_GREEN}$1${COLOR_NONE}"
}

# Create symlinks for zsh config files and config directories
setup_symlinks() {
    title "Creating symlinks"

    # Symlink all files in the /zsh directory, e.g. zsh/.zshrc -> ~/.zshrc
    zsh_files=$(find "$DOTFILES/zsh" -mindepth 1 -maxdepth 1 -type f 2>/dev/null)
    for file in $zsh_files; do
        target="$HOME/$(basename "$file")"
        if [ -e "$target" ]; then
            if [ -L "$target" ]; then
                info "~${target#$HOME} already exists as symlink... Skipping."
            else
                warning "~${target#$HOME} already exists (not a symlink)... Skipping."
            fi
        else
            info "Creating symlink for $file"
            if ln -s "$file" "$target"; then
                success "Created symlink: ~${target#$HOME}"
            else
                error "Failed to create symlink for $file"
            fi
        fi
    done

    echo -e
    info "installing to ~/.config"
    if [ ! -d "$HOME/.config" ]; then
        info "Creating ~/.config"
        mkdir -p "$HOME/.config"
    fi

    config_files=$(find "$DOTFILES/config" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
    for config in $config_files; do
        target="$HOME/.config/$(basename "$config")"
        if [ -e "$target" ]; then
            if [ -L "$target" ]; then
                info "~${target#$HOME} already exists as symlink... Skipping."
            else
                warning "~${target#$HOME} already exists (not a symlink)... Skipping."
            fi
        else
            info "Creating symlink for $config"
            if ln -s "$config" "$target"; then
                success "Created symlink: ~${target#$HOME}"
            else
                error "Failed to create symlink for $config"
            fi
        fi
    done
}

# Create symlinks for local configurations
setup_local() {
    local config_dir="$1"
    
    if [ -z "$config_dir" ]; then
        error "No directory specified. Usage: ./install.sh link-local <directory>"
    fi
    
    if [ ! -d "$config_dir" ]; then
        error "Directory does not exist: $config_dir"
    fi
    
    title "Creating local symlinks from $config_dir"
    
    # Define allowed files that can be linked as local configs
    local allowed_files=(".zshrc" ".gitconfig")
    
    for file in "${allowed_files[@]}"; do
        local source_file="$config_dir/$file"
        local target_file="$HOME/${file#.}-local"
        
        if [ -f "$source_file" ]; then
            if [ -e "$target_file" ]; then
                if [ -L "$target_file" ]; then
                    info "~${target_file#$HOME} already exists as symlink... Skipping."
                else
                    warning "~${target_file#$HOME} already exists (not a symlink)... Skipping."
                fi
            else
                info "Creating symlink for $source_file"
                if ln -s "$source_file" "$target_file"; then
                    success "Created symlink: ~${target_file#$HOME}"
                else
                    error "Failed to create symlink for $source_file"
                fi
            fi
        else
            info "File $file not found in $config_dir... Skipping."
        fi
    done
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
    
    # Check if we're running on macOS
    if [ "$(uname -s)" != "Darwin" ]; then
        error "Homebrew setup can only be run on macOS"
    fi
    
    # Install Homebrew if not already installed
    if ! command -v brew >/dev/null 2>&1; then
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
        error "Failed to install Homebrew packages"
    fi
}

# Configure macOS system preferences
setup_macos() {
    title "Configuring macOS system preferences"
    
    # Check if we're running on macOS
    if [ "$(uname -s)" != "Darwin" ]; then
        error "macOS configuration can only be run on macOS"
    fi
    
    if [ -f "$DOTFILES/macos" ]; then
        info "Running macOS configuration script"
        if "$DOTFILES/macos"; then
            success "macOS configuration completed"
        else
            error "Failed to configure macOS settings"
        fi
    else
        error "macOS configuration script not found at $DOTFILES/macos"
    fi
}

# Main function that handles command line arguments and orchestrates the setup
main() {
    case "${1:-}" in
        link)
            setup_symlinks
            ;;
        link-local)
            setup_local "$2"
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
            setup_brew
            setup_shell
            setup_macos
            ;;
        *)
            echo -e "\nUsage: $(basename "$0") {link|link-local|shell|brew|macos|all}\n"
            echo "  link       - Create symlinks for zsh and config files"
            echo "  link-local - Create symlinks for local context configs (usage: link-local <directory>)"
            echo "  shell      - Set up shell tools (Zap, fzf, bat)"
            echo "  brew       - Install applications and packages from Brewfile"
            echo "  macos      - Configure macOS system preferences"
            echo "  all        - Run all setup steps (link, shell, brew, macos)"
            echo
            exit 1
            ;;
    esac

    echo -e
    success "Done."
}

main "$@"
