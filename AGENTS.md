# dotfiles

This repo is the public base layer for generic personal dotfiles and reusable Codex defaults. Repo-root `AGENTS.md` is the canonical repo-specific instruction file, and repo-root `CLAUDE.md` is a compatibility symlink to it.

## Routing

- Keep private or machine-specific behavior out of this repo. Put it in local overrides or another repo in the dotty chain.
- When editing public prose in this repo, keep terminology generic. Avoid employer-specific product names, environment names, internal links, or private repo structure; describe them as `local overrides`, `later repos in the dotty chain`, or `host-specific setup` instead.
- If a public-repo sensitive-content guard blocks a commit, treat it as a routing failure. Do not sanitize private or host-specific content just to land it publicly; move the artifact to the appropriate later repo unless the user explicitly wants a generic public version.
- Keep changes concrete and incremental so the generated `~/.codex` state remains easy to understand.

## Workflow

- In this repo, changes are not done until they are committed and pushed to `main` with a conventional commit.
- Use `dotty update` when catching a machine up to the repo state. Use `dotty run brew-sync` when you want to reconcile tracked Homebrew packages on macOS, and `dotty run macos-setup` when you want to reapply tracked macOS defaults and related setup.
- Run `dotty update` after tracked config changes so the live home directory reflects the repo state.
- Run `./scripts/check` before commit. It includes `tmux-agent-bar` and `tuicr` managed-checkout tests. Repo-local Git hooks auto-install on `dotty install` and `dotty update`; use `./scripts/install-git-hooks.sh` to repair them manually.
- The shared Codex validation path also checks tracked skill UI metadata and extra frontend workflow manifests when they are present in the active dotty chain.
- If a change affects setup, commands, or configuration architecture, update `README.md` and `AGENTS.md` in the same change.
- For Git config changes in this setup, use `git config-shared`, `git config-local`, or `git config --file ...`, not `git config --global`.

## tmux Agent Status

- Read `home/.config/tmux/README.md` before making tmux agent-status changes.
- Keep generic parser, collector, renderer, prompt heuristics, and source registration in the external `tmux-agent-bar` repo, not in this repo.
- Use this repo for `tmux-agent-bar` checkout management, wrapper stability, and runtime path resolution only.
- Preserve the tmux-expanded session target flow from `tmux.conf` into the wrappers so `#()` jobs do not reuse stale output after a session switch.
- Keep wrapper and sync tests behavior-first. Assert path precedence, wrapper exec behavior, and safe update behavior instead of helper boundaries.
- When a tmux status bug comes from a real session, reduce it to the smallest reproducer in `tmux-agent-bar`; only add a dotfiles test when the bug is specifically about wrapper or checkout behavior.
- Do not change tmux agent-status behavior without running `./scripts/check`.

## Mental Model

- `home/` is tracked source that dotty links into `$HOME`.
- `.dotty/run.sh` is the post-link hook for repo-managed setup work.
- `scripts/` contains setup, sync, and validation helpers.
- `tests/tmux-agent-bar/` holds the wrapper and sync tests for the managed `tmux-agent-bar` runtime.
- `tests/tuicr/` holds the managed-checkout tests for the dotty-owned `tuicr` runtime clone.
- `home/.zshenv` is the only top-level zsh bootstrap. It sets `ZDOTDIR=~/.config/zsh`, and `home/.config/zsh/.zshrc` owns interactive completion discovery and the shared shell startup flow.
- Use `~/.zshrc.pre.local` for pre-`compinit` shell init and `~/.zshrc.local` for post-`compinit` interactive overrides. Do not reintroduce a tracked dependency on a real `~/.zshrc`.
- Later repos that need Powerlevel10k changes before `home/.config/zsh/.p10k.zsh` loads should set the generic `DOTFILES_P10K_LEFT_PROMPT_ELEMENTS_OVERRIDE` array or `DOTFILES_P10K_DISABLE_GITSTATUS=true` in `~/.zshrc.pre.local` instead of writing `POWERLEVEL9K_*` directly.
- User-installed completions live under `~/.local/share/zsh/site-functions`, and Homebrew completions under `/opt/homebrew/share/zsh/site-functions`.
- Keep the generic sesh picker and one-shot launcher helpers in `home/.local/bin/`; session definitions that use them belong in the appropriate repo later in the dotty chain.
- Keep generic Raycast script commands in `home/.raycast-scripts/`. Reach for Hammerspoon only when the workflow needs an always-on hotkey, app watcher, or other resident automation.
- Keep generic NeoVim config in `home/.config/nvim/`; host-specific install logic belongs outside this repo.
- Keep generic Hunk defaults in `home/.config/hunk/`; host-specific install routing belongs in later repos in the dotty chain.
- Keep the generic frontend NeoVim baseline minimal: built-in syntax highlighting first, with small `vim.pack` additions for LSP and formatting only when they solve an immediate need.
- Keep JS repo tools such as `prettier` and `eslint` project-local by default. Repo-managed setup may install editor-facing language server binaries, but it should not replace per-project toolchains.
- The stable tmux entrypoints live in `home/.config/tmux/`, but the generic implementation lives in the managed `tmux-agent-bar` checkout under `~/.local/share/tmux-agent-bar/repo` unless a local override path is set.
- `home/.config/tmux/session-status-left.sh` owns the current-session prefix path, `session-status-refresh.sh` owns the cached visible `status-right` refresh path, `session-status.sh` remains the stable renderer wrapper, and `agent-status-hook.sh` owns explicit state writes.
- Managed runtime checkouts live under `~/.local/share/`; `tmux-agent-bar` and `tuicr` use that pattern.
- Keep dotty-owned runtime checkouts separate from manual development clones. For `tuicr`, the managed checkout at `~/.local/share/tuicr/repo` is for install/use, not for personal fork remotes or long-lived branches.
- Put generic always-on Codex behavior, including simplicity and anti-overengineering guidance, in `home/.codex/AGENTS.md`.
- Keep reusable generic Codex skills in `home/.codex/skills/`, including `codex-config-coach` for turning session friction into durable steering, `godspeed-tasks` for Godspeed inbox triage, and `nvim-config-coach` for incremental Neovim config work. Split skills by concern (`writing-style`, `react-patterns`, `typescript-style`, `css-layout`) so skill loading stays targeted.
- Keep tracked Codex skills on the standard `SKILL.md` plus `agents/openai.yaml` layout so UI metadata and validation stay consistent across the dotty chain.
- Keep pinned Codex theme reference submodules under `home/.codex/references/` and regenerate derived theme assets in `home/.codex/themes/` with `scripts/sync-codex-nightfly-theme.ts` instead of hand-editing them.

Tracked config belongs under `home/`. Mutable runtime state does not. Do not add shell history, completion caches, app session files, or similar runtime artifacts to the repo-backed tree. For Claude, treat `home/.claude/` as an allowlisted tracked-config source tree only; runtime state belongs in the live `~/.claude/` directory.

## Reference Docs

- [README.md](README.md) for install, daily commands, and the public repo map
- [docs/layout.md](docs/layout.md) for the dotty chain, local overrides, and source/runtime boundaries
- [docs/agent-tooling.md](docs/agent-tooling.md) for tmux, Codex, and Claude operational details
- [docs/git-prompt-status.md](docs/git-prompt-status.md) for the Powerlevel10k git status legend and cleanup guidance
