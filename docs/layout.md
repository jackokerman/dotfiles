# Layout and Dotty Chain

## Core Model

`home/` is the source of truth for files that should appear in `$HOME`.

Examples:

- `home/.zshenv` becomes `~/.zshenv`
- `home/.config/git/config` becomes `~/.config/git/config`
- `home/.codex/config.toml` is a tracked source input that the repo hook syncs into the live `~/.codex/config.toml`

If you want a tracked file at `~/.config/foo/bar`, put it at `home/.config/foo/bar`.

## Dotty Chain

This repo is the base layer:

```bash
DOTTY_NAME="dotfiles"
DOTTY_EXTENDS=()
```

Additional repos can extend the base with their own `DOTTY_EXTENDS` entry. Dotty processes the chain base-first so later repos can add or override files without rewriting the base.

`dotty` commands you will actually use here:

- `dotty install <path-or-url>`: install or register a repo chain and run hooks
- `dotty update [name]`: refresh links, pull updates, and rerun hooks
- `dotty commands`: list repo-defined commands from `.dotty/commands/`
- `dotty run <name> [args]`: execute a repo-defined command from the active chain
- `dotty link [name]`: relink without pulling or rerunning hooks
- `dotty status`: inspect the current chain and environment detection

## Local Overrides

Tracked shared config should stay generic. Machine- or environment-specific values belong in local override files or later repos in the dotty chain.

Current conventions:

- shared Git defaults in `~/.config/git/config`
- `~/.gitconfig.local` for machine-specific git config
- `~/.zshenv.local` for env vars and path tweaks
- `~/.zshrc.pre.local` for pre-`compinit` shell init such as completion path setup
- `~/.zshrc.local` for interactive shell overrides
- later repos in the dotty chain for machine-family-specific behavior

For Git config changes in this setup, use `git config-shared`, `git config-local`, or explicit `git config --file ...`. Avoid `git config --global`, which writes unmanaged `~/.gitconfig`.

`~/.zshenv` is the only top-level zsh bootstrap in this layout. It sets `ZDOTDIR=~/.config/zsh` and hands off to the tracked config there. Base `dotfiles` intentionally does not source a real `~/.zshrc`.

## Source vs Runtime State

Keep the boundary strict:

- tracked config lives in `home/`
- runtime state lives in XDG state/cache directories or app-managed directories
- ignored files inside the repo are still a smell if the live config points at them

Current zsh runtime paths:

- history: `~/.local/state/zsh/history`
- compdump: `~/.cache/zsh/.zcompdump`
- completion cache: `~/.cache/zsh/.zcompcache/`
- local shell session files: disabled

The reason for this split is simple: dotty may link tracked paths directly into the live home directory, so writing mutable state into repo-backed config paths causes the repo clone to behave like application storage.

## Real Directories With Managed Contents

Some tools need their home directories to stay writable at runtime.

- `~/.claude` stays a real directory; tracked config is linked or copied into it by the repo hook
- `~/.codex` stays a real directory; tracked fragments are synced into managed outputs by the repo hook

Do not edit generated runtime outputs in those live directories when there is a tracked source input in this repo.
