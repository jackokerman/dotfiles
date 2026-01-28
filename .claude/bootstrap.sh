#!/bin/bash
# Bootstrap Claude config
# Usage: bootstrap.sh [overlay_path]
#   overlay_path: Optional path to work/overlay .claude/ directory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PERSONAL_CLAUDE="$SCRIPT_DIR"
OVERLAY_CLAUDE="${1:-}"
TARGET="$HOME/.claude"

# Source shared utilities (includes logging and symlink functions)
if [[ -f "$HOME/dotfiles/scripts/utils.sh" ]]; then
    source "$HOME/dotfiles/scripts/utils.sh"
elif [[ -f "$HOME/dotfiles/scripts/logging.sh" ]]; then
    # Fallback to just logging if utils.sh doesn't exist yet
    source "$HOME/dotfiles/scripts/logging.sh"
    # Define minimal versions of needed functions
    create_symlink() {
        local source="$1" target="$2"
        [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]] && return 0
        [[ -e "$target" ]] && { cp "$target" "$target.backup" 2>/dev/null; rm -f "$target"; }
        ln -sf "$source" "$target" && success "Linked: ~${target#$HOME}"
    }
    merge_json_settings() {
        local source="$1" target="$2"
        [[ -f "$target" ]] && cp "$target" "$target.backup"
        if command -v jq &>/dev/null && [[ -f "$target" ]]; then
            local source_perms=$(jq -r '.permissions.allow // []' "$source")
            local target_perms=$(jq -r '.permissions.allow // []' "$target")
            local merged_perms=$(echo "$source_perms $target_perms" | jq -s 'add | unique | sort')
            jq -s '.[0] * .[1]' "$target" "$source" | jq --argjson perms "$merged_perms" '.permissions.allow = $perms' > "$target.tmp" && mv "$target.tmp" "$target"
        else
            cp "$source" "$target"
        fi
    }
    create_symlinks_from_dir() {
        local src="$1" tgt="$2"
        [[ -d "$src" ]] || return 0
        mkdir -p "$tgt"
        for item in "$src"/*; do
            [[ -e "$item" ]] || continue
            local name=$(basename "$item")
            [[ -d "$item" ]] && create_symlinks_from_dir "$item" "$tgt/$name" || create_symlink "$item" "$tgt/$name"
        done
    }
else
    echo "Error: dotfiles not found" >&2
    exit 1
fi

title "Bootstrapping Claude config"
info "Personal: $PERSONAL_CLAUDE"
[[ -n "$OVERLAY_CLAUDE" ]] && info "Overlay:  $OVERLAY_CLAUDE"

# 1. Ensure target directories exist
mkdir -p "$TARGET/commands"
mkdir -p "$TARGET/rules"

# 2. Symlink directories from personal, then overlay (overlay wins on conflicts)
# This handles: commands/, rules/, agents/, hooks/, etc.
for dir in commands rules agents hooks; do
    create_symlinks_from_dir "$PERSONAL_CLAUDE/$dir" "$TARGET/$dir"
    [[ -n "$OVERLAY_CLAUDE" ]] && create_symlinks_from_dir "$OVERLAY_CLAUDE/$dir" "$TARGET/$dir"
done

# 3. Merge settings.json (overlay wins on values, permissions arrays are unioned)
# Claude reads/writes settings.json on startup - merging preserves accumulated permissions
if [[ -n "$OVERLAY_CLAUDE" ]] && [[ -f "$OVERLAY_CLAUDE/settings.json" ]]; then
    merge_json_settings "$OVERLAY_CLAUDE/settings.json" "$TARGET/settings.json"
elif [[ -f "$PERSONAL_CLAUDE/settings.json" ]]; then
    merge_json_settings "$PERSONAL_CLAUDE/settings.json" "$TARGET/settings.json"
fi

# 4. Concatenate CLAUDE.md (personal + overlay, not symlinked)
# Personal preferences persist with work context added
rm -f "$TARGET/CLAUDE.md"
if [[ -f "$PERSONAL_CLAUDE/CLAUDE.md" ]] && [[ -n "$OVERLAY_CLAUDE" ]] && [[ -f "$OVERLAY_CLAUDE/CLAUDE.md" ]]; then
    cat "$PERSONAL_CLAUDE/CLAUDE.md" > "$TARGET/CLAUDE.md"
    echo -e "\n---\n" >> "$TARGET/CLAUDE.md"
    cat "$OVERLAY_CLAUDE/CLAUDE.md" >> "$TARGET/CLAUDE.md"
    success "CLAUDE.md concatenated (personal + overlay)"
elif [[ -f "$PERSONAL_CLAUDE/CLAUDE.md" ]]; then
    cp "$PERSONAL_CLAUDE/CLAUDE.md" "$TARGET/CLAUDE.md"
    success "CLAUDE.md copied (from personal)"
elif [[ -n "$OVERLAY_CLAUDE" ]] && [[ -f "$OVERLAY_CLAUDE/CLAUDE.md" ]]; then
    cp "$OVERLAY_CLAUDE/CLAUDE.md" "$TARGET/CLAUDE.md"
    success "CLAUDE.md copied (from overlay)"
fi

# 5. Clean up deprecated files (settings.local.json is no longer used)
rm -f "$TARGET/settings.local.json" "$TARGET/settings.local.json.backup"

# 6. Prime Claude to initialize settings
# This ensures Claude reads settings.json before the first interactive session
if command -v claude &> /dev/null; then
    info "Priming Claude to initialize settings..."
    claude -p "" 2>/dev/null || true
fi

success "Claude config bootstrapped to ~/.claude"
