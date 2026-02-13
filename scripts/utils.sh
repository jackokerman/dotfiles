#!/usr/bin/env bash
#
# Shared utilities for dotfiles scripts.
# Provides merge_json_settings; logging and symlink functions come from DOTTY_LIB.

source "$DOTTY_LIB"

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
            local source_perms target_perms merged_perms
            source_perms=$(jq -r '.permissions.allow // []' "$source")
            target_perms=$(jq -r '.permissions.allow // []' "$target")
            merged_perms=$(echo "$source_perms $target_perms" | jq -s 'add | unique | sort')

            # Step 2: Merge objects (source wins), then set merged permissions
            jq -s '.[0] * .[1]' "$target" "$source" | \
                jq --argjson perms "$merged_perms" '.permissions.allow = $perms' \
                > "$target.tmp" && mv "$target.tmp" "$target"
            success "Settings merged"
        else
            cp "$source" "$target"
            warning "jq not found, copied settings (no merge)"
        fi
    else
        info "Creating settings from source"
        cp "$source" "$target"
        success "Settings created"
    fi
}
