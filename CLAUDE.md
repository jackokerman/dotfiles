# dotfiles

Public base dotfiles repo for generic personal setup. Keep work-only behavior in overlay repos, not here.

## Workflow

- Commit and push directly to `main` with conventional commits.
- Run `dotty update` after tracked config changes so the live home directory reflects the repo state.
- Run `./scripts/check` before commit. It includes tmux agent status regression tests. Install the repo-local pre-commit hook with `./scripts/install-git-hooks.sh`.

## Mental Model

- `home/` is tracked source that dotty links into `$HOME`.
- `.dotty/run.sh` is the post-link hook for repo-managed setup work.
- `scripts/` contains setup, sync, and validation helpers.

Tracked config belongs under `home/`. Mutable runtime state does not. Do not add shell history, completion caches, app session files, or similar runtime artifacts to the repo-backed tree.

## Reference Docs

- [README.md](README.md) for install, daily commands, and the public repo map
- [docs/layout.md](docs/layout.md) for overlays, local overrides, and source/runtime boundaries
- [docs/agent-tooling.md](docs/agent-tooling.md) for tmux, Codex, and Claude operational details
