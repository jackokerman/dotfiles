# tmux agent status follow-up

## Current status

The current tmux status implementation is in a better place than before, but it is
not fully hook-based yet.

What is solid now:

- Explicit local and remote state files are the primary source of truth.
- The local tmux hook now resolves the real session via `TMUX_PANE`.
- Remote sync now prefers explicit remote tmux hook state over remote process
  existence.

What is still not ideal:

- Local Codex still uses a small visible-pane fallback to distinguish `working`
  and `waiting` from `done`.
- That fallback is intentionally narrow, but it is still more brittle than a
  pure hook/state-file model.

## Why this should be simplified

The repo below is the right reference model:

- `https://github.com/samleeney/tmux-agent-status`

The important design principle from that repo is:

- Hooks write explicit state.
- Renderer stays dumb.
- Process checks are only for session existence, not status inference.

## Recommended next step

Refactor the current setup to match that model more directly instead of carrying
local fallback logic.

### Goal

Only render from explicit state values:

- `working`
- `waiting`
- `done`

### Desired architecture

1. Hooks are the only source of status transitions.
2. Renderer only reads status files and displays them.
3. Remote sync only mirrors explicit remote state files.
4. No process-based override should replace explicit `done`.
5. Any local visible-pane fallback should be removed once Codex hooks cover the
   missing states.

## Concrete follow-up tasks

1. Deep-dive `samleeney/tmux-agent-status` and copy the hook/state model, not
   just the display semantics.
2. Update local Codex hooks to mirror the fuller state transitions used there.
3. Specifically check whether Codex can explicitly emit `waiting` for approval
   or user-input pauses in this environment.
4. If Codex supports that cleanly, remove the local visible-pane fallback from
   `session-status.sh`.
5. Keep remote logic limited to syncing remote tmux state files and pruning dead
   sessions.
6. Re-test these transitions once the hook model is in place:
   - local Codex: `working -> waiting -> done`
   - remote Claude: `working -> done`
   - session close: session disappears cleanly

## Practical stopping point

If the fuller Codex hook model works, the final renderer should be almost dumb:

- read status file
- map `working/waiting/done` to colors/icons
- skip missing/dead sessions

That is the version to aim for.
