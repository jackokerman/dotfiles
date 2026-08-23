# dotfiles

This repo is the public base layer for generic personal dotfiles and reusable Codex defaults. Repo-root `AGENTS.md` is the canonical repo-specific instruction file, and repo-root `CLAUDE.md` is a compatibility symlink to it.

## Routing

- Keep private or machine-specific behavior out of this repo. Put it in local overrides or another repo in the dotty chain.
- When editing public prose in this repo, keep terminology generic. Avoid employer-specific product names, environment names, internal links, or private repo structure; describe them as `local overrides`, `later repos in the dotty chain`, or `host-specific setup` instead.
- Treat the sensitive-content guard as a mechanical check. If it blocks a commit, route the artifact to the appropriate later repo instead of sanitizing private or host-specific content to make it public.

## Workflow

- In this repo, changes are not done until they are committed and pushed to `main` with a conventional commit.
- When replacing a dotty-chain config mechanism such as an env var, skip list, fallback path, or generated fragment, map the existing producer and consumer path across base, overlays, docs, and live symlinks before editing. Remove the old mechanism in the same change instead of landing a parallel control surface.
- Run `dotty update` after tracked config changes so the live home directory reflects the repo state.
- For dotty hook or generated-config changes, prefer committing the intended files before final live `dotty update` verification so Dotty does not test through an auto-stashed dirty worktree. If unrelated files are dirty, keep them unstaged and verify `git status --short` before any amend or push.
- Run `./scripts/check --quiet` for routine broad validation and `./scripts/check --extended --quiet` for helper, integration, tmux, generated-config, or check-runner changes. The pre-commit hook owns staged-path validation; do not duplicate it manually.
- Do not add or keep tests by default for personal glue. Keep tests only when they guard generated config, fragile shell parsing, cross-repo or multi-machine sync, destructive behavior, a repeated regression, or a reusable CLI/library contract. Do not test skill prose, docs strings, prompt wording, picker labels, icons, or display text unless that text is a documented external contract.
- Keep `README.md` focused on new-machine setup and daily-use entrypoints. Push deeper architecture and subsystem detail into `docs/`.
- Update user-facing documentation when setup, commands, configuration, layout, or workflows change. Update `AGENTS.md` only when durable agent routing, ownership, safety, or verification guidance changes.
- For Git config changes in this setup, use `git config-shared`, `git config-local`, or `git config --file ...`, not `git config --global`.

## tmux Agent Status

- Read `home/.config/tmux/README.md` and `docs/agent-tooling.md` before making tmux agent-status changes.
- Test tmux config changes on an explicit isolated socket. Never kill the default tmux server during diagnostics.
- Do not change tmux agent-status behavior without running `./scripts/check --extended --quiet`.

## Source and Subsystem Routing

- Tracked config belongs under `home/`; mutable runtime state does not. Edit tracked sources instead of generated live files.
- `.dotty/run.sh` owns post-link orchestration, while `scripts/` owns reusable setup, sync, and validation helpers.
- Keep `.dotty/commands/*` as thin `dotty run` entrypoints. Put substantive reusable workflow logic under `scripts/`, and leave `.dotty/run.sh` inline logic for post-link orchestration that only makes sense inside the hook.
- Read `docs/shell.md` before changing zsh bootstrap, local hooks, prompt overrides, or completion discovery.
- Keep generic sesh helpers and defaults in this repo, and session definitions in the appropriate dotty-chain layer.
- Treat sesh picker icons, colors, and spacing as presentation. Pass stable selection labels into connect hooks and `sesh connect`; prefer direct picker verification over new tests unless the stable label boundary regresses again.
- Keep generic Raycast Script Commands in `home/.raycast-scripts/`, verify behavior against Raycast's official documentation, and use Hammerspoon only for resident automation.
- Keep shared keyboard modifier behavior, such as generic Karabiner Hyper-key remaps, in this repo. Preserve the reserved Touch ID Magic Keyboard exception in shared remaps, and route app-specific or host-specific Hyper actions to local overrides or later repos in the dotty chain.
- When debugging local GUI automation, verify behavior through the same app runtime that owns the workflow. For Hammerspoon, prefer AppleScript or `hs.task` probes and scoped app logs over terminal-only reproduction.
- When searching logs or caches, start from known app log paths, recent timestamps, or narrow predicates. Do not run broad recursive searches over `~/Library/Logs` or cache roots unless narrower paths fail.
- Keep generic NeoVim config in `home/.config/nvim/`; read `home/.config/nvim/README.md` before changing its module or plugin ownership structure, and keep host-specific install logic outside this repo.
- Keep install routing for broadly available CLI tools in the tracked `Brewfile` or later repos in the dotty chain.
- Read `docs/agent-tooling.md` before changing managed-checkout ownership or update behavior.
- Private, host-specific, or credential-sensitive managed checkout rows belong in later repos in the dotty chain, not this public base repo.
- Do not assume a dotty-managed runtime checkout under `~/.local/share/*/repo` is the right upstream contribution clone. Check for an existing development clone first; if only the managed checkout exists, ask before committing there.
- Put generic always-on Codex instruction behavior, including simplicity and anti-overengineering guidance, in `home/.codex/AGENTS.md`.
- Keep reusable generic Codex skills in `home/.codex/skills/` and split them by concern so loading stays targeted.
- Keep tracked Codex skills on the standard `SKILL.md` plus `agents/openai.yaml` layout so UI metadata and validation stay consistent across the dotty chain.

## Reference Docs

- [README.md](README.md) for install, daily commands, and the public repo map
- [docs/layout.md](docs/layout.md) for the dotty chain, local overrides, and source/runtime boundaries
- [docs/shell.md](docs/shell.md) for zsh bootstrap, local hooks, and completions
- [docs/agent-tooling.md](docs/agent-tooling.md) for tmux, Codex, and Claude operational details
- [docs/git-prompt-status.md](docs/git-prompt-status.md) for the Powerlevel10k git status legend and cleanup guidance
