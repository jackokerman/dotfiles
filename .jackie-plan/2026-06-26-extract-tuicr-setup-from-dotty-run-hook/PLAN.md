---
id: 2026-06-26-extract-tuicr-setup-from-dotty-run-hook
title: Extract tuicr setup from dotty run hook
state: complete
createdAt: 2026-06-26T16:16:58.067Z
updatedAt: 2026-06-26T16:29:25.407Z
sourcePlan: 2026-06-26-explore-leaner-dotty-run-file-structure
---

# Extract tuicr setup from dotty run hook

## Plan

# Extract tuicr setup from dotty run hook

## Goal
Move the `tuicr` managed-checkout install/update workflow out of `.dotty/run.sh` into a standalone `scripts/sync-tuicr.sh` helper, while preserving current `dotty update` behavior.

## Current Shape
`.dotty/run.sh` currently owns the entire `setup_tuicr` flow: clone the runtime checkout, verify branch and origin, skip dirty or mismatched checkouts, fast-forward from origin, bootstrap Cargo through rustup when needed, install with `cargo install --path ... --locked --force`, and stamp the installed checkout revision under `${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/tuicr/install-rev`.

`tests/tuicr/test-setup.sh` already covers the important behavior, but it reaches into the hook by sourcing `.dotty/run.sh` and calling `setup_tuicr`. That is the boundary to improve.

## Implementation Shape
Create `scripts/sync-tuicr.sh` as the direct local-debug entrypoint. Move the tuicr helper functions and setup body there, using small local logging helpers that match the existing hook output names (`title`, `info`, `success`, `warning`) so the script is self-contained when run directly.

Change `.dotty/run.sh` so `setup_tuicr` only resolves `scripts/sync-tuicr.sh`, warns if it is missing or non-executable, and invokes it non-fatally from the existing install/update hook path. Keep the surrounding `dotty update` orchestration unchanged.

Retarget `tests/tuicr/test-setup.sh` to execute `scripts/sync-tuicr.sh` directly with the same fake HOME, fake Cargo, and tuicr override environment. Remove the fake dotty library and `source .dotty/run.sh` coupling.

Add repo steering that `.dotty/commands/*` should stay thin `dotty run` entrypoints and substantive reusable workflow logic belongs under `scripts/`. The command layout itself is unchanged, so no README update is required beyond any existing `scripts/README.md` wording that helps future contributors.

## Acceptance Criteria
- `dotty update` still syncs and installs `tuicr` through `.dotty/run.sh`.
- `scripts/sync-tuicr.sh` can be run directly for local debugging.
- `tests/tuicr/test-setup.sh` covers clone, fast-forward update, dirty checkout skip, branch mismatch skip, origin mismatch skip, and reinstall-on-revision-change behavior against the standalone script.
- `.dotty/run.sh` loses the tuicr workflow internals and remains an orchestration entrypoint.
- Repo-local steering documents the thin-command-wrapper pattern so future dotty run-file changes do not reintroduce substantive workflow logic under `.dotty/commands/`.

## Verification
Run `tests/tuicr/test-setup.sh` for focused behavior and `./scripts/check --staged --quiet` before committing. Because this touches a `dotty update` hook path and a managed checkout helper, run `dotty update` after committing to refresh the live home state before pushing.
