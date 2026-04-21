# dotfiles

This repo is the public base layer for generic personal dotfiles and reusable Codex defaults. Repo-root `AGENTS.md` is the canonical repo-specific instruction file, and repo-root `CLAUDE.md` is a compatibility symlink to it.

## Routing

- Keep work-only behavior out of this repo. Route company-specific Codex rules, permissions, and tooling to the private overlay repo.
- Keep changes concrete and incremental so the generated `~/.codex` state remains easy to understand.

## Workflow

- In this repo, changes are not done until they are committed and pushed to `main` with a conventional commit.
- Use `./scripts/sync-machine` when catching a machine up to the repo state, especially if `Brewfile` changed.
- Run `dotty update` after tracked config changes so the live home directory reflects the repo state.
- Run `./scripts/check` before commit. It includes tmux agent status regression tests. Repo-local Git hooks auto-install on `dotty install` and `dotty update`; use `./scripts/install-git-hooks.sh` to repair them manually.
- The shared Codex validation path also checks tracked skill UI metadata and overlay frontend workflow manifests when they are present in the dotty chain.
- If a change affects setup, commands, or configuration architecture, update `README.md` and `AGENTS.md` in the same change.
- For Git config changes in this setup, use `git config-shared`, `git config-local`, or `git config --file ...`, not `git config --global`.

## tmux Agent Status

- Read `home/.config/tmux/README.md` before making tmux agent-status changes.
- Keep generic parser, collector, and renderer behavior in this repo; overlays should extend through `~/.config/tmux/session-status-overlay.sh`.
- Changes to prompt heuristics, state reconciliation, duplicate suppression, or overlay contract must add or update tmux regression tests.
- Do not change tmux agent-status behavior without running `./scripts/check`.

## Mental Model

- `home/` is tracked source that dotty links into `$HOME`.
- `.dotty/run.sh` is the post-link hook for repo-managed setup work.
- `scripts/` contains setup, sync, and validation helpers.
- `home/.config/zsh/.zshrc` owns interactive completion discovery; user-installed completions live under `~/.local/share/zsh/site-functions`, and Homebrew completions under `/opt/homebrew/share/zsh/site-functions`.
- The generic tmux agent-status collector and renderer live here; overlays may extend them through `~/.config/tmux/session-status-overlay.sh` instead of patching the base renderer directly.
- Put generic always-on Codex behavior, including simplicity and anti-overengineering guidance, in `home/.codex/AGENTS.md`.
- Keep reusable generic Codex skills in `home/.codex/skills/`, and split them by concern (`writing-style`, `react-patterns`, `typescript-style`, `css-layout`) so skill loading stays targeted.
- Keep tracked Codex skills on the standard `SKILL.md` plus `agents/openai.yaml` layout so UI metadata and validation stay consistent across overlays.

Tracked config belongs under `home/`. Mutable runtime state does not. Do not add shell history, completion caches, app session files, or similar runtime artifacts to the repo-backed tree.

## Reference Docs

- [README.md](README.md) for install, daily commands, and the public repo map
- [docs/layout.md](docs/layout.md) for overlays, local overrides, and source/runtime boundaries
- [docs/agent-tooling.md](docs/agent-tooling.md) for tmux, Codex, and Claude operational details
- [docs/git-prompt-status.md](docs/git-prompt-status.md) for the Powerlevel10k git status legend and cleanup guidance
