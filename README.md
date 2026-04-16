# Dotfiles

Personal base dotfiles managed by [dotty](https://github.com/jackokerman/dotty). This repo is the public, generic layer; work-specific behavior lives in overlay repos.

## Install

```bash
git clone https://github.com/jackokerman/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```

`./install.sh` bootstraps `dotty` if needed, links tracked files into `$HOME`, and runs the repo hook.

If you use MonoLisa, download the Complete ZIP to `~/Downloads/` before or after install. `scripts/install-fonts.sh` will install it the next time the hook runs. Symbols Nerd Font is downloaded automatically.

## Daily Use

```bash
dotty update
./scripts/check
./scripts/install-git-hooks.sh
```

- `dotty update` refreshes symlinks and reruns setup hooks.
- `./scripts/check` runs the fast local validation path for this repo, including tmux agent status regression tests.
- `./scripts/install-git-hooks.sh` installs the repo-local pre-commit hook.
- After changing tracked config, run `dotty update` before testing the live setup.

Temporary bypass for the repo-local pre-commit hook:

```bash
SKIP_DOTFILES_CHECK=1 git commit -m "..."
```

`SKIP_CODEX_SYNC_VALIDATE=1` is still accepted as a legacy alias.

## Repo Map

- `home/`: tracked source files that dotty links into `$HOME`
- `.dotty/`: repo identity and post-link hook
- `scripts/`: setup, sync, and validation helpers
- `docs/layout.md`: layout, overlays, and source/runtime boundaries
- `docs/agent-tooling.md`: tmux, Codex, and Claude operational notes

## Where To Change Things

- Shell: `home/.zshenv` and `home/.config/zsh/`
- Git, tmux, Ghostty, AeroSpace, Hammerspoon: `home/.config/`
- Codex and Claude: `home/.codex/` and `home/.claude/`
- Install/update behavior: `install.sh`, `.dotty/run.sh`, `scripts/`, and `Brewfile`

Reusable generic Codex frontend guidance belongs under `home/.codex/skills/` and stays split by concern: `react-patterns`, `typescript-style`, and `css-layout`.

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
