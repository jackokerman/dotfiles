---
id: 2026-06-26-extract-tuicr-setup-from-dotty-run-hook
title: Extract tuicr setup from dotty run hook
state: inbox
createdAt: 2026-06-26T16:16:58.067Z
updatedAt: 2026-06-26T16:16:58.067Z
sourcePlan: 2026-06-26-explore-leaner-dotty-run-file-structure
sourceRepo: dotfiles
sourcePath: .
---

# Extract tuicr setup from dotty run hook

## Plan

## Goal
Move the `tuicr` managed-checkout install/update workflow out of `.dotty/run.sh` into a standalone script, while preserving current `dotty update` behavior.

## Why
`setup_tuicr` is the clearest mismatch in the dotty hook: it is a full clone, safety-check, fast-forward, cargo-install, and revision-recording workflow embedded in the post-link orchestration file. It already has focused behavior tests, so extraction should make the boundary easier to understand and verify without changing user-facing behavior.

## Proposed Shape
Create `scripts/sync-tuicr.sh` with the current `setup_tuicr` behavior and helper functions. Keep `.dotty/run.sh` responsible for calling the script and translating failure into the existing warning/non-fatal hook behavior. Retarget `tests/tuicr/test-setup.sh` to invoke the standalone script directly instead of sourcing `.dotty/run.sh`.

Add a small repo-local steering update while doing the extraction so future agents keep the same boundary: `.dotty/commands/*` should stay thin `dotty run` entrypoints, substantive reusable workflow logic should live under `scripts/`, and hook-owned inline logic should be reserved for behavior that only makes sense inside the post-link hook. Prefer `AGENTS.md` for agent-facing steering, with matching docs only if the user-facing command layout changes. Add a mechanical check only if the extracted shape exposes a cheap, concrete invariant; do not add broad linting just to police style.

## Acceptance Criteria
- `dotty update` still syncs and installs `tuicr` through the hook.
- `scripts/sync-tuicr.sh` can be run directly for local debugging.
- `tests/tuicr/test-setup.sh` covers clone, fast-forward update, dirty checkout skip, branch mismatch skip, origin mismatch skip, and reinstall-on-revision-change behavior against the standalone script.
- `.dotty/run.sh` loses the tuicr workflow internals and remains an orchestration entrypoint.
- Repo-local steering documents the thin-command-wrapper pattern so future dotty run-file changes do not reintroduce substantive workflow logic under `.dotty/commands/`.
