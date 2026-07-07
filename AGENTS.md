# dotfiles

This repo is the public base layer for generic personal dotfiles and reusable Codex defaults. Repo-root `AGENTS.md` is the canonical repo-specific instruction file, and repo-root `CLAUDE.md` is a compatibility symlink to it.

## Routing

- Keep private or machine-specific behavior out of this repo. Put it in local overrides or another repo in the dotty chain.
- When editing public prose in this repo, keep terminology generic. Avoid employer-specific product names, environment names, internal links, or private repo structure; describe them as `local overrides`, `later repos in the dotty chain`, or `host-specific setup` instead.
- Treat the sensitive-content guard as a mechanical check, not a prewriting exercise. Do not spend extra analysis trying to predict whether a scoped change will pass unless the content is obviously private; run the normal check and react to an actual failure.
- If a public-repo sensitive-content guard blocks a commit, treat it as a routing failure. Do not sanitize private or host-specific content just to land it publicly; move the artifact to the appropriate later repo unless the user explicitly wants a generic public version.
- Keep changes concrete and incremental so the generated `~/.codex` state remains easy to understand.

## Workflow

- In this repo, changes are not done until they are committed and pushed to `main` with a conventional commit.
- Use `dotty update` when catching a machine up to the repo state. Use `dotty run brew-sync` when you want to install tracked Homebrew packages on macOS, and use `dotty run brew-sync --cleanup` only when you explicitly want to remove untracked Homebrew packages. Use `dotty run macos-setup` when you want to reapply tracked macOS defaults and related setup.
- Keep personal-only Homebrew entries conditional inside `Brewfile` on `HOMEBREW_DOTFILES_ENV=personal`; shell startup sets that Homebrew-preserved variable because Homebrew strips ordinary dotty env vars before evaluating Brewfiles.
- When replacing a dotty-chain config mechanism such as an env var, skip list, fallback path, or generated fragment, map the existing producer and consumer path across base, overlays, docs, and live symlinks before editing. Remove the old mechanism in the same change instead of landing a parallel control surface.
- After changing tracked Karabiner or macOS-setup sources, do not assume `dotty update` reapplies them. Run `bun run scripts/ts/karabiner-config.ts` for a narrow keyboard-remap refresh or `dotty run macos-setup` for the broader macOS setup path.
- Run `dotty update` after tracked config changes so the live home directory reflects the repo state.
- For dotty hook or generated-config changes, prefer committing the intended files before final live `dotty update` verification so Dotty does not test through an auto-stashed dirty worktree. If unrelated files are dirty, keep them unstaged and verify `git status --short` before any amend or push.
- Run `./scripts/check --quiet` for routine broad validation. Use `./scripts/check --extended --quiet` before pushing helper, integration, tmux, generated-config, or check-runner changes that warrant the extended regression lane. The repo-local pre-commit hook runs `./scripts/check --staged --quiet`, which keeps commits fast and output low by running common checks plus regression tests for staged path groups. For commit-like validation, prefer `./scripts/check --staged --quiet` and rely on the hook result instead of manually rerunning the same staged path after commit. Repo-local Git hooks auto-install on `dotty install` and `dotty update`; use `./scripts/install-git-hooks.sh` to repair them manually.
- The shared Codex validation path also checks tracked skill UI metadata and extra frontend workflow manifests when they are present in the active dotty chain.
- Keep `README.md` focused on new-machine setup and daily-use entrypoints. Push deeper architecture and subsystem detail into `docs/`.
- If a change affects setup, commands, or configuration architecture, update `README.md` and `AGENTS.md` in the same change.
- For Git config changes in this setup, use `git config-shared`, `git config-local`, or `git config --file ...`, not `git config --global`.

## tmux Agent Status

