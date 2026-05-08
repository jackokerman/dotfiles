# tmux Agent Status Tests

Use these tests to lock down behavior when tmux status bugs show up.

## Bug-to-test workflow

1. Start from the observed contract breakage, not from the code path you think is wrong.
2. Reduce the bug to the smallest reproducer:
   - a pane tail transcript for prompt-shape or live-state issues
   - a resolver input/output case for precedence issues
   - a rendered row or local record for collector or visibility issues
3. Add or update the narrowest test that expresses that contract.
4. Only then change the implementation.

Keep assertions on user-visible behavior or supported contracts. Do not assert temp-file layout, exact mtimes, helper calls, or which internal function produced the answer unless that detail is itself the supported contract.

## Test ownership

- `test-pane-state.sh`: prompt-shape and pane-tail classification. Use this when the visible footer or prompt text is being misread. Prefer copying the smallest real transcript that still reproduces the bug.
- `test-session-status.sh`: state precedence and render policy. Use this when explicit state, live state, stale-working decay, agent mismatch, or truncation rules are wrong.
- `test-session-status-local.sh`: local collection behavior. Use this when session visibility, fallback-only sessions, done cleanup, or local explicit record handling is wrong.
- `test-overlay-contract.sh`: base overlay contract only. Use this when the generic base collector and an overlay disagree about duplicate labels or record rendering.

## Scope rules

- Prefer base tests first. Only add overlay tests when the bug truly depends on remote mirroring or overlay-owned policy.
- If one bug crosses layers, add one focused test per affected contract instead of one oversized end-to-end test.
- When exact timestamps are not the contract, match their shape rather than a hard-coded value.
