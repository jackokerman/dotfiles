#!/usr/bin/env bash
#
# Shared utilities for dotfiles scripts
# Source this file with: source "$(dirname "$0")/utils.sh"

# Source logging utilities
UTILS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$UTILS_SCRIPT_DIR/logging.sh"

# Improved symlink helper - updates symlinks if source changed
# This enables the overlay pattern: run personal first, then overlay (overlay wins)
create_symlink() {
    local source="$1"
    local target="$2"

    if [ -L "$target" ]; then
        local current_source=$(readlink "$target")
        if [ "$current_source" = "$source" ]; then
            info "~${target#$HOME} already linked... Skipping."
            return 0
        else
            info "Updating symlink: ~${target#$HOME}"
            rm "$target"
        fi
    elif [ -e "$target" ]; then
        warning "~${target#$HOME} already exists (not a symlink)... Skipping."
        return 0
    fi

    local description="$(basename "$source")"
    if ln -s "$source" "$target"; then
        success "Linked: ~${target#$HOME}"
        return 0
    else
        error "Failed to create symlink for $description"
    fi
}

# Merge JSON settings files
# Source values win on conflicts, but permissions.allow arrays are unioned
merge_json_settings() {
    local source="$1"
    local target="$2"

    if [[ ! -f "$source" ]]; then
        warning "Source settings not found: $source"
        return 1
    fi

    if [[ -f "$target" ]]; then
        info "Merging settings (source wins, preserves unique target additions)"
        cp "$target" "$target.backup"

        if command -v jq &> /dev/null; then
            # Step 1: Extract and merge permissions.allow arrays
            local source_perms=$(jq -r '.permissions.allow // []' "$source")
            local target_perms=$(jq -r '.permissions.allow // []' "$target")
            local merged_perms=$(echo "$source_perms $target_perms" | jq -s 'add | unique | sort')

            # Step 2: Merge objects (source wins), then set merged permissions
            jq -s '.[0] * .[1]' "$target" "$source" | \
                jq --argjson perms "$merged_perms" '.permissions.allow = $perms' \
                > "$target.tmp" && mv "$target.tmp" "$target"
            success "Settings merged"
        else
            cp "$source" "$target"
            warning "jq not found - copied settings (no merge)"
        fi
    else
        info "Creating settings from source"
        cp "$source" "$target"
        success "Settings created"
    fi
}

# Generic function to create symlinks from a source directory
# Overlay behavior: run personal first, then overlay (overlay wins due to updated create_symlink)
create_symlinks_from_dir() {
    local source_dir="$1"
    local target_dir="$2"

    if [ ! -d "$source_dir" ]; then
        return 0  # Not an error, just nothing to do
    fi

    mkdir -p "$target_dir"

    # Define patterns to exclude (version control files and install scripts)
    local exclude_patterns="-name .git -o -name .gitignore -o -name .gitmodules -o -name README.md -o -name install.sh"

    local items=$(find "$source_dir" -mindepth 1 -maxdepth 1 \( $exclude_patterns \) -prune -o -print 2>/dev/null)
    for item in $items; do
        local basename_item=$(basename "$item")
        local target_item="$target_dir/$basename_item"

        if [ -d "$item" ]; then
            if [ -d "$target_item" ] || [ -L "$target_item" ]; then
                # Recursively merge directory contents
                create_symlinks_from_dir "$item" "$target_item"
            else
                create_symlink "$item" "$target_item"
            fi
        else
            create_symlink "$item" "$target_item"
        fi
    done
}
