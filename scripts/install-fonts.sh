#!/bin/bash
# Font Installation Script
# Installs MonoLisa (if downloaded) and Symbols Nerd Font (auto-downloaded)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/logging.sh"

FONTS_DIR="$HOME/Library/Fonts"
DOWNLOADS_DIR="$HOME/Downloads"
NERD_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.zip"

install_symbols_nerd_font() {
    # Check if already installed
    if [ -f "$FONTS_DIR/SymbolsNerdFontMono-Regular.ttf" ]; then
        success "Symbols Nerd Font Mono already installed"
        return 0
    fi

    info "Downloading Symbols Nerd Font..."
    local tmp_dir=$(mktemp -d)
    local zip_file="$tmp_dir/NerdFontsSymbolsOnly.zip"

    if curl -sL "$NERD_FONT_URL" -o "$zip_file"; then
        unzip -q "$zip_file" -d "$tmp_dir"
        cp "$tmp_dir/SymbolsNerdFontMono-Regular.ttf" "$FONTS_DIR/"
        success "Symbols Nerd Font Mono installed"
        rm -rf "$tmp_dir"
    else
        error "Failed to download Symbols Nerd Font"
        rm -rf "$tmp_dir"
        return 1
    fi
}

install_monolisa() {
    # Check if already installed
    if ls "$FONTS_DIR"/MonoLisaVariable*.ttf &>/dev/null; then
        success "MonoLisa Variable already installed"
        return 0
    fi

    # Look for MonoLisa ZIP in Downloads
    local zip_file=$(find "$DOWNLOADS_DIR" -maxdepth 1 -name "*MonoLisa*Complete*.zip" -type f 2>/dev/null | head -n 1)

    if [ -z "$zip_file" ]; then
        warning "MonoLisa not found"
        info "To install MonoLisa:"
        info "  1. Visit https://www.monolisa.dev/orders"
        info "  2. Log in with your email and order number (check your purchase confirmation email)"
        info "  3. Download the Complete version ZIP to $DOWNLOADS_DIR"
        info "  4. Re-run: ./scripts/install-fonts.sh"
        return 0
    fi

    info "Installing MonoLisa from $zip_file..."
    local tmp_dir=$(mktemp -d)

    unzip -q "$zip_file" -d "$tmp_dir"

    # Find and copy TTF files
    local ttf_dir=$(find "$tmp_dir" -type d -name "ttf" | head -n 1)
    if [ -n "$ttf_dir" ]; then
        cp "$ttf_dir"/*.ttf "$FONTS_DIR/"
        success "MonoLisa Variable installed"
    else
        error "Could not find ttf directory in ZIP"
        rm -rf "$tmp_dir"
        return 1
    fi

    rm -rf "$tmp_dir"
}

main() {
    info "Installing fonts..."
    mkdir -p "$FONTS_DIR"

    install_symbols_nerd_font
    install_monolisa

    info "Font installation complete"
}

main "$@"
