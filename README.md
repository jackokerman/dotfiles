# Dotfiles

Personal base dotfiles managed by [dotty](https://github.com/jackokerman/dotty). This repo is the public, generic layer; work-specific behavior lives in overlay repos.

## Install

```bash
git clone https://github.com/jackokerman/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```

`./install.sh` bootstraps `dotty` if needed, links tracked files into `$HOME`, and runs the repo hook.

Once the repo is cloned, `./scripts/sync-machine` is the higher-level catch-up command. It falls back to `./install.sh` on a fresh machine and, on an existing machine, also applies `Brewfile` changes that plain `dotty update` skips.

If you use MonoLisa, download the Complete ZIP to `~/Downloads/` before or after install. `scripts/install-fonts.sh` will install it the next time the hook runs. Symbols Nerd Font is downloaded automatically.

## Daily Use

```bash
./scripts/sync-machine
dotty update
./scripts/check
./scripts/install-git-hooks.sh
```

- `./scripts/sync-machine` installs or updates the dotty chain and applies `Brewfile` changes. Use this on a fresh machine after cloning the repo or when an existing machine has fallen behind.
- `dotty update` refreshes symlinks and reruns setup hooks.
- `dotty update` intentionally does not install new `Brewfile` packages unless you opt in via `./scripts/sync-machine`.
- `./scripts/check` runs the fast local validation path for this repo, including tmux agent status regression tests.
- `./scripts/install-git-hooks.sh` installs or repairs the repo-local Git hooks. These hooks are also auto-installed during `dotty install` and `dotty update`.
- After changing tracked config, run `dotty update` before testing the live setup.

Temporary bypass for the repo-local pre-commit hook:

```bash
SKIP_DOTFILES_CHECK=1 git commit -m "..."
```

`SKIP_CODEX_SYNC_VALIDATE=1` is still accepted as a legacy alias.

## Repo Map

- `AGENTS.md`: canonical repo-specific agent instructions for this repo (`CLAUDE.md` is a compatibility symlink)
- `home/`: tracked source files that dotty links into `$HOME`
- `.dotty/`: repo identity and post-link hook
- `scripts/`: setup, sync, and validation helpers
- `docs/layout.md`: layout, overlays, and source/runtime boundaries
- `docs/agent-tooling.md`: tmux, Codex, and Claude operational notes
- `home/.config/tmux/README.md`: code-local tmux agent-status architecture and change guide

## Where To Change Things

- Shell: `home/.zshenv` and `home/.config/zsh/`
- Git shared defaults: `home/.config/git/config` via `git config-shared`
- Git local overrides: `~/.gitconfig.local` via `git config-local`
- Do not use `git config --global` in this setup. It writes unmanaged `~/.gitconfig`.
- tmux, Ghostty, AeroSpace, Hammerspoon: `home/.config/`
- tmux agent status core: `home/.config/tmux/agent-pane-state.sh`, `home/.config/tmux/session-status.sh`, and `home/.config/tmux/session-status-lib.sh`
- tmux agent status overlays: `~/.config/tmux/session-status-overlay.sh` from an overlay repo when environment-specific collectors are needed
- Codex and Claude: `home/.codex/` and `home/.claude/`
- Codex default behavior and always-on instruction bias: `home/.codex/AGENTS.md`
- Install/update behavior: `install.sh`, `.dotty/run.sh`, `scripts/`, and `Brewfile`

Reusable generic Codex frontend guidance belongs under `home/.codex/skills/` and stays split by concern: `react-patterns`, `typescript-style`, and `css-layout`. Tracked skills use the standard `SKILL.md` plus `agents/openai.yaml` layout, and the shared Codex validation path also checks overlay frontend workflow manifests when they are present in the dotty chain.

Mutable runtime state should not live under `home/`. Keep tracked config in the repo and runtime artifacts in XDG state/cache directories or app-managed directories.

## Post-Install Notes

Grant accessibility permissions when prompted for:

1. Karabiner-Elements
2. AeroSpace
3. Hammerspoon

Raycast still needs one-time manual setup:

1. Set the hotkey to `Cmd+Space`
2. Disable Spotlight's `Cmd+Space` shortcut in System Settings
3. Add `~/.raycast-scripts` in Raycast Preferences > Extensions > Script Commands

## More Detail

- [Layout and overlays](docs/layout.md)
- [Agent tooling and managed config](docs/agent-tooling.md)
