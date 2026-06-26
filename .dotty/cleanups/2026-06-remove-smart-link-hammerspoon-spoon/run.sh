#!/usr/bin/env bash
set -euo pipefail

readonly smart_link_spoon="$HOME/.config/hammerspoon/MySpoons/SmartLinkManager.spoon"
readonly smart_link_init="$smart_link_spoon/init.lua"
readonly old_target="$HOME/.dotty/repos/dotfiles/home/.config/hammerspoon/MySpoons/SmartLinkManager.spoon/init.lua"

if [[ ! -e "$smart_link_spoon" ]]; then
    exit 0
fi

if [[ -L "$smart_link_init" && "$(readlink "$smart_link_init")" == "$old_target" ]]; then
    if [[ "${DOTTY_DRY_RUN:-false}" == "true" ]]; then
        printf '[dry-run] Would remove stale Hammerspoon spoon %s\n' "$smart_link_spoon"
        exit 0
    fi

    rm -rf "$smart_link_spoon"
    printf 'Removed stale Hammerspoon spoon %s\n' "$smart_link_spoon"
fi
