#!/usr/bin/env bash
#
# Shared utilities for dotfiles scripts
# Source this file with: source "$(dirname "$0")/utils.sh"

UTILS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$UTILS_SCRIPT_DIR/logging.sh"

_SKIP_COUNT=0
_LINK_DEPTH=0

# This enables the overlay pattern: run personal first, then overlay (overlay wins)
create_symlink() {
    local source="$1"
    local target="$2"

    if [ -L "$target" ]; then
        local current_source=$(readlink "$target")
        if [ "$current_source" = "$source" ]; then
            _SKIP_COUNT=$((_SKIP_COUNT + 1))
            if [[ "${DOTTY_VERBOSE:-false}" == "true" ]]; then
                info "~${target#$HOME} already linked... Skipping."
            fi
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

# Overlay behavior: run personal first, then overlay (overlay wins due to updated create_symlink)
create_symlinks_from_dir() {
    local source_dir="$1"
    local target_dir="$2"

    if [ ! -d "$source_dir" ]; then
        return 0  # Not an error, just nothing to do
    fi

    _LINK_DEPTH=$((_LINK_DEPTH + 1))
    # Reset skip counter at the top-level call
    if [[ $_LINK_DEPTH -eq 1 ]]; then
        _SKIP_COUNT=0
    fi

    mkdir -p "$target_dir"

    local exclude_patterns="-name .git -o -name .gitignore -o -name .gitmodules -o -name README.md -o -name install.sh"

    local items=$(find "$source_dir" -mindepth 1 -maxdepth 1 \( $exclude_patterns \) -prune -o -print 2>/dev/null)
    for item in $items; do
        local basename_item=$(basename "$item")
        local target_item="$target_dir/$basename_item"

        if [ -d "$item" ]; then
            if [ -L "$target_item" ]; then
                # Target is a symlink - check if it points to the right place
                local current_source=$(readlink "$target_item")
                if [ "$current_source" = "$item" ]; then
                    _SKIP_COUNT=$((_SKIP_COUNT + 1))
                    if [[ "${DOTTY_VERBOSE:-false}" == "true" ]]; then
                        info "~${target_item#$HOME} already linked... Skipping."
                    fi
                else
                    info "Updating symlink: ~${target_item#$HOME}"
                    rm "$target_item"
                    create_symlink "$item" "$target_item"
                fi
            elif [ -d "$target_item" ]; then
                # Target is a real directory - recurse to merge contents
                create_symlinks_from_dir "$item" "$target_item"
            else
                create_symlink "$item" "$target_item"
            fi
        else
            create_symlink "$item" "$target_item"
        fi
    done

    _LINK_DEPTH=$((_LINK_DEPTH - 1))
    # Print summary when returning to top level
    if [[ $_LINK_DEPTH -eq 0 && $_SKIP_COUNT -gt 0 ]]; then
        info "$_SKIP_COUNT files already linked"
        _SKIP_COUNT=0
    fi
}
