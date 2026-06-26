# tmux Agent Status

This directory now owns the tmux-side wrappers and path resolution for the external `tmux-agent-bar` runtime.

## Ownership

- `session-status-left.sh`: stable tmux entrypoint for the current-session state prefix; it reads the explicit state file directly and never calls back into tmux while tmux is evaluating `status-left`.
- `session-status.sh`: stable tmux entrypoint that resolves the active `tmux-agent-bar` checkout and execs its renderer.
- `session-status-refresh.sh`: stable tmux entrypoint that refreshes the session-scoped cached `status-right` value from the active `tmux-agent-bar` checkout. Forced refreshes draw cached state first and refresh fresh remote/source state in the background.
- `agent-status-hook.sh`: stable hook entrypoint that resolves the active `tmux-agent-bar` checkout and execs its explicit-state writer.
- `codex-agent-status-hook.sh`: stable Codex hook entrypoint that resolves the active `tmux-agent-bar` checkout and execs its Codex lifecycle adapter.
- `tmux-agent-bar-path.sh`: shared path-resolution helper for the wrappers.
- `tmux.conf`: wires the stable wrappers into `status-left` and `status-right`, passes the session name to the left prefix helper, keeps the visible session name tmux-native, and renders only the session-scoped cached right-side option. Hooks update that option on session switches, session closes, and agent state changes.

The generic parser, collector, renderer, prompt heuristics, and Codex event-to-state mapping live in the active `tmux-agent-bar` checkout, not in this repo.

## Runtime resolution

The wrappers resolve the runtime checkout in this order:

1. `TMUX_AGENT_BAR_DIR`
2. `~/.config/tmux-agent-bar/path.local`
3. `~/src/tmux-agent-bar` when present
4. `~/.local/share/tmux-agent-bar/repo`

`dotty update` manages the default development checkout under `~/src/tmux-agent-bar` through `.dotty/dev-checkouts.tsv`. The legacy `~/.local/share/tmux-agent-bar/repo` path is kept only as a compatibility symlink when safe, or as a fallback checkout when the development checkout is absent.

Optional runtime modules under `~/.config/tmux-agent-bar/agents/` and `~/.config/tmux-agent-bar/sources/` are owned by the current dotty layer or by local user config. The base `dotfiles` repo installs and updates the runtime but does not hardcode private launcher labels or remote transports.

## Change rules

- Keep generic status-bar logic in `tmux-agent-bar`, not here.
- Keep this repo responsible only for wrapper stability, checkout sync, and path resolution.
- Keep the visible right side event-driven. `status-right` must read `#{@tmux_agent_bar_status_right}` only; wrappers and hooks refresh that cached option. Do not fix freshness by adding a polling `#()` renderer or refresher back into `status-right`.
- Before changing status behavior, identify the source of truth and trigger path: explicit hook state, live pane tail, remote/source cache, session-scoped tmux option, and the tmux hook that updates it. Add the regression at the boundary that failed.
- If a status-bar bug is in agent detection, rendering, or remote-source behavior, fix it in `tmux-agent-bar` and keep the regression there.
- If a bug is in install/update behavior or wrapper path selection, fix it here and add a focused wrapper or sync test.
- For latency regressions, verify the live tmux config does not contain `session-status-refresh.sh` in `status-right`, and check that refresh/render processes are not being spawned by polling.

## Required verification

Run these before committing wrapper or sync changes:

```bash
./tests/tmux-agent-bar/test-runtime-path.sh
./tests/tmux-agent-bar/test-wrappers.sh
./tests/tmux-agent-bar/test-sync.sh
./scripts/check
```
