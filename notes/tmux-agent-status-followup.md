# tmux agent status roadmap

## Current state

What is solid now:

- Explicit tmux state files are the primary source of truth for local sessions.
- Remote devbox sessions are mirrored through explicit local-to-remote mappings
  instead of transient `pty-cli` client logs.
- Remote `done` sessions are already suppressed once the mapped remote tmux
  session no longer owns a live `codex` or `claude` process.

What is still not ideal:

- Local `done` sessions can linger when the pane has returned to a plain shell.
- Multiple local labels can point at the same remote tmux session, which creates
  duplicate status entries.
- Remote Devvy/Codex sessions can still lose their explicit remote state file
  even while the agent process is alive.
- Codex still has no explicit hook for “waiting for user input” or “the agent
  process tree fully exited,” so bounded liveness checks remain necessary.

## This reliability pass

This step is intentionally narrow. It is not the picker.

The goals are:

1. Canonicalize remote session identity.
   - The devbox-named local tmux session is the canonical label for mirrored
     remote agent work.
   - Wrapper aliases like `devvy` should never surface as separate status rows.
2. Hide local stale `done` sessions immediately.
   - If a local `codex` or `claude` session has explicit `done` state but no
     live agent process remains, remove it from the status bar even if the tmux
     pane is still an open shell.
3. Keep remote cleanup hook-plus-liveness based.
   - Explicit remote state still drives status.
   - Liveness checks decide whether a `done` remote session should remain
     visible or be suppressed.

Acceptance criteria for this pass:

- `Documents`-style local sessions disappear once the agent exits and the pane
  returns to `zsh`.
- Duplicate labels for the same remote `devvy-agent` session collapse to one
  canonical devbox-named entry.
- Remote `done` sessions with no live agent process disappear.
- No picker work lands in this pass.

## Next foundation step

Once the current status behavior is reliable, the next internal milestone is a
shared collector/cache layer.

The collector should normalize one session-level row per canonical session with:

- session name
- agent name
- state
- source (`local_hook`, `remote_mirror`, `local_fallback`, etc.)
- last-updated timestamp
- last-live-agent-seen timestamp
- attention class

That collector should merge:

- explicit local state files
- explicit mirrored remote state files
- bounded liveness checks for `codex` and `claude`
- local Codex fallback inference for `working` and `waiting` only

The status bar should ultimately consume that cache instead of making its own
reconciliation decisions inline.

## After that

Only after the collector is stable should a picker land.

The first picker should be session-first, not pane-first, and ranked by:

1. `waiting`
2. recently `done`
3. `working`

The picker is a consumer of the collector. It is not part of the current pass.
