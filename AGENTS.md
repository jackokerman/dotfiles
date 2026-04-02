# dotfiles

This repo owns generic personal dotfiles and reusable Codex defaults.

- Keep work-only behavior out of this repo. Route company-specific Codex rules, permissions, and tooling to the private overlay repo.
- Keep changes concrete and incremental so the generated `~/.codex` state remains easy to understand.
- In this repo, changes are not done until they are committed and pushed to `main` with a conventional commit.
- If a change affects setup, commands, or configuration architecture, update `README.md` and `CLAUDE.md` in the same change.
