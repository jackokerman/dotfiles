#!/usr/bin/env bash
#
# Temporary migration script: -local to .local naming convention
# This script cleans up old symlinks. Remove after all machines are updated.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"

MIGRATED=false

migrate_file() {
    local old="$1"
    if [ -L "$old" ] || [ -f "$old" ]; then
        rm -f "$old"
        info "Removed old: ${old/#$HOME/~}"
        MIGRATED=true
    fi
}

title "Migrating from -local to .local naming convention"

# Home directory files
migrate_file "$HOME/.zshrc-local"
migrate_file "$HOME/.zshenv-local"
migrate_file "$HOME/.gitconfig-local"
migrate_file "$HOME/.aerospace-arrangement-local"

# Config directory files
migrate_file "$HOME/.config/hammerspoon/init-local.lua"

if [ "$MIGRATED" = true ]; then
    echo ""
    success "Migration complete. New symlinks will be created by stripe-dotfiles install."
    echo ""
    warning "REMINDER: After all machines are updated, remove this migration:"
    echo "    1. rm \$DOTFILES/scripts/migrate-local-naming.sh"
    echo "    2. Remove the migration call from install.sh"
else
    info "No old -local files found. Nothing to migrate."
fi
