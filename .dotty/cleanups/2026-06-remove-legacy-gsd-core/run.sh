#!/usr/bin/env bash
set -euo pipefail

source "$DOTTY_LIB"

codex_dir="$HOME/.codex"
installer="$HOME/.local/bin/gsd-core-install"
checkout_installer="$HOME/.local/share/gsd-core/repo/bin/install.js"

if [[ -x "$installer" ]]; then
    "$installer" --codex --global --uninstall || warning "Failed to run legacy GSD Core uninstaller"
elif [[ -f "$checkout_installer" ]]; then
    node "$checkout_installer" --codex --global --uninstall || warning "Failed to run legacy GSD Core checkout uninstaller"
fi

paths=(
    "$HOME/.local/bin/gsd-tools"
    "$HOME/.local/bin/gsd-core-install"
    "$HOME/.local/share/gsd-core"
    "$HOME/.local/state/dotfiles/gsd-core"
    "$codex_dir/.gsd-profile"
    "$codex_dir/gsd-core"
    "$codex_dir/gsd-file-manifest.json"
    "$codex_dir/gsd-install-state.json"
    "$codex_dir/gsd-migration-journal"
)
rm -rf -- "${paths[@]}"

generated_paths=()
for path in "$codex_dir"/skills/gsd-* "$codex_dir"/agents/gsd-* "$codex_dir"/hooks/gsd-*; do
    [[ -e "$path" ]] && generated_paths+=("$path")
done

if [[ ${#generated_paths[@]} -gt 0 ]]; then
    rm -rf -- "${generated_paths[@]}"
fi

rmdir "$HOME/.local/state/dotfiles" 2>/dev/null || true
