# Agent Tooling and Managed Config

## tmux and Ghostty

- `tmux` enables OSC 8 hyperlink passthrough with `terminal-features 'xterm*:hyperlinks'`
- In Ghostty inside `tmux` on macOS, use `Shift+Cmd+Click` to open links
- `home/.config/ghostty/config` keeps `mouse-shift-capture = false` so `tmux` mouse bindings and link opening stay predictable
- Use `tmux-link-test` inside `tmux` to verify hyperlink passthrough quickly

## tmux Agent Status

- Session state is rendered from files under `/tmp/tmux-agent-$(id -u)`
- Agents write `agent<TAB>state` via `~/.config/tmux/agent-status-hook.sh <working|waiting|done> <agent>`
- `home/.config/tmux/session-status-left.sh`, `home/.config/tmux/session-status.sh`, `home/.config/tmux/session-status-refresh.sh`,
  and `home/.config/tmux/agent-status-hook.sh` are stable wrappers around the active `tmux-agent-bar` checkout
- `home/.config/tmux/tmux-agent-bar-path.sh` resolves the runtime checkout in this order:
  - `TMUX_AGENT_BAR_DIR`
  - `~/.config/tmux-agent-bar/path.local`
  - `~/src/tmux-agent-bar`
- `dotty update` keeps `~/src/tmux-agent-bar` current through `.dotty/managed-checkouts.tsv`
- `home/.config/tmux/README.md` is the code-local change guide for the wrappers and runtime path model
- The status bar still redraws on tmux's normal interval, while `client-session-changed` and `client-attached` refresh the cached per-session option without forcing another nested tmux redraw
- Agent hook wrappers refresh the cached right-side option in the background and rely on tmux's normal redraw path instead of forcing a client refresh on every tool event
- The generic prompt heuristics, reconciliation rules, and source registration now live in the `tmux-agent-bar` repo
- Finished shell-only sessions are hidden once no live agent process remains
- dotfiles-side runtime path and sync tests live under `tests/tmux-agent-bar/`

## Claude

The repo hook keeps `~/.claude` as a real directory and manages tracked contents from `home/.claude/`.

- `CLAUDE.md` is symlinked into place
- tracked `hooks/`, `rules/`, and `skills/` entries are linked individually
- `settings.json` is copied so later repos can extend it without writing through into this repo
- `home/.claude/` is allowlisted for tracked config only; Claude runtime files belong in `~/.claude/`, not the repo source tree

Later repos in the dotty chain can add more entries to the same live `~/.claude/` directories.

## Codex

Tracked Codex inputs live under `home/.codex/` and `home/.ruler/`.

- `home/.ruler/AGENTS.md` is the active source for Codex instructions
- `home/.ruler/ruler.toml` selects Codex as the current Ruler target
- `home/.codex/config.toml` and `home/.codex/hooks.json` are source fragments
- `home/.codex/AGENTS.md` is still tracked as the rollback source for the old dotty-only instruction path
- `scripts/ts/sync-ruler.ts` stages `.ruler` in a temporary directory, runs Ruler there, and writes live `~/.codex/AGENTS.md` with a dotty-generated header
- `scripts/ts/sync-codex.ts` validates and syncs the remaining Codex fragments into the live `~/.codex/` directory
- tracked skills are synced into `~/.codex/skills/`
- tracked agents are synced into `~/.codex/agents/`
- pinned Codex theme reference submodules live under `home/.codex/references/`
- `scripts/ts/sync-codex-nightfly-theme.ts` regenerates the tracked `nightfly` theme from those pinned upstream files
- tracked themes are symlinked into `~/.codex/themes/`

`~/.codex` stays a real directory so Codex can keep local runtime state there. Do not edit the generated live outputs when a tracked source file exists in this repo.

Ruler-generated output is never committed. Dotty invokes Ruler only in a temporary staging root and remains the owner of the live `~/.codex/AGENTS.md` file.

## Managed checkouts

`.dotty/managed-checkouts.tsv` lists tracked public tool repos that should exist on every machine using this base layer. `dotty update` and `dotty checkouts` clone missing entries, fast-forward existing checkouts only when they are clean, on the configured branch, and still point at the configured origin URL, then run the row's configured install action when one is present. Clone and fetch paths stay non-interactive so update runs warn and skip instead of hanging on prompts.

Use this for reusable public tools that are both part of the dotfiles workflow and likely to be iterated on directly, such as lint configs, Codex-adjacent tools, or small CLIs. Keep runtime-only clones under `~/.local/share/` when the checkout is an implementation detail rather than a contribution workspace. Private, host-specific, or credential-sensitive rows belong in later repos in the dotty chain.

The manifest columns are `name`, `repo-url`, `branch`, `checkout`, `update`, and `install`. Use `dev` for the normal `~/src/<name>` checkout location. The only update policy is `fast-forward`, which skips dirty, branch-mismatched, origin-mismatched, and diverged checkouts rather than overwriting them.

Leave `install` empty for checkout-only tools. Use `repo:<relative-command>` when the tool owns its installer, and use `dotty:<relative-command>` when this repo needs to adapt the install step to the dotty environment. `repo:` actions run from the configured checkout; `dotty:` actions run from this repo.

## Codex instruction workflow

Everyday instruction workflow:

1. Edit `home/.ruler/AGENTS.md`.
2. Run `dotty update`.
3. Confirm `~/.codex/AGENTS.md` starts with `Generated by dotty from tracked Ruler instruction sources`.

Rollback workflow:

1. Edit `home/.codex/AGENTS.md` only when preparing the old dotty-only path.
2. Run `DOTTY_CODEX_RULER=0 dotty update`.
3. Confirm `~/.codex/AGENTS.md` starts with `Generated by dotty from tracked Codex instruction fragments`.

Current managed defaults also:

- enable Codex hooks
- disable commit attribution trailers
- use `approval_policy = "never"`
- use `sandbox_mode = "danger-full-access"`

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
- runs `tmux-agent-bar` runtime path and sync tests
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
