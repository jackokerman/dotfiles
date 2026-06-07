# Dotfiles

Personal base dotfiles managed by [dotty](https://github.com/jackokerman/dotty). This repo is the public, generic layer for shared personal defaults.

## Install

```bash
git clone https://github.com/jackokerman/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```

`./install.sh` bootstraps `dotty` if needed, links tracked files into `$HOME`, and runs the repo hook. It does not install the Homebrew packages from `Brewfile`.

Pinned repo submodules are synced during `./install.sh` and `dotty update`. If you want a fully populated checkout immediately after clone, use `git clone --recurse-submodules`.

## New Machine

After `./install.sh`, this is the setup sequence that matters on a fresh macOS machine:

1. Install the tracked tools and apps:

```bash
dotty run brew-sync
```

This installs the Homebrew-managed tools from `Brewfile`, including `gh`.

2. Set up GitHub auth and SSH:

```bash
gh auth login --web --git-protocol ssh
gh auth status
ssh -T git@github.com
```

`gh auth login --git-protocol ssh` will detect an existing SSH key and offer to create and upload one if needed. This repo no longer uses 1Password to manage SSH keys. It expects a normal machine-local SSH setup.

This repo does not track `~/.ssh/`. If you need custom hosts, extra identities, or a non-default key layout, keep that in your local `~/.ssh/config` or in a later repo in the dotty chain.

3. Reapply the tracked macOS setup:

```bash
dotty run macos-setup
```

That covers Touch ID for `sudo`, tracked macOS defaults, Karabiner config generation, and font installation.

If you use MonoLisa, download the Complete ZIP to `~/Downloads/` before or after `dotty run macos-setup`. Symbols Nerd Font is downloaded automatically.

4. Finish the one-time GUI setup:

- Grant accessibility permissions when prompted for Karabiner-Elements, AeroSpace, and Hammerspoon.
- Set Raycast's hotkey to `Cmd+Space`.
- Disable Spotlight's `Cmd+Space` shortcut in System Settings.
- Add `~/.raycast-scripts` in Raycast Preferences > Extensions > Script Commands.
- The tracked keyboard remaps keep the built-in keyboard `Caps Lock` as `Control` on hold and turn `Right Command` into a pure Hyper key (`Cmd+Ctrl+Opt+Shift`) on every keyboard except the reserved Touch ID Magic Keyboard.
- Reserve `Hyper+Space` as the shared quick-entry shortcut and bind the machine-specific action in the relevant app, local override, or later repo in the dotty chain.

Once the machine is bootstrapped, `dotty update` is the normal catch-up command. It refreshes the dotty chain, reruns the repo hook, syncs pinned submodules, and keeps managed runtime checkouts such as `~/.local/share/tuicr/repo` current.

## Daily Use

```bash
dotty update
dotty run brew-sync
dotty run install-nvim-js-tools
dotty run macos-setup
./scripts/check
./scripts/install-git-hooks.sh
```

- `dotty update` refreshes symlinks, reruns setup hooks, syncs pinned repo submodules, and updates managed runtime checkouts such as `tmux-agent-bar` and `tuicr` without touching Homebrew.
- `dotty run brew-sync` reconciles the tracked `Brewfile` on macOS by installing missing formulae/casks and cleaning up unmanaged ones, including personal-machine tools such as `hunk`.
- `dotty run install-nvim-js-tools` installs the minimal Bun-backed Neovim JS language-server toolchain used by the tracked editor config.
- `dotty run macos-setup` reapplies the tracked macOS setup on macOS, including Touch ID for `sudo`, defaults, Karabiner config generation, and font installation.
- After changing tracked Karabiner or macOS-setup sources, use `bun run scripts/karabiner-config.ts` for a narrow keyboard-remap refresh or `dotty run macos-setup` for the broader macOS setup path. `dotty update` alone does not rerun `macos-setup`.
- `./scripts/check` runs the fast local validation path for this repo, including `tmux-agent-bar` and `tuicr` managed-checkout tests.
- `./scripts/install-git-hooks.sh` installs or repairs the repo-local Git hooks. These hooks are also auto-installed during `dotty install` and `dotty update`.
- After changing tracked config, run `dotty update` before testing the live setup.

## Shell Notes

`~/.zshenv` is the only top-level zsh bootstrap in this setup. It points `ZDOTDIR` at `~/.config/zsh`, so tracked interactive shell config lives under `home/.config/zsh/` instead of a repo-managed `~/.zshrc`.

Tracked zsh config exposes three local shell hooks for later repos or machine-local overrides:

- `~/.zshenv.local` runs during shell startup and is the right place for machine-local env vars and path tweaks, including local API tokens needed by shell-backed agent workflows.

- `~/.zshrc.pre.local` runs before `compinit` and is the right place to add completion paths or source shell init that needs to run before completion registration.
- `~/.zshrc.local` runs after `compinit` and plugin setup and is the right place for post-completion interactive shell config.

`~/.zshrc.pre.local` is also where later repos should set early Powerlevel10k overrides that must land before `~/.config/zsh/.p10k.zsh` loads. The supported generic hooks are `DOTFILES_P10K_LEFT_PROMPT_ELEMENTS_OVERRIDE=(...)` and `DOTFILES_P10K_DISABLE_GITSTATUS=true`.

Tracked zsh config loads completions from these standard locations in interactive shells:

- `~/.local/share/zsh/site-functions` for user-installed tools such as `dotty`
- `/opt/homebrew/share/zsh/site-functions` for Homebrew-installed tools
- the bundled `zsh-users/zsh-completions` plugin for extra upstream definitions

If you install a new tool and completion is not available in the current shell yet, run:

```bash
reload-completions
```

That rebuilds completion registration in-place and rehashes commands.

Temporary bypass for the repo-local pre-commit hook:

```bash
SKIP_DOTFILES_CHECK=1 git commit -m "..."
```

`SKIP_CODEX_SYNC_VALIDATE=1` is still accepted as a legacy alias.

## Layout

- `home/` contains tracked source files that dotty links into `$HOME`.
- `.dotty/` contains repo identity, commands, and the post-link hook.
- `scripts/` contains setup, sync, and validation helpers.
- `tests/` contains focused regression tests for repo-managed subsystems.
- `docs/` contains deeper architecture and operational notes.

Common places to edit:

- Shell: `home/.zshenv` and `home/.config/zsh/`
- Git defaults: `home/.config/git/config`, plus `~/.gitconfig.local` for machine-local overrides
- SSH host and identity config: local `~/.ssh/config`
- Keyboard remaps: `scripts/karabiner-config.ts`
- NeoVim: `home/.config/nvim/`
- tmux and related wrappers: `home/.config/tmux/`
- Raycast script commands: `home/.raycast-scripts/`
- Codex and Claude tracked config: `home/.codex/` and `home/.claude/`

## More Detail

- [Layout and dotty chain](docs/layout.md)
- [Agent tooling and managed config](docs/agent-tooling.md)
- [Git prompt status legend](docs/git-prompt-status.md)
