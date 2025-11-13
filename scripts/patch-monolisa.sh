#!/bin/bash
#
# MonoLisa Nerd Font Patcher
# Automatically extracts, patches, and installs MonoLisa fonts with Nerd Font glyphs
#
# Usage:
#   1. Download MonoLisa ZIP from your email link to ~/Downloads/
#   2. This script is called automatically by install.sh during macOS setup
#   3. The script will look for the ZIP in ~/Downloads/ automatically

set -e

# Get the absolute path to the dotfiles directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source shared logging utilities
source "$SCRIPT_DIR/logging.sh"

# Directories
DOWNLOADS_DIR="$HOME/Downloads"
TMP_DIR="$DOTFILES/tmp"
EXTRACTED_DIR="$TMP_DIR/monolisa-extracted"
PATCHED_DIR="$TMP_DIR/monolisa-patched"
PATCHER_DIR="$TMP_DIR/monolisa-nerdfont-patch"

# Clone or update the patcher tool
setup_patcher() {
    info "Setting up Nerd Font patcher..."

    # Create tmp directory if it doesn't exist
    mkdir -p "$TMP_DIR"

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

# Get font version using fontforge
get_font_version() {
    local font_file="$1"

    if [ ! -f "$font_file" ]; then
        return 1
    fi

    local font_dir="$(dirname "$font_file")"
    local font_name="$(basename "$font_file")"

    # Extract version using fontforge, filter out warnings
    local version=$(cd "$font_dir" 2>/dev/null && \
                    fontforge -lang=py -c "import fontforge; font = fontforge.open('$font_name'); print(font.version)" 2>&1 | \
                    grep -v "Copyright\|License\|Version:\|Based on\|Core python\|Warning:" | \
                    tail -1)

    # Extract base version (before semicolon if present)
    # e.g., "2.017;Nerd Fonts 3.4.0" -> "2.017"
    echo "$version" | cut -d';' -f1
}

# Check if patching can be skipped
should_skip_patching() {
    # Look for extracted MonoLisa font (unpatched)
    local extracted_font=$(find "$EXTRACTED_DIR" -type f -name "MonoLisa-Regular.*" \( -name "*.ttf" -o -name "*.otf" \) | head -n 1)

    # Look for installed MonoLisa Nerd Font (patched)
    local installed_font="$HOME/Library/Fonts/MonoLisaNerdFont-Regular.ttf"

    if [ -z "$extracted_font" ] || [ ! -f "$installed_font" ]; then
        # Can't compare - continue with patching
        return 1
    fi

    local extracted_version=$(get_font_version "$extracted_font")
    local installed_version=$(get_font_version "$installed_font")

    if [ -z "$extracted_version" ] || [ -z "$installed_version" ]; then
        # Couldn't get versions - continue with patching
        return 1
    fi

    info "Downloaded version: $extracted_version"
    info "Installed version: $installed_version"

    if [ "$extracted_version" = "$installed_version" ]; then
        success "MonoLisa v$installed_version already installed, skipping patch"
        return 0  # Skip patching
    fi

    return 1  # Continue with patching
}

# Extract the ZIP file
extract_fonts() {
    info "Looking for MonoLisa ZIP file in ~/Downloads/..."

    local zip_file=$(find "$DOWNLOADS_DIR" -name "*MonoLisa*" -o -name "*monolisa*" | grep -i "\.zip$" | head -n 1)

    if [ -z "$zip_file" ]; then
        warning "No MonoLisa ZIP file found in $DOWNLOADS_DIR"
        info "Download MonoLisa and place the ZIP file in: $DOWNLOADS_DIR"
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

    # Check if we can skip patching
    if should_skip_patching; then
        return 0
    fi

    patch_fonts
    install_fonts
}

main "$@"
