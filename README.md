# Dotfiles

Personal base dotfiles managed by [dotty](https://github.com/jackokerman/dotty). This is the public, generic layer for shared defaults; local overrides and later repos in the dotty chain add machine-specific behavior.

This repo manages shell, Git, tmux, Neovim, Raycast Script Commands, Karabiner, Codex and Claude defaults, a few small runtime checkouts under `~/.local/share/`, and selected development checkouts under `~/src`. Tracked source lives under `home/`, and `dotty` links or renders it into `$HOME`.

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

This installs packages from the tracked `Brewfile`. It does not remove untracked Homebrew packages unless you explicitly pass `--cleanup`. When `dotty run brew-sync` runs with `DOTTY_ENV=personal`, the `Brewfile` also includes entries marked as personal-machine only.

### 2. Set up GitHub auth and SSH

```bash
gh auth login --web --git-protocol ssh
gh auth status
ssh -T git@github.com
```

Private HTTPS checkouts in this repo, including `jackie-plan`, rely on GitHub credentials being available to Git. After `dotty update`, the tracked Git config routes GitHub HTTPS through `gh auth git-credential`. If you want that wiring before the first successful `dotty update`, run `gh auth setup-git`.

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

After bootstrap, `dotty update` is the normal catch-up command. It refreshes the dotty chain, reruns the repo hook, syncs pinned submodules, ensures selected `~/src` development checkouts exist, updates runtime-only managed checkouts, and installs Jackie Plan from `~/src/jackie-plan`.

## Daily Use

Most routine work starts with `dotty update`. Use the narrower commands when you only need one subsystem.

### Setup and sync

| Command | Use |
| --- | --- |
| `dotty update` | Refresh symlinks, rerun setup hooks, render generated config, sync pinned submodules, ensure selected `~/src` development checkouts exist, and update runtime-only managed checkouts. |
| `dotty run brew-sync` | Install packages from the tracked `Brewfile` on macOS. Includes personal-only entries when `DOTTY_ENV=personal`; use `--cleanup` to remove untracked Homebrew packages. |
| `dotty run install-nvim-js-tools` | Install the minimal Bun-backed Neovim JavaScript language-server toolchain. |
| `dotty run macos-setup` | Reapply tracked macOS setup. After Karabiner-only changes, use `bun run scripts/ts/karabiner-config.ts` for a narrower refresh. |
| `dotty run sync-dev-checkouts` | Clone or conservatively fast-forward tracked development repos listed in `.dotty/dev-checkouts.tsv` under `~/src`. Private entries rely on your machine GitHub auth. |

### Validation

| Command | Use |
| --- | --- |
| `./scripts/check --quiet` | Run the default core validation lane with pass/fail phase summaries. |
| `./scripts/check --extended --quiet` | Run core checks plus helper and integration regressions. |
| `./scripts/check --staged --quiet` | Run cheap common checks plus tests selected from staged path groups with hook-style output. |
| `./scripts/check-prose.sh` | Run advisory Markdown prose-density checks for `README.md` and top-level docs. |
| `./scripts/install-git-hooks.sh` | Install or repair repo-local Git hooks. |

After changing tracked config, run `dotty update` before testing the live setup.

## Making Changes

Edit tracked source in this repo, not the generated live output in `$HOME`. For example, change `home/.config/zsh/.zshrc` instead of `~/.config/zsh/.zshrc`, and change tracked Codex sources under `home/.codex/` or `home/.ruler/` instead of generated files under `~/.codex/`.

For local verification:

```bash
./scripts/check --staged --quiet
./scripts/check --quiet
dotty update
```

Use `./scripts/check --staged --quiet` for the fast pre-commit path, `./scripts/check --quiet` for routine broad validation, `./scripts/check --extended --quiet` when helper or integration regressions are relevant, and `dotty update` when you need the live home directory to reflect the repo state.

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
| Glow markdown rendering | `home/.config/glow/nightfly.json`; `dotty update` renders the live `~/.config/glow/glow.yml` with an absolute style path. |
| SSH hosts and identities | Local `~/.ssh/config` |
| Keyboard remaps | `scripts/ts/karabiner-config.ts` |
| Neovim | `home/.config/nvim/` |
| tmux and related wrappers | `home/.config/tmux/` |
| sesh defaults | `home/.config/sesh/sesh.toml`; `dotty update` renders the live `~/.config/sesh/sesh.toml` into a real `~/.config/sesh/` directory. |
| Raycast script commands | `home/.raycast-scripts/` |
| Codex and Claude tracked config | `home/.ruler/`, `home/.codex/`, and `home/.claude/` |
| Public development checkouts | `.dotty/dev-checkouts.tsv` |

Keep the tracked Godspeed helper and guidance generic. Personal labels, matching rules, and smart-list definitions should be discovered or supplied at runtime.

## More Detail

- [Layout and dotty chain](docs/layout.md)
- [Shell setup](docs/shell.md)
- [Agent tooling and managed config](docs/agent-tooling.md)
- [Git prompt status legend](docs/git-prompt-status.md)
- [Godspeed keyboard shortcuts](docs/godspeed-keyboard-shortcuts.md)
