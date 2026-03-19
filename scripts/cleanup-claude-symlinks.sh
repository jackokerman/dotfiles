#!/usr/bin/env bash
#
# One-time cleanup for the ~/.claude symlink → real directory migration.
# Run this on machines where ~/.claude is a directory symlink pointing
# into the dotfiles repo (causing Claude runtime files to pollute the
# working tree).
#
# What it does:
#   1. Discards unstaged drift in home/.claude/settings.json
#   2. Runs dotty update (pulls new config, converts symlink to real dir)
#   3. Removes leftover runtime files from the repo directory

set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
CLAUDE_REPO_DIR="$DOTFILES/home/.claude"

cd "$DOTFILES"

echo "==> Discarding settings.json drift"
git checkout -- home/.claude/settings.json 2>/dev/null || true

echo "==> Running dotty update"
dotty update

echo "==> Cleaning up runtime files from repo directory"
# These are Claude Code runtime files that ended up in the repo when
# ~/.claude was a directory symlink. The .gitignore hides them from
# git, but they still take up space.
runtime_dirs=(backups debug file-history paste-cache plans plugins projects session-env statsig todos)
for dir in "${runtime_dirs[@]}"; do
    if [[ -d "$CLAUDE_REPO_DIR/$dir" ]]; then
        echo "   removing $dir/"
        rm -rf "$CLAUDE_REPO_DIR/$dir"
    fi
done

# Runtime files
for file in history.jsonl settings.json.backup settings.local.json .claude.json; do
    if [[ -f "$CLAUDE_REPO_DIR/$file" ]]; then
        echo "   removing $file"
        rm -f "$CLAUDE_REPO_DIR/$file"
    fi
done

echo "==> Done. Restart Claude Code to pick up the new settings."
