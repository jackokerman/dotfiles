# Dotfiles

Personal base dotfiles managed by [dotty](https://github.com/jackokerman/dotty). This is the public, generic layer for shared defaults; local overrides and later repos in the dotty chain add machine-specific behavior.

This repo manages shell, Git, tmux, Neovim, Raycast Script Commands, Karabiner, Codex and Claude defaults, and selected personal devtool repos under `~/src`. Tracked source lives under `home/`, and `dotty` links or renders it into `$HOME`.

## Install

Requirements for the first install are `git`, `curl`, and a POSIX shell. Homebrew packages and macOS-specific tooling are installed in the next section.

```bash
git clone https://github.com/jackokerman/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`./install.sh` bootstraps `dotty` if needed, links tracked files into `$HOME`, and runs the repo hook. It does not install Homebrew packages from `Brewfile`.

To remove this repo's managed symlinks and restore backups that `dotty` created:

```bash
dotty uninstall dotfiles
```

Pinned repo submodules are synced during `./install.sh` and `dotty update`. Use `git clone --recurse-submodules` if you want a fully populated checkout immediately after clone.

## New machine

After `./install.sh`, run the steps that apply to the fresh host.

### 1. Install tracked Homebrew tools

```bash
dotty run brew-sync
```

This installs packages from the tracked `Brewfile` on supported Homebrew hosts, including Linuxbrew on Linux. It does not remove untracked Homebrew packages unless you explicitly pass `--cleanup`. Personal-only entries are included when `HOMEBREW_DOTFILES_ENV=personal`, which is the base shell default. Homebrew `gh` is installed only when no non-Homebrew `gh` is already available, so host-provided wrappers can own GitHub CLI behavior; use `dotty run brew-sync` for that path so the helper preserves the pre-Homebrew command path.

### 2. Set up GitHub auth and SSH

```bash
gh auth login --web --git-protocol ssh
gh auth status
ssh -T git@github.com
```

Managed checkout rows that require private GitHub credentials belong in later repos in the dotty chain. After `dotty update`, the tracked Git config routes GitHub HTTPS through `gh auth git-credential`. If you want that wiring before the first successful `dotty update`, run `gh auth setup-git`.

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

After bootstrap, `dotty update` is the normal catch-up command. It refreshes the dotty chain, syncs managed checkouts, reruns the repo hook, syncs pinned submodules, and updates generated config.

## Daily Use

Most routine work starts with `dotty update`. Use the narrower commands when you only need one subsystem.

### Setup and sync

| Command | Use |
| --- | --- |
| `dotty update` | Refresh the active chain: managed checkouts, links, hooks, generated config, submodules, and Linux `fzf`. |
| `dotty checkouts` | Clone or fast-forward clean managed checkouts from `.dotty/managed-checkouts.tsv` without re-linking dotfiles. |
| `dotty run brew-sync` | Install tracked Homebrew packages; pass `--cleanup` only when you want to remove untracked packages. |
| `dotty run install-nvim-js-tools` | Install the minimal Bun-backed Neovim JavaScript language-server toolchain. |
| `dotty run macos-setup` | Reapply Touch ID, macOS defaults, Karabiner config, Handy settings, and fonts. |

Notes:

- `brew-sync` includes personal-only entries when `HOMEBREW_DOTFILES_ENV=personal`, the base shell default.
- Use `dotty run brew-sync` instead of invoking `brew bundle` directly so the helper preserves the pre-Homebrew command path for host-provided wrappers.
- For Karabiner-only changes, use `bun --install=fallback run scripts/ts/karabiner-config.ts` instead of the full macOS setup path.
- Private managed checkout rows belong in later repos and rely on your machine GitHub auth.

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
| Shell | `home/.zshenv` and `home/.config/zsh/`. |
| Git defaults | `home/.config/git/config`; machine-local overrides in `~/.gitconfig.local`. |
| Glow markdown rendering | `home/.config/glow/nightfly.json`. |
| Television fuzzy finder | `home/.config/television/`. |
| SSH hosts and identities | Local `~/.ssh/config`. |
| Keyboard remaps | `scripts/ts/karabiner-config.ts`. |
| Neovim | `home/.config/nvim/`; see `home/.config/nvim/README.md` for the module and plugin ownership map. |
| tmux and related wrappers | `home/.config/tmux/`. |
| sesh defaults | `home/.config/sesh/sesh.toml`. |
| Raycast script commands | `home/.raycast-scripts/`. |
| Codex and Claude tracked config | `home/.ruler/`, `home/.codex/`, and `home/.claude/`. |
| Public managed checkouts | `.dotty/managed-checkouts.tsv`. |

Generated or real-directory notes:

- `dotty update` renders live Glow config, Television config and themes, and sesh config when those sources change.
- `~/.config/sesh/`, `~/.codex/`, and `~/.claude/` stay real directories so apps can write runtime state; edit tracked sources here, not generated live outputs.

Keep the tracked Godspeed helper and guidance generic. Personal labels, matching rules, and smart-list definitions should be discovered or supplied at runtime.

## More Detail

- [Layout and dotty chain](docs/layout.md)
- [Shell setup](docs/shell.md)
- [Agent tooling and managed config](docs/agent-tooling.md)
- [Vim basics in Neovim](docs/neovim-basics.md)
- [Git prompt status legend](docs/git-prompt-status.md)
- [Godspeed keyboard shortcuts](docs/godspeed-keyboard-shortcuts.md)
