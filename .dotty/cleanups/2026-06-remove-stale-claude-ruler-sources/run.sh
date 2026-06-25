#!/usr/bin/env bash
set -euo pipefail

claude_dir="$HOME/.claude"

rm -f "$claude_dir/CLAUDE.md"
rm -f "$claude_dir/rules/conventional-commits.md" "$claude_dir/rules/writing-style.md"
rm -rf \
    "$claude_dir/skills/bash-style" \
    "$claude_dir/skills/claudify" \
    "$claude_dir/skills/nerd-font" \
    "$claude_dir/skills/typescript-style"
