# Agent Tooling and Managed Config

## tmux and Ghostty

- `tmux` enables OSC 8 hyperlink passthrough with `terminal-features 'xterm*:hyperlinks'`
- In Ghostty inside `tmux` on macOS, use `Shift+Cmd+Click` to open links
- `home/.config/ghostty/config` keeps `mouse-shift-capture = false` so `tmux` mouse bindings and link opening stay predictable
- Use `tmux-link-test` inside `tmux` to verify hyperlink passthrough quickly

## tmux Agent Status

- Session state is rendered from files under `/tmp/tmux-agent-$(id -u)`
- Agents write `agent<TAB>state` via `~/.config/tmux/agent-status-hook.sh <working|waiting|done> <agent>`
- The status bar still polls every 2 seconds, but tmux also forces an immediate refresh on `client-session-changed` and `client-attached`
- Known local `codex` and `claude` sessions still use a small pane-tail fallback to refine `working` and `waiting`
- Codex does not currently expose a dedicated public hook for "waiting for user input", so tmux infers that state from prompt text
- When a Codex prompt line includes both waiting cues and `esc to interrupt`, tmux treats it as `waiting` rather than `working`
- Finished shell-only sessions are hidden once no live agent process remains

## Claude

The repo hook keeps `~/.claude` as a real directory and manages tracked contents from `home/.claude/`.

- `CLAUDE.md` is symlinked into place
- tracked `hooks/`, `rules/`, and `skills/` entries are linked individually
- `settings.json` is copied so overlays can extend it without writing through into this repo

Overlay repos can add more entries to the same live `~/.claude/` directories.

## Codex

Tracked Codex inputs live under `home/.codex/`.

- `AGENTS.md`, `config.toml`, and `hooks.json` are source fragments
- `scripts/sync-codex.ts` validates and syncs those fragments into the live `~/.codex/` directory
- tracked skills are synced into `~/.codex/skills/`
- tracked agents are synced into `~/.codex/agents/`
- tracked themes are symlinked into `~/.codex/themes/`

`~/.codex` stays a real directory so Codex can keep local runtime state there. Do not edit the generated live outputs when a tracked source file exists in this repo.

Current managed defaults also:

- enable Codex hooks
- disable commit attribution trailers
- use `approval_policy = "never"`
- use `sandbox_mode = "danger-full-access"`

## Validation

Use `./scripts/check` as the fast local validation path. It currently:

- runs shell syntax checks for tracked bash and zsh files
- asserts that zsh runtime artifacts are not present in `home/.config/zsh`
- runs tmux agent status regression tests
- runs Codex sync validation, including tracked skill UI metadata and overlay frontend workflow manifest checks when present

To install the repo-local pre-commit hook:

```bash
./scripts/install-git-hooks.sh
```

Temporary bypass:

```bash
SKIP_DOTFILES_CHECK=1 git commit -m "..."
```

`SKIP_CODEX_SYNC_VALIDATE=1` is still supported as a legacy alias.
