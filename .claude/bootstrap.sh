#!/bin/bash
# Bootstrap Claude config
# Usage: bootstrap.sh [overlay_path]
#   overlay_path: Optional path to work/overlay .claude/ directory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PERSONAL_CLAUDE="$SCRIPT_DIR"
OVERLAY_CLAUDE="${1:-}"
TARGET="$HOME/.claude"

# Source shared utilities
source "$HOME/dotfiles/scripts/utils.sh"

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
