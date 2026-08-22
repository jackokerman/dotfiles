# Agent Tooling and Managed Config

## tmux and Ghostty

- `tmux` enables OSC 8 hyperlink passthrough with `terminal-features 'xterm*:hyperlinks'`
- In Ghostty inside `tmux` on macOS, use `Shift+Cmd+Click` to open links
- `home/.config/ghostty/config` keeps `mouse-shift-capture = false` so `tmux` mouse bindings and link opening stay predictable
- Use `tmux-link-test` inside `tmux` to verify hyperlink passthrough quickly

## Fleet agent dashboard

Fleet is the agent dashboard for tmux. Homebrew owns the executable through the personal-only `nicknisi/formulae/fleet` entry, while this repo owns the reviewed integration:

- `home/.config/tmux/tmux.conf` binds `prefix` + `F` to the 55% by 60% dashboard popup, binds `prefix` + `f` to the native 34-column sidebar, and injects Fleet's attention-only second status row after Nightfly loads. The row always shows its sidebar button and adds agents only when they need permission, have a question, or are ready for review.
- `home/.config/fleet/theme.toml` provides the Nightfly agent-state palette.
- `.dotty/run.sh` runs `fleet install` and `fleet install codex` non-interactively when Fleet and the corresponding agent CLI are available.
- `home/.claude/settings.json` preserves Fleet's enabled plugin entry and the unrelated conventional-commit validation hook.
- `home/.codex/hooks.json` keeps only Fleet's supported `PreToolUse` and `Stop` hooks through the upgrade-stable plugin link. `home/.codex/config.toml` enables hooks.

Fleet's native installers own the mutable Claude marketplace registration, plugin links, status directories, and agent registry. Run `fleet doctor` after setup, and see `home/.config/tmux/README.md` for isolated tmux verification.

## Sesh session picker

`Alt+S` opens `sesh-pick` in a popup inside tmux and runs the picker directly in the current terminal outside tmux. Tmux popups require an attached tmux client. Inside tmux, `Ctrl+T` also opens the popup directly.

## Sesh one-shot launchers

`sesh-one-shot` runs a configured launcher command and invalidates sesh's tmux-session cache when the command exits. Later repos in the dotty chain can opt a repeatable launcher into numbered tmux sessions without changing `sesh-pick`:

```bash
exec sesh-one-shot --numbered-session 'Scratch {n}' -- scratch-session
```

The name template must contain exactly one `{n}`. Inside tmux, the wrapper renames the newly created configured session to the lowest available positive number before starting the child. Tmux session names remain the uniqueness boundary; the wrapper does not keep a counter or lock file. It invalidates the sesh cache immediately after the rename and again when the child exits. Unnumbered launchers keep the existing `sesh-one-shot <command> [args...]` form.

## Claude

The repo hook keeps `~/.claude` as a real directory and manages tracked contents from `home/.claude/`.

- `CLAUDE.md` is symlinked into place
- tracked `hooks/`, `rules/`, and `skills/` entries are linked individually
- `settings.json` is copied so later repos can extend it without writing through into this repo
- `home/.claude/` is allowlisted for tracked config only; Claude runtime files belong in `~/.claude/`, not the repo source tree

Later repos in the dotty chain can add more entries to the same live `~/.claude/` directories.

## Codex

Tracked Codex inputs live under `home/.codex/`.

- `home/.codex/AGENTS.md`, `home/.codex/config.toml`, and `home/.codex/hooks.json` are source fragments
- `scripts/ts/sync-codex.ts` validates and syncs Codex fragments into the live `~/.codex/` directory
- tracked skills are synced into `~/.codex/skills/`
- tracked agents are synced into `~/.codex/agents/`
- pinned Codex theme reference submodules live under `home/.codex/references/`
- `scripts/ts/sync-codex-nightfly-theme.ts` regenerates the tracked `nightfly` theme from those pinned upstream files
- tracked themes are symlinked into `~/.codex/themes/`

