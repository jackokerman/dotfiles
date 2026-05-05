#!/usr/bin/env bash

set -euo pipefail

log() {
    printf '[install-nvim-js-tools] %s\n' "$*"
}

if ! command -v bun >/dev/null 2>&1; then
    log 'bun not found, skipping install'
    exit 0
fi

export PATH="$HOME/.bun/bin:$PATH"

required_commands=(
    tsc
    typescript-language-server
    vscode-eslint-language-server
)

missing_commands=()
for command_name in "${required_commands[@]}"; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        missing_commands+=("$command_name")
    fi
done

if [[ ${#missing_commands[@]} -eq 0 ]]; then
    log 'Neovim JS tools already installed'
    exit 0
fi

log "Installing missing Neovim JS tools: ${missing_commands[*]}"
bun add --global typescript typescript-language-server vscode-langservers-extracted
log 'Neovim JS tools installed'
