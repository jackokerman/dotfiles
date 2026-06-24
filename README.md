# Dotfiles

Personal base dotfiles managed by [dotty](https://github.com/jackokerman/dotty). This is the public, generic layer for shared defaults; local overrides and later repos in the dotty chain add machine-specific behavior.

This repo manages shell, Git, tmux, Neovim, Raycast Script Commands, Karabiner, Codex and Claude defaults, and a few small runtime checkouts under `~/.local/share/`. Tracked source lives under `home/`, and `dotty` links or renders it into `$HOME`.

## Install

Requirements for the first install are `git`, `curl`, and a POSIX shell. macOS-specific tooling is installed in the next section.

```bash
git clone https://github.com/jackokerman/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`./install.sh` bootstraps `dotty` if needed, links tracked files into `$HOME`, and runs the repo hook. It does not install Homebrew packages from `Brewfile`.

Pinned repo submodules are synced during `./install.sh` and `dotty update`. Use `git clone --recurse-submodules` if you want a fully populated checkout immediately after clone.

## New Machine

After `./install.sh`, run these steps on a fresh macOS machine.

### 1. Install tracked tools and apps

```bash
dotty run brew-sync
```

This installs packages from the tracked `Brewfile`. It does not remove untracked Homebrew packages unless you explicitly pass `--cleanup`.

### 2. Set up GitHub auth and SSH

```bash
gh auth login --web --git-protocol ssh
gh auth status
ssh -T git@github.com
```

This repo does not track `~/.ssh/`. Keep custom hosts, identities, or non-default key layouts in local SSH config or a later repo in the dotty chain.

### 3. Reapply tracked macOS setup

```bash
dotty run macos-setup
```

This applies Touch ID for `sudo`, tracked macOS defaults, Karabiner config generation, Handy settings, and font installation. If you use MonoLisa, download the Complete ZIP to `~/Downloads/`; Symbols Nerd Font is downloaded automatically.

### 4. Finish one-time GUI setup

- Grant accessibility permissions when prompted for Karabiner-Elements, AeroSpace, and Hammerspoon.
- Set Raycast's hotkey to `Cmd+Space`.
- Disable Spotlight's `Cmd+Space` shortcut in System Settings.
- Add `~/.raycast-scripts` in Raycast Preferences > Extensions > Script Commands.
- Bind the machine-specific action for `Hyper+Space` in the relevant app, local override, or later repo in the dotty chain.

After bootstrap, `dotty update` is the normal catch-up command. It refreshes the dotty chain, reruns the repo hook, syncs pinned submodules, and updates managed runtime checkouts.

## Daily Use

Most routine work starts with `dotty update`. Use the narrower commands when you only need one subsystem.

### Setup and sync

| Command | Use |
| --- | --- |
| `dotty update` | Refresh symlinks, rerun setup hooks, render generated config, sync pinned submodules, and update managed runtime checkouts. |
| `dotty run brew-sync` | Install packages from the tracked `Brewfile` on macOS. Use `dotty run brew-sync --cleanup` to remove untracked Homebrew packages. |
| `dotty run install-nvim-js-tools` | Install the minimal Bun-backed Neovim JavaScript language-server toolchain. |
| `dotty run install-gsd-core` | Install or reapply the optional pinned GSD Core integration. Use `dotty run install-gsd-core --uninstall` to remove it. |
| `dotty run macos-setup` | Reapply tracked macOS setup. After Karabiner-only changes, use `bun run scripts/ts/karabiner-config.ts` for a narrower refresh. |

### Validation

| Command | Use |
| --- | --- |
| `./scripts/check` | Run the full local validation suite. |
| `./scripts/check --staged` | Run cheap common checks plus tests selected from staged path groups. |
| `./scripts/check-prose.sh` | Run advisory prose checks for `README.md` and top-level docs. |
| `./scripts/install-git-hooks.sh` | Install or repair repo-local Git hooks. |

After changing tracked config, run `dotty update` before testing the live setup.

## Making Changes

Edit tracked source in this repo, not the generated live output in `$HOME`. For example, change `home/.config/zsh/.zshrc` instead of `~/.config/zsh/.zshrc`, and change tracked Codex sources under `home/.codex/` or `home/.ruler/` instead of generated files under `~/.codex/`.

For local verification:

```bash
./scripts/check --staged
./scripts/check
dotty update
```

Use `./scripts/check --staged` for the fast pre-commit path, `./scripts/check` before pushing broader config or hook changes, and `dotty update` when you need the live home directory to reflect the repo state.

## Layout

| Path | Purpose |
| --- | --- |
| `home/` | Tracked source files that dotty links into `$HOME`. |
| `.dotty/` | Repo identity, commands, and the post-link hook. |
| `scripts/` | Setup, sync, and validation helpers. |
| `tests/` | Focused regression tests for repo-managed subsystems. |
| `docs/` | Deeper architecture and operational notes. |

Common places to edit:

| Concern | Edit |
| --- | --- |
| Shell | `home/.zshenv` and `home/.config/zsh/` |
| Git defaults | `home/.config/git/config`; use `~/.gitconfig.local` for machine-local overrides. |
| SSH hosts and identities | Local `~/.ssh/config` |
| Keyboard remaps | `scripts/ts/karabiner-config.ts` |
| Neovim | `home/.config/nvim/` |
| tmux and related wrappers | `home/.config/tmux/` |
| sesh defaults | `home/.config/sesh/sesh.toml`; `dotty update` renders the live `~/.config/sesh/sesh.toml` into a real `~/.config/sesh/` directory. |
| Raycast script commands | `home/.raycast-scripts/` |
| Codex and Claude tracked config | `home/.ruler/`, `home/.codex/`, and `home/.claude/` |

Keep the tracked Godspeed helper and guidance generic. Personal labels, matching rules, and smart-list definitions should be discovered or supplied at runtime.

## More Detail

- [Layout and dotty chain](docs/layout.md)
- [Shell setup](docs/shell.md)
- [Agent tooling and managed config](docs/agent-tooling.md)
- [Git prompt status legend](docs/git-prompt-status.md)
- [Godspeed keyboard shortcuts](docs/godspeed-keyboard-shortcuts.md)
