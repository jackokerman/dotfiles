#!/usr/bin/env bash

# Adapted from curl https://github.com/nicknisi/dotfiles/raw/main/install.sh

DOTFILES="$(pwd)"
COLOR_GRAY="\033[1;38;5;243m"
COLOR_BLUE="\033[1;34m"
COLOR_GREEN="\033[1;32m"
COLOR_RED="\033[1;31m"
COLOR_PURPLE="\033[1;35m"
COLOR_YELLOW="\033[1;33m"
COLOR_NONE="\033[0m"

title() {
    echo -e "\n${COLOR_PURPLE}$1${COLOR_NONE}\n"
}

error() {
    echo -e "${COLOR_RED}Error: ${COLOR_NONE}$1"
    exit 1
}

warning() {
    echo -e "${COLOR_YELLOW}Warning: ${COLOR_NONE}$1"
}

info() {
    echo -e "${COLOR_BLUE}Info: ${COLOR_NONE}$1"
}

success() {
    echo -e "${COLOR_GREEN}$1${COLOR_NONE}"
}

setup_symlinks() {
    title "Creating symlinks"

    # Symlink all files in the /zsh directory, e.g. zsh/.zshrc -> ~/.zshrc
    zsh_files=$(find "$DOTFILES/zsh" -mindepth 1 -maxdepth 1 2>/dev/null)
    for file in $zsh_files; do
        target="$HOME/$(basename "$file")"
        if [ -e "$target" ]; then
            info "~${target#$HOME} already exists... Skipping."
        else
            info "Creating symlink for $file"
            ln -s "$file" "$target"
        fi
    done

    echo -e
    info "installing to ~/.config"
    if [ ! -d "$HOME/.config" ]; then
        info "Creating ~/.config"
        mkdir -p "$HOME/.config"
    fi

    config_files=$(find "$DOTFILES/config" -mindepth 1 -maxdepth 1 2>/dev/null)
    for config in $config_files; do
        target="$HOME/.config/$(basename "$config")"
        if [ -e "$target" ]; then
            info "~${target#$HOME} already exists... Skipping."
        else
            info "Creating symlink for $config"
            ln -s "$config" "$target"
        fi
    done
}

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

case "$1" in
link)
    setup_symlinks
    ;;
shell)
    setup_shell
    ;;
all)
    setup_symlinks
    setup_shell
    ;;
*)
    echo -e $"\nUsage: $(basename "$0") {|link|shell|all}\n"
    exit 1
    ;;
esac

echo -e
success "Done."
