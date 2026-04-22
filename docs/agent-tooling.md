# Agent Tooling and Managed Config

## tmux and Ghostty

- `tmux` enables OSC 8 hyperlink passthrough with `terminal-features 'xterm*:hyperlinks'`
- In Ghostty inside `tmux` on macOS, use `Shift+Cmd+Click` to open links
- `home/.config/ghostty/config` keeps `mouse-shift-capture = false` so `tmux` mouse bindings and link opening stay predictable
- Use `tmux-link-test` inside `tmux` to verify hyperlink passthrough quickly

## tmux Agent Status

- Session state is rendered from files under `/tmp/tmux-agent-$(id -u)`
- Agents write `agent<TAB>state` via `~/.config/tmux/agent-status-hook.sh <working|waiting|done> <agent>`
- `home/.config/tmux/session-status.sh` is the base tmux entrypoint and `home/.config/tmux/session-status-lib.sh` owns the generic local collector and renderer helpers
- `home/.config/tmux/README.md` is the code-local change guide for the tmux agent-status stack
- Later repos in the dotty chain can extend the base collector through `~/.config/tmux/session-status-overlay.sh`
- The extension hook names are:
  - `tmux_agent_overlay_maybe_refresh`
  - `tmux_agent_overlay_emit_records`
- Overlay emitters should print tab-separated records in the form `session_label<TAB>agent<TAB>state<TAB>source<TAB>updated_at`
- The status bar still polls every 2 seconds, but tmux also forces an immediate refresh on `client-session-changed` and `client-attached`
- For Codex, `working` and `done` remain hook-driven; live pane parsing is only used to detect explicit waiting prompts
- Codex does not currently expose a dedicated public hook for "waiting for user input", so tmux infers that state from a small allowlist of known prompt shapes
- When a Codex prompt line includes both waiting cues and `esc to interrupt`, tmux treats it as `waiting` rather than `working`
- Generic Codex footer text such as the model/path line is not treated as a waiting signal
- Finished shell-only sessions are hidden once no live agent process remains

## Claude

The repo hook keeps `~/.claude` as a real directory and manages tracked contents from `home/.claude/`.

- `CLAUDE.md` is symlinked into place
- tracked `hooks/`, `rules/`, and `skills/` entries are linked individually
- `settings.json` is copied so later repos can extend it without writing through into this repo

Later repos in the dotty chain can add more entries to the same live `~/.claude/` directories.

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
- runs tmux agent status regression tests, including the optional extension contract path
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
