# tmux Agent Status

This directory now owns the tmux-side wrappers and path resolution for the external `tmux-agent-bar` runtime.

## Ownership

- `session-status-left.sh`: stable tmux entrypoint for the current-session state prefix; tmux renders the session name itself so local session switches update immediately.
- `session-status.sh`: stable tmux entrypoint that resolves the active `tmux-agent-bar` checkout and execs its renderer.
- `session-status-refresh.sh`: stable tmux entrypoint that refreshes the session-scoped cached `status-right` value from the active `tmux-agent-bar` checkout.
- `agent-status-hook.sh`: stable hook entrypoint that resolves the active `tmux-agent-bar` checkout and execs its explicit-state writer.
- `codex-agent-status-hook.sh`: stable Codex hook entrypoint that resolves the active `tmux-agent-bar` checkout and execs its Codex lifecycle adapter.
- `tmux-agent-bar-path.sh`: shared path-resolution helper for the wrappers.
- `tmux.conf`: wires the stable wrappers into `status-left` and `status-right`, keeps the session name tmux-native on the left, and stores the visible right side in a session-scoped tmux option so session switches update immediately.

The generic parser, collector, renderer, prompt heuristics, and Codex event-to-state mapping live in the managed `tmux-agent-bar` repo, not in this repo.

## Runtime resolution

The wrappers resolve the runtime checkout in this order:

1. `TMUX_AGENT_BAR_DIR`
2. `~/.config/tmux-agent-bar/path.local`
3. `~/.local/share/tmux-agent-bar/repo`

`dotty update` manages the default checkout under `~/.local/share/tmux-agent-bar/repo`.

## Change rules

- Keep generic status-bar logic in `tmux-agent-bar`, not here.
- Keep this repo responsible only for wrapper stability, checkout sync, and path resolution.
- If a status-bar bug is in agent detection, rendering, or remote-source behavior, fix it in `tmux-agent-bar` and keep the regression there.
- If a bug is in install/update behavior or wrapper path selection, fix it here and add a focused wrapper or sync test.

## Required verification

Run these before committing wrapper or sync changes:

```bash
./tests/tmux-agent-bar/test-runtime-path.sh
./tests/tmux-agent-bar/test-wrappers.sh
./tests/tmux-agent-bar/test-sync.sh
./scripts/check
```
