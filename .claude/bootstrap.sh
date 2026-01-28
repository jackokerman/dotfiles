#!/bin/bash
# Bootstrap Claude config
# Usage: bootstrap.sh [overlay_path]
#   overlay_path: Optional path to work/overlay .claude/ directory

set -e

PERSONAL_CLAUDE="$HOME/dotfiles/.claude"
OVERLAY_CLAUDE="${1:-}"  # Optional overlay path (e.g., ~/stripe-dotfiles/.claude)
TARGET="$HOME/.claude"

echo "Bootstrapping Claude config..."
echo "  Personal: $PERSONAL_CLAUDE"
[[ -n "$OVERLAY_CLAUDE" ]] && echo "  Overlay:  $OVERLAY_CLAUDE"

# 1. Create target directories
mkdir -p "$TARGET/commands"
mkdir -p "$TARGET/rules"

# 2. Copy settings.local.json (overlay wins)
# Note: Claude writes session permissions to settings.json, not here
# Backup existing settings.local.json in case user wants to review accumulated permissions
if [[ -f "$TARGET/settings.local.json" ]]; then
  cp "$TARGET/settings.local.json" "$TARGET/settings.local.json.backup"
  echo "  Backed up existing settings.local.json"
fi
rm -f "$TARGET/settings.local.json"
if [[ -n "$OVERLAY_CLAUDE" ]] && [[ -f "$OVERLAY_CLAUDE/settings.local.json" ]]; then
  cp "$OVERLAY_CLAUDE/settings.local.json" "$TARGET/settings.local.json"
  echo "  Copied settings.local.json (from overlay)"
elif [[ -f "$PERSONAL_CLAUDE/settings.local.json" ]]; then
  cp "$PERSONAL_CLAUDE/settings.local.json" "$TARGET/settings.local.json"
  echo "  Copied settings.local.json (from personal)"
fi

# 3. Concatenate CLAUDE.md (personal + overlay)
# Personal preferences (communication style, JS standards) persist with work context added
rm -f "$TARGET/CLAUDE.md"
if [[ -f "$PERSONAL_CLAUDE/CLAUDE.md" ]] && [[ -n "$OVERLAY_CLAUDE" ]] && [[ -f "$OVERLAY_CLAUDE/CLAUDE.md" ]]; then
  cat "$PERSONAL_CLAUDE/CLAUDE.md" > "$TARGET/CLAUDE.md"
  echo "" >> "$TARGET/CLAUDE.md"
  echo "---" >> "$TARGET/CLAUDE.md"
  echo "" >> "$TARGET/CLAUDE.md"
  cat "$OVERLAY_CLAUDE/CLAUDE.md" >> "$TARGET/CLAUDE.md"
  echo "  Concatenated CLAUDE.md (personal + overlay)"
elif [[ -f "$PERSONAL_CLAUDE/CLAUDE.md" ]]; then
  cp "$PERSONAL_CLAUDE/CLAUDE.md" "$TARGET/CLAUDE.md"
  echo "  Copied CLAUDE.md (from personal)"
elif [[ -n "$OVERLAY_CLAUDE" ]] && [[ -f "$OVERLAY_CLAUDE/CLAUDE.md" ]]; then
  cp "$OVERLAY_CLAUDE/CLAUDE.md" "$TARGET/CLAUDE.md"
  echo "  Copied CLAUDE.md (from overlay)"
fi

# 4. Symlink rules from personal (code style, etc.)
# Symlinks allow edits to apply to next session without re-running bootstrap
if [[ -d "$PERSONAL_CLAUDE/rules" ]]; then
  for rule in "$PERSONAL_CLAUDE/rules"/*.md; do
    [[ -f "$rule" ]] && ln -sf "$rule" "$TARGET/rules/$(basename "$rule")"
  done
fi

# 5. Symlink rules from overlay (overwrites personal if same name)
if [[ -n "$OVERLAY_CLAUDE" ]] && [[ -d "$OVERLAY_CLAUDE/rules" ]]; then
  for rule in "$OVERLAY_CLAUDE/rules"/*.md; do
    [[ -f "$rule" ]] && ln -sf "$rule" "$TARGET/rules/$(basename "$rule")"
  done
fi

# Count rules
rule_count=$(ls -1 "$TARGET/rules"/*.md 2>/dev/null | wc -l | tr -d ' ')
echo "  Symlinked $rule_count rules"

# 6. Symlink commands from personal
if [[ -d "$PERSONAL_CLAUDE/commands" ]]; then
  for cmd in "$PERSONAL_CLAUDE/commands"/*.md; do
    [[ -f "$cmd" ]] && ln -sf "$cmd" "$TARGET/commands/$(basename "$cmd")"
  done
fi

# 7. Symlink commands from overlay (overwrites personal if same name)
if [[ -n "$OVERLAY_CLAUDE" ]] && [[ -d "$OVERLAY_CLAUDE/commands" ]]; then
  for cmd in "$OVERLAY_CLAUDE/commands"/*.md; do
    [[ -f "$cmd" ]] && ln -sf "$cmd" "$TARGET/commands/$(basename "$cmd")"
  done
fi

# Count commands
cmd_count=$(ls -1 "$TARGET/commands"/*.md 2>/dev/null | wc -l | tr -d ' ')
echo "  Symlinked $cmd_count commands"

echo "Done! Claude config bootstrapped to ~/.claude"