`~/.codex` stays a real directory so Codex can keep local runtime state there. Do not edit the generated live outputs when a tracked source file exists in this repo.

## Managed checkouts

`.dotty/managed-checkouts.tsv` lists tracked public tool repos that should exist on every machine using this base layer. `dotty update` and `dotty checkouts` clone missing entries, fast-forward existing checkouts only when they are clean, on the configured branch, and still point at the configured origin URL, then run the row's configured install action when one is present. Clone and fetch paths stay non-interactive so update runs warn and skip instead of hanging on prompts.

Use this for reusable public tools that are both part of the dotfiles workflow and likely to be iterated on directly, such as lint configs, Codex-adjacent tools, or small CLIs. Keep runtime-only clones under `~/.local/share/` when the checkout is an implementation detail rather than a contribution workspace. Private, host-specific, or credential-sensitive rows belong in later repos in the dotty chain.

The manifest columns are `name`, `repo-url`, `branch`, `checkout`, `update`, and `install`. Use `dev` for the normal `~/src/<name>` checkout location. The only update policy is `fast-forward`, which skips dirty, branch-mismatched, origin-mismatched, and diverged checkouts rather than overwriting them.

Leave `install` empty for checkout-only tools. Use `repo:<relative-command>` when the tool owns its installer, and use `dotty:<relative-command>` when this repo needs to adapt the install step to the dotty environment. `repo:` actions run from the configured checkout; `dotty:` actions run from this repo.

## Codex instruction workflow

Everyday instruction workflow:

1. Edit `home/.codex/AGENTS.md`.
2. Run `dotty update`.
3. Confirm `~/.codex/AGENTS.md` starts with `Generated by dotty from tracked Codex instruction fragments`.

Current managed defaults also:

- use `gpt-5.6-sol` with medium reasoning as the personal default model
- enable Codex hooks
- disable commit attribution trailers
- use `approval_policy = "never"`
- use `sandbox_mode = "danger-full-access"`

Keep durable local defaults such as `model` and `model_reasoning_effort` in the tracked `home/.codex/config.toml`. A later dotty-chain repo can override the same keys for a work machine, even when both layers happen to use the same values today. The desktop app, CLI, and IDE share the generated `~/.codex/config.toml`; a setting changed through one of those local surfaces remains a local experiment until it is promoted to the owning tracked fragment, and a later `dotty update` restores tracked values. Codex cloud chats use the model selected in their composer and do not currently support a configurable default model.

For GitHub operations, local agents rely on your machine auth. On a new machine, install the tracked tools first with `dotty run brew-sync`, then run:

```bash
gh auth login --web --git-protocol ssh
gh auth status
ssh -T git@github.com
```

`gh auth login` uses a browser-based flow by default and stores credentials in the system keychain when available. With `--git-protocol ssh`, it will detect an existing SSH key and prompt to create and upload one if needed.

This repo no longer routes SSH through 1Password. It expects a normal machine-local SSH key setup, and it does not track `~/.ssh/`.

After a successful `dotty update`, the tracked Git config already uses `gh auth git-credential` for GitHub HTTPS, so `gh auth setup-git` is usually only useful before the first successful `dotty update` or when bootstrapping a machine by hand.

## Validation

Use `./scripts/check` as the fast local validation path. It currently:

- runs shell syntax checks for tracked bash and zsh files
- asserts that zsh runtime artifacts are not present in `home/.config/zsh`
- runs Codex hook and sync validation
- runs Codex sync validation, including tracked skill UI metadata and extra frontend workflow manifest checks when present

To install the repo-local pre-commit hook:

```bash
./scripts/install-git-hooks.sh
```

Temporary bypass:

```bash
SKIP_DOTFILES_CHECK=1 git commit -m "..."
```

`SKIP_CODEX_SYNC_VALIDATE=1` is still supported as a legacy alias.
