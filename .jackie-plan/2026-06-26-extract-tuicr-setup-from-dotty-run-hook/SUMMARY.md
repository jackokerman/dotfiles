---
id: 2026-06-26-extract-tuicr-setup-from-dotty-run-hook
title: Extract tuicr setup from dotty run hook
state: ready-to-implement
createdAt: 2026-06-26T16:16:58.067Z
updatedAt: 2026-06-26T16:27:37.426Z
sourcePlan: 2026-06-26-explore-leaner-dotty-run-file-structure
sourceRepo: dotfiles
sourcePath: .
---

Extracted the `tuicr` managed-checkout workflow from `.dotty/run.sh` into executable `scripts/sync-tuicr.sh`. The hook now keeps a small non-fatal wrapper that calls the standalone script during install/update. `tests/tuicr/test-setup.sh` now exercises the standalone script directly with fake HOME/Cargo/remote repos. Added `scripts/sync-tuicr.sh` to `scripts/check` syntax and executable-bit coverage plus staged-check routing, and documented the thin `.dotty/commands/*` wrapper pattern in `AGENTS.md` and `scripts/README.md`.

Focused verification passed: `tests/tuicr/test-setup.sh`, `bash -n .dotty/run.sh scripts/sync-tuicr.sh tests/tuicr/test-setup.sh scripts/check`, and `./scripts/check --staged --quiet`.
