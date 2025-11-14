#!/usr/bin/env bash

# Setup macOS Dock with core applications and folders
# This script configures the dock with apps that are the same across all machines
# Machine-specific apps (like Slack on work machines) can be added via setup-dock.local.sh

set -e

DOTFILES="${DOTFILES:-$HOME/dotfiles}"

# Load logging utilities
source "$(dirname "$0")/logging.sh"

# Helper function to add an app to the dock only if it exists
add_app_if_exists() {
    local app_path="$1"
    if [ -d "$app_path" ]; then
        dockutil --add "$app_path" --no-restart
    fi
}

title "Setting up Dock"

# Remove all existing dock items
info "Clearing existing dock items..."
dockutil --remove all --no-restart

# Add core applications (left side)
# Note: Finder is always present and cannot be removed, so we skip it
info "Adding core applications..."
add_app_if_exists '/Applications/Google Chrome.app'
add_app_if_exists '/Applications/Safari.app'
add_app_if_exists '/Applications/Visual Studio Code.app'
add_app_if_exists '/Applications/Cursor.app'
add_app_if_exists '/Applications/Obsidian.app'
add_app_if_exists '/Applications/Super Whisper.app'

# Add folders/stacks (right side)
info "Adding folders..."
dockutil --add "$HOME/Screenshots" --view grid --display stack --section others --no-restart
dockutil --add "$HOME/Downloads" --view grid --display stack --section others --no-restart

# Load local dock configuration if it exists (for machine-specific additions like Slack)
if [ -f "$DOTFILES/scripts/setup-dock.local.sh" ]; then
    info "Loading local dock configuration..."
    source "$DOTFILES/scripts/setup-dock.local.sh"
fi

# Restart Dock to apply all changes
info "Restarting Dock..."
killall Dock

success "Dock setup complete!"
