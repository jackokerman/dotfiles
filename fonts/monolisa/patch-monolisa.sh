#!/bin/bash
#
# MonoLisa Nerd Font Patcher
# Automatically extracts, patches, and installs MonoLisa fonts with Nerd Font glyphs
#
# Usage:
#   1. Download MonoLisa ZIP from your email link
#   2. Place ZIP file in fonts/monolisa/source/
#   3. This script is called automatically by install.sh during macOS setup

set -e

# Get the absolute path to the dotfiles directory
# Assumes this script is in dotfiles/fonts/monolisa/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for logging output
COLOR_BLUE="\033[34m"
COLOR_GREEN="\033[32m"
COLOR_RED="\033[31m"
COLOR_YELLOW="\033[33m"
COLOR_NONE="\033[0m"

# Logging functions (from install.sh)
info() {
    echo -e "${COLOR_BLUE}Info: ${COLOR_NONE}$1"
}

success() {
    echo -e "${COLOR_GREEN}$1${COLOR_NONE}"
}

warning() {
    echo -e "${COLOR_YELLOW}Warning: ${COLOR_NONE}$1" >&2
}

error() {
    echo -e "${COLOR_RED}Error: ${COLOR_NONE}$1" >&2
    exit 1
}

# Directories
SOURCE_DIR="$SCRIPT_DIR/source"
EXTRACTED_DIR="$SCRIPT_DIR/extracted"
PATCHED_DIR="$SCRIPT_DIR/patched"
PATCHER_DIR="$SCRIPT_DIR/monolisa-nerdfont-patch"

# Clone or update the patcher tool
setup_patcher() {
    info "Setting up Nerd Font patcher..."

    if [ -d "$PATCHER_DIR" ]; then
        info "Updating patcher to latest version..."
        cd "$PATCHER_DIR"
        git fetch origin --quiet
        git reset --hard origin/main --quiet
        cd "$SCRIPT_DIR"
    else
        info "Cloning Nerd Font patcher..."
        git clone --depth 1 --quiet https://github.com/daylinmorgan/monolisa-nerdfont-patch.git "$PATCHER_DIR"
    fi
}

# Extract the ZIP file
extract_fonts() {
    info "Looking for MonoLisa ZIP file..."

    local zip_file="$SOURCE_DIR"/*.zip

    if [ ! -f $zip_file ]; then
        warning "No ZIP file found in $SOURCE_DIR"
        info "Download MonoLisa and place the ZIP file in: $SOURCE_DIR"
        return 1
    fi

    # Clean and recreate extracted directory
    rm -rf "$EXTRACTED_DIR"
    mkdir -p "$EXTRACTED_DIR"

    local filename=$(basename "$zip_file")
    info "Extracting $filename..."
    unzip -q "$zip_file" -d "$EXTRACTED_DIR"

    # Check if fonts were extracted
    if ! find "$EXTRACTED_DIR" -type f \( -name "*.ttf" -o -name "*.otf" \) | grep -q .; then
        error "No font files found after extraction"
    fi
}

# Patch fonts with Nerd Font glyphs
patch_fonts() {
    # Check for fontforge before patching
    if ! command -v fontforge &> /dev/null; then
        error "fontforge is not installed. Run: brew install fontforge"
    fi

    info "Patching fonts with Nerd Font glyphs (this may take a few minutes)..."

    # Clean and recreate patched directory
    rm -rf "$PATCHED_DIR"
    mkdir -p "$PATCHED_DIR"

    cd "$PATCHER_DIR"
    ./patch-monolisa -c -f "$EXTRACTED_DIR" -o "$PATCHED_DIR"
    cd "$SCRIPT_DIR"
}

# Install fonts to system
install_fonts() {
    info "Installing fonts to system..."

    local font_dir="$HOME/Library/Fonts"
    local installed_count=0
    local font_names=()

    # Find all font files recursively in patched directory
    while IFS= read -r -d '' font; do
        if [ -f "$font" ]; then
            local filename=$(basename "$font")
            cp "$font" "$font_dir/"
            installed_count=$((installed_count + 1))

            # Store font name without extension for display
            local name=$(basename "$font" .ttf)
            name=$(basename "$name" .otf)
            font_names+=("$name")
        fi
    done < <(find "$PATCHED_DIR" -type f \( -name "*.ttf" -o -name "*.otf" \) -print0)

    if [ $installed_count -eq 0 ]; then
        error "No font files found to install"
    fi

    success "Installed $installed_count font files:"
    for name in "${font_names[@]}"; do
        echo "  - $name"
    done
}

# Main execution
main() {
    setup_patcher
    extract_fonts || return 1
    patch_fonts
    install_fonts
}

main "$@"
