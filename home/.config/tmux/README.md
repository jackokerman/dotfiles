# tmux Agent Status

This directory owns the generic tmux agent-status pipeline.

## Ownership

- `session-status.sh`: stable tmux entrypoint that loads the generic renderer and optional overlay adapter.
- `agent-status-hook.sh`: stable hook entrypoint that writes explicit `agent<TAB>state` records for the current tmux session into `/tmp/tmux-agent-$(id -u)`.
- `agent-status/main.sh`: generic session-status orchestration.
- `agent-status/lib.sh`: generic local collection, state reconciliation, duplicate suppression, and rendering helpers.
- `agent-status/pane-state.sh`: live pane-tail classification for `codex` and `claude`. This is where prompt-shape heuristics live.
- `agent-status/hook.sh`: explicit state-file writer used by the stable hook entrypoint.
- `tmux.conf`: wires the status script into `status-right`.

## Overlay contract

Overlays may extend the generic collector through `~/.config/tmux/session-status-overlay.sh`.

Supported hooks:

- `tmux_agent_overlay_maybe_refresh`
- `tmux_agent_overlay_emit_records`

Overlay emitters must print tab-separated rows:

```text
session_label<TAB>agent<TAB>state<TAB>source<TAB>updated_at
```

The base renderer should not learn overlay-specific cache layout or transport logic.

## Change rules

- Keep generic behavior here. Work-specific collectors belong in an overlay repo.
- Do not patch the base renderer to understand a specific remote transport or cache format.
- Treat Codex prompt detection as regression-prone. If you change prompt heuristics, add or update focused tail tests.
- Treat state reconciliation as separate from prompt parsing. If you change state precedence, stale-working handling, or duplicate suppression, add or update reconciliation or integration tests.
- Prefer changing the smallest layer that owns the behavior:
  - prompt parsing: `agent-status/pane-state.sh`
  - local collection or render policy: `agent-status/lib.sh`
  - tmux wiring: `session-status.sh`
  - environment-specific collection: overlay script in another repo

## Required verification

Run these before committing tmux status changes:

```bash
./tests/tmux-agent-status/test-pane-state.sh
./tests/tmux-agent-status/test-session-status-local.sh
./tests/tmux-agent-status/test-session-status.sh
./tests/tmux-agent-status/test-overlay-contract.sh
./scripts/check
```

If you change the overlay contract, update this file, `docs/agent-tooling.md`, and the overlay repo that consumes it in the same change.
