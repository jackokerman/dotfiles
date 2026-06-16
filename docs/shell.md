# Shell Setup

The shell entrypoint is `~/.zshenv`. It sets `ZDOTDIR=~/.config/zsh`, so the tracked interactive shell config lives under `home/.config/zsh/`.

This repo does not manage a real `~/.zshrc`. Keep host-specific shell setup in local files or in later repos in the dotty chain.

## Local Hooks

- `~/.zshenv.local` runs during shell startup. Use it for machine-local environment variables, path tweaks, and local API tokens needed by shell-backed workflows.
- `~/.zshrc.pre.local` runs before `compinit`. Use it for completion paths or shell init that must happen before completion registration.
- `~/.zshrc.local` runs after `compinit` and plugin setup. Use it for post-completion interactive shell config.

Later repos can set early Powerlevel10k overrides in `~/.zshrc.pre.local`:

```zsh
DOTFILES_P10K_LEFT_PROMPT_ELEMENTS_OVERRIDE=(...)
DOTFILES_P10K_DISABLE_GITSTATUS=true
```

## Completions

Tracked zsh config loads completions from:

- `~/.local/share/zsh/site-functions` for user-installed tools such as `dotty`.
- `/opt/homebrew/share/zsh/site-functions` for Homebrew-installed tools.
- the bundled `zsh-users/zsh-completions` plugin for extra upstream definitions.

After installing a tool, refresh completion registration in the current shell:

```bash
reload-completions
```

## Hook Bypass

Use this only for temporary local commits:

```bash
SKIP_DOTFILES_CHECK=1 git commit -m "..."
```

`SKIP_CODEX_SYNC_VALIDATE=1` is still accepted as a legacy alias.