- Read `home/.config/tmux/README.md` before making tmux agent-status changes.
- Keep generic parser, collector, renderer, prompt heuristics, and source registration in the external `tmux-agent-bar` repo, not in this repo.
- Use this repo for `tmux-agent-bar` checkout management, wrapper stability, and runtime path resolution only.
- Preserve the tmux-expanded session target flow from `tmux.conf` into the wrappers so `#()` jobs do not reuse stale output after a session switch.
- Keep `status-right` event-driven. It should render cached tmux options only; do not reintroduce a polling `#()` renderer or refresher in `status-right` to fix freshness issues.
- Keep wrapper and sync tests behavior-first. Assert path precedence, wrapper exec behavior, and safe update behavior instead of helper boundaries.
- Before changing tmux status behavior, map the source of truth and trigger path first: local hook state, live pane tail, remote or later-repo source cache, cached tmux option, and the tmux hook that refreshes it. Fix the broken boundary instead of adding a special case for one visible symptom.
- When a tmux status bug comes from a real session, reduce it to the smallest reproducer in `tmux-agent-bar`; only add a dotfiles test when the bug is specifically about wrapper or checkout behavior.
- When a status regression crosses `tmux-agent-bar`, this repo, and a later dotty-chain overlay, update the paired tests/docs in every affected repo before pushing.
- Do not change tmux agent-status behavior without running `./scripts/check --extended --quiet`.

## Mental Model

