#!/bin/bash
# Bootstrap Claude config
# Usage: bootstrap.sh [overlay_path]
#   overlay_path: Optional path to work/overlay .claude/ directory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PERSONAL_CLAUDE="$SCRIPT_DIR"
OVERLAY_CLAUDE="${1:-}"
TARGET="$HOME/.claude"

# Source shared utilities (derive from SCRIPT_DIR so it works regardless of repo location)
source "$(dirname "$SCRIPT_DIR")/scripts/utils.sh"

title "Bootstrapping Claude config"
info "Personal: $PERSONAL_CLAUDE"
[[ -n "$OVERLAY_CLAUDE" ]] && info "Overlay:  $OVERLAY_CLAUDE"

# Ensure target directories exist
mkdir -p "$TARGET/commands"
mkdir -p "$TARGET/rules"

# Symlink directories from personal, then overlay (overlay wins on conflicts)
for dir in commands rules agents hooks; do
    create_symlinks_from_dir "$PERSONAL_CLAUDE/$dir" "$TARGET/$dir"
    [[ -n "$OVERLAY_CLAUDE" ]] && create_symlinks_from_dir "$OVERLAY_CLAUDE/$dir" "$TARGET/$dir"
done

# Concatenate CLAUDE.md (personal + overlay)
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

# Clean up deprecated files
rm -f "$TARGET/settings.local.json" "$TARGET/settings.local.json.backup"

# Prime Claude FIRST to let it create default settings files
# This must happen BEFORE we merge our settings, otherwise Claude overwrites them
if command -v claude &> /dev/null; then
    info "Priming Claude to initialize default settings..."
    claude -p "" 2>/dev/null || true
fi

# NOW merge settings.json (overlay wins on values, permissions arrays are unioned)
# This happens AFTER priming so our settings persist
if [[ -n "$OVERLAY_CLAUDE" ]] && [[ -f "$OVERLAY_CLAUDE/settings.json" ]]; then
    merge_json_settings "$OVERLAY_CLAUDE/settings.json" "$TARGET/settings.json"
elif [[ -f "$PERSONAL_CLAUDE/settings.json" ]]; then
    merge_json_settings "$PERSONAL_CLAUDE/settings.json" "$TARGET/settings.json"
fi

# Mark onboarding complete and set theme AFTER priming
# Claude may modify .claude.json during startup, so we set our values last
CLAUDE_JSON="$HOME/.claude.json"
if command -v jq &> /dev/null; then
    if [[ -f "$CLAUDE_JSON" ]]; then
        jq '.hasCompletedOnboarding = true | .theme = "dark"' "$CLAUDE_JSON" > "$CLAUDE_JSON.tmp" && mv "$CLAUDE_JSON.tmp" "$CLAUDE_JSON"
    else
        echo '{"hasCompletedOnboarding": true, "theme": "dark"}' > "$CLAUDE_JSON"
    fi
    success "Onboarding marked complete, theme set to dark"
fi

success "Claude config bootstrapped to ~/.claude"
