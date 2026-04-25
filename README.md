# Dotfiles

Personal base dotfiles managed by [dotty](https://github.com/jackokerman/dotty). This repo is the public, generic layer for shared personal defaults.

## Install

```bash
git clone https://github.com/jackokerman/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```

`./install.sh` bootstraps `dotty` if needed, links tracked files into `$HOME`, and runs the repo hook.

Once the repo is cloned, `dotty update` is the normal catch-up command. It refreshes the dotty chain and reruns the repo hook. Use `dotty run brew-sync` when you want to reconcile tracked Homebrew packages on macOS, and `dotty run macos-setup` when you want to reapply tracked macOS defaults and related setup.

If you use MonoLisa, download the Complete ZIP to `~/Downloads/` before or after install. `dotty run macos-setup` will install it the next time you run it on macOS. Symbols Nerd Font is downloaded automatically.

## Daily Use

```bash
dotty update
dotty run brew-sync
dotty run macos-setup
./scripts/check
./scripts/install-git-hooks.sh
```

- `dotty update` refreshes symlinks and reruns setup hooks without touching Homebrew.
- `dotty run brew-sync` reconciles the tracked `Brewfile` on macOS by installing missing formulae/casks and cleaning up unmanaged ones.
- `dotty run macos-setup` reapplies the tracked macOS setup on macOS, including Touch ID for `sudo`, defaults, Karabiner config generation, and font installation.
- `./scripts/check` runs the fast local validation path for this repo, including tmux agent status regression tests.
- `./scripts/install-git-hooks.sh` installs or repairs the repo-local Git hooks. These hooks are also auto-installed during `dotty install` and `dotty update`.
- After changing tracked config, run `dotty update` before testing the live setup.

## Shell Completions

Tracked zsh config loads completions from these standard locations in interactive shells:

- `~/.local/share/zsh/site-functions` for user-installed tools such as `dotty`
- `/opt/homebrew/share/zsh/site-functions` for Homebrew-installed tools
- the bundled `zsh-users/zsh-completions` plugin for extra upstream definitions

If you install a new tool and completion is not available in the current shell yet, run:

```bash
reload-completions
```

That deletes the current `compinit` dump, rebuilds completion registration in-place, and rehashes commands.

Temporary bypass for the repo-local pre-commit hook:

```bash
SKIP_DOTFILES_CHECK=1 git commit -m "..."
```

`SKIP_CODEX_SYNC_VALIDATE=1` is still accepted as a legacy alias.

## Repo Map

- `AGENTS.md`: canonical repo-specific agent instructions for this repo (`CLAUDE.md` is a compatibility symlink)
- `home/`: tracked source files that dotty links into `$HOME`
- `.dotty/`: repo identity and post-link hook
- `.dotty/commands/`: repo-defined dotty commands such as `brew-sync` and `macos-setup`
- `scripts/`: setup, sync, and validation helpers
- `tests/`: focused regression tests for repo-managed subsystems
- `docs/layout.md`: layout, dotty chain, and source/runtime boundaries
- `docs/agent-tooling.md`: tmux, Codex, and Claude operational notes
- `docs/git-prompt-status.md`: Powerlevel10k git prompt symbol legend and cleanup guidance
- `home/.config/tmux/README.md`: code-local tmux agent-status architecture and change guide

## Where To Change Things

- Shell: `home/.zshenv` and `home/.config/zsh/`
- Sesh picker and one-shot launcher helpers: `home/.local/bin/sesh-pick` and `home/.local/bin/sesh-one-shot`
- NeoVim: `home/.config/nvim/`
- Git prompt legend in shell: run `git-prompt-help`
- Git shared defaults: `home/.config/git/config` via `git config-shared`
- Git local overrides: `~/.gitconfig.local` via `git config-local`
- Do not use `git config --global` in this setup. It writes unmanaged `~/.gitconfig`.
- tmux, Ghostty, AeroSpace, Hammerspoon: `home/.config/`
- tmux agent status entrypoints: `home/.config/tmux/session-status.sh` and `home/.config/tmux/agent-status-hook.sh`
- tmux agent status internals: `home/.config/tmux/agent-status/`
- tmux agent status tests: `tests/tmux-agent-status/`
- tmux agent status extension hook: `~/.config/tmux/session-status-overlay.sh` when you need extra collectors outside the base repo
- Codex and Claude: `home/.codex/` and `home/.claude/`
- Codex default behavior and always-on instruction bias: `home/.codex/AGENTS.md`
- Codex-only local skill tokens: `~/.codex/env.local` (for example `GODSPEED_API_TOKEN`)
- Install/update behavior: `install.sh`, `.dotty/run.sh`, `scripts/`, and `Brewfile`

Reusable generic Codex skills belong under `home/.codex/skills/`. Current shared skills include `writing-style` for drafting, `godspeed-tasks` for read-only Godspeed inbox triage, and the frontend-focused `react-patterns`, `typescript-style`, and `css-layout` skills. Tracked skills use the standard `SKILL.md` plus `agents/openai.yaml` layout, and the shared Codex validation path also checks extra frontend workflow manifests when they are present in the active dotty chain.

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

- [Layout and dotty chain](docs/layout.md)
- [Agent tooling and managed config](docs/agent-tooling.md)
- [Git prompt status legend](docs/git-prompt-status.md)