- `home/` is tracked source that dotty links into `$HOME`.
- `.dotty/run.sh` is the post-link hook for repo-managed setup work.
- `scripts/` contains setup, sync, and validation helpers.
- Keep `.dotty/commands/*` as thin `dotty run` entrypoints. Put substantive reusable workflow logic under `scripts/`, and leave `.dotty/run.sh` inline logic for post-link orchestration that only makes sense inside the hook.
- `tests/tmux-agent-bar/` holds the wrapper and sync tests for the active `tmux-agent-bar` checkout.
- `tests/tuicr/` holds the managed-checkout tests for the dotty-owned `tuicr` runtime clone.
- `home/.zshenv` is the only top-level zsh bootstrap. It sets `ZDOTDIR=~/.config/zsh`, and `home/.config/zsh/.zshrc` owns interactive completion discovery and the shared shell startup flow.
- Use `~/.zshenv.local` for machine-local env vars and path tweaks, including local API tokens needed by shell-backed agent workflows, unless a specific tool documents a different secret source.
- Use `~/.zshrc.pre.local` for pre-`compinit` shell init and `~/.zshrc.local` for post-`compinit` interactive overrides. Do not reintroduce a tracked dependency on a real `~/.zshrc`.
- Later repos that need Powerlevel10k changes before `home/.config/zsh/.p10k.zsh` loads should set the generic `DOTFILES_P10K_LEFT_PROMPT_ELEMENTS_OVERRIDE` array or `DOTFILES_P10K_DISABLE_GITSTATUS=true` in `~/.zshrc.pre.local` instead of writing `POWERLEVEL9K_*` directly.
- User-installed completions live under `~/.local/share/zsh/site-functions`, and Homebrew completions under `/opt/homebrew/share/zsh/site-functions`.
- Keep the generic sesh picker and one-shot launcher helpers in `home/.local/bin/`. Keep portable sesh defaults in `home/.config/sesh/sesh.toml`; `~/.config/sesh/` stays a real directory, `~/.config/sesh/sesh.toml` is generated from tracked fragments during `dotty update`, and later repos in the dotty chain own their own session definitions.
- Treat sesh picker icons, colors, and spacing as presentation. Pass stable selection labels into connect hooks and `sesh connect`, and cover icon-prefixed rows in `tests/sesh/test-pick.sh` when changing the picker contract.
- Keep generic Raycast script commands in `home/.raycast-scripts/`. When changing Script Command metadata, output mode, or UI behavior, check Raycast's official Script Commands docs and examples first; use `fullOutput` for long-running/log-style output, `compact` or `silent` for simple last-line results, and `inline` only for dashboard/status items with `refreshTime`. Reach for Hammerspoon only when the workflow needs an always-on hotkey, app watcher, or other resident automation.
- Keep shared keyboard modifier behavior, such as generic Karabiner Hyper-key remaps, in this repo. Preserve the reserved Touch ID Magic Keyboard exception in shared remaps, and route app-specific or host-specific Hyper actions to local overrides or later repos in the dotty chain.
- When debugging local GUI automation, verify behavior through the same app runtime that owns the workflow. For Hammerspoon, prefer AppleScript or `hs.task` probes and scoped app logs over terminal-only reproduction.
- When searching logs or caches, start from known app log paths, recent timestamps, or narrow predicates. Do not run broad recursive searches over `~/Library/Logs` or cache roots unless narrower paths fail.
- Keep generic NeoVim config in `home/.config/nvim/`; host-specific install logic belongs outside this repo.
- Keep generic Hunk defaults in `home/.config/hunk/`; host-specific install routing belongs in later repos in the dotty chain.
- Keep the generic frontend NeoVim baseline minimal: built-in syntax highlighting first, with small `vim.pack` additions for LSP and formatting only when they solve an immediate need.
- Keep JS repo tools such as `prettier` and `eslint` project-local by default. Repo-managed setup may install editor-facing language server binaries, but it should not replace per-project toolchains.
- The stable tmux entrypoints live in `home/.config/tmux/`, but the generic implementation lives in the `tmux-agent-bar` checkout under `~/src/tmux-agent-bar` unless an explicit override path is set.
- `home/.config/tmux/session-status-left.sh` owns the current-session prefix path, `session-status-refresh.sh` owns the cached visible `status-right` refresh path, `session-status.sh` remains the stable renderer wrapper, and `agent-status-hook.sh` owns explicit state writes.
- Managed runtime checkouts live under `~/.local/share/` when the checkout is an implementation detail rather than a contribution workspace. `tuicr` uses that runtime-only pattern; actively developed tools such as `tmux-agent-bar` use `~/src` through `.dotty/dev-checkouts.tsv`.
- Development checkouts for reusable tools live under `~/src` and are listed in `.dotty/dev-checkouts.tsv`; `dotty update` clones missing entries and conservatively fast-forwards clean checkouts on their configured branch.
- Some tracked development checkouts are private GitHub HTTPS repos. Keep machine GitHub auth available for those clone paths, and prefer non-interactive failures over prompt-driven hooks.
- Keep dotty-owned runtime checkouts separate from manual development clones. For `tuicr`, the managed checkout at `~/.local/share/tuicr/repo` is for install/use, not for personal fork remotes or long-lived branches.
- Do not assume a dotty-managed runtime checkout under `~/.local/share/*/repo` is the right upstream contribution clone. Check for an existing development clone first; if only the managed checkout exists, ask before committing there.
- Jackie Plan is an exception to the runtime-checkout pattern: `dotty update` installs it from the normal development checkout at `~/src/jackie-plan`, and the Jackie Plan installer owns its `jp` CLI and Codex plugin installation.
- Put generic always-on Codex instruction behavior, including simplicity and anti-overengineering guidance, in `home/.ruler/AGENTS.md`. Keep `home/.codex/AGENTS.md` as the rollback source for `DOTTY_CODEX_RULER=0` while that fallback remains supported.
- Keep reusable generic Codex skills in `home/.codex/skills/`, including `codex-config-coach` for turning session friction into durable steering, `godspeed-tasks` for Godspeed inbox triage, and `nvim-config-coach` for incremental Neovim config work. Split skills by concern (`writing-style`, `react-patterns`, `typescript-style`, `css-layout`) so skill loading stays targeted.
- Keep tracked Codex skills on the standard `SKILL.md` plus `agents/openai.yaml` layout so UI metadata and validation stay consistent across the dotty chain.
- Keep pinned Codex theme reference submodules under `home/.codex/references/` and regenerate derived theme assets in `home/.codex/themes/` with `scripts/ts/sync-codex-nightfly-theme.ts` instead of hand-editing them.

Tracked config belongs under `home/`. Mutable runtime state does not. Do not add shell history, completion caches, app session files, or similar runtime artifacts to the repo-backed tree. For Claude, treat `home/.claude/` as an allowlisted tracked-config source tree only; runtime state belongs in the live `~/.claude/` directory.

## Reference Docs

- [README.md](README.md) for install, daily commands, and the public repo map
- [docs/layout.md](docs/layout.md) for the dotty chain, local overrides, and source/runtime boundaries
- [docs/agent-tooling.md](docs/agent-tooling.md) for tmux, Codex, and Claude operational details
- [docs/git-prompt-status.md](docs/git-prompt-status.md) for the Powerlevel10k git status legend and cleanup guidance
