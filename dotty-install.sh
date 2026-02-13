#!/usr/bin/env bash
#
# dotty install hook for personal dotfiles
# Runs after symlinks are created. DOTTY_REPO_DIR and DOTTY_ENV are exported.

# Source install.sh to get all setup_* functions (guarded, won't auto-run)
DOTFILES="$DOTTY_REPO_DIR"
source "$DOTTY_REPO_DIR/install.sh"

setup_git_hooks
setup_vscode_settings
setup_vscode_theme
setup_shell

if [[ "$(uname -s)" == "Darwin" ]]; then
    setup_brew
    setup_macos
fi
