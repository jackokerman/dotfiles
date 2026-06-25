#!/usr/bin/env bash
set -euo pipefail

source "$DOTTY_LIB"

legacy_zshrc="$HOME/.zshrc"
backup_zshrc="$HOME/.zshrc.pre-zdotdir-backup"
backup_index=1

[[ -f "$legacy_zshrc" && ! -L "$legacy_zshrc" ]] || exit 0

if ! grep -Eq '(^|[[:space:]])source[[:space:]].*/dotfiles/home/\.zshrc($|[[:space:]])' "$legacy_zshrc"; then
    exit 0
fi

while [[ -e "$backup_zshrc" ]]; do
    backup_zshrc="$HOME/.zshrc.pre-zdotdir-backup.$backup_index"
    ((backup_index++))
done

mv "$legacy_zshrc" "$backup_zshrc"
success "Moved stale ~/.zshrc wrapper to $backup_zshrc"
