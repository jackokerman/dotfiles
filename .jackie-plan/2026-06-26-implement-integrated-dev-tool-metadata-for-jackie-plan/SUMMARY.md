---
id: 2026-06-26-implement-integrated-dev-tool-metadata-for-jackie-plan
title: Implement integrated dev-tool metadata for Jackie Plan
state: ready-to-implement
createdAt: 2026-06-26T16:49:18.390Z
updatedAt: 2026-06-26T16:49:22.092Z
sourcePlan: 2026-06-26-explore-first-class-dotty-managed-dev-tool-checkouts
sourceRepo: /Users/jackokerman/dotfiles
sourcePath: .
---

# Summary

Implement the first slice from the first-class dev-tool checkout exploration: make Jackie Plan's checkout and integration metadata come from one tracked source of truth.

Scope:
- Preserve the existing conservative checkout behavior from `.dotty/dev-checkouts.tsv` and `scripts/sync-dev-checkouts.sh`.
- Add a richer metadata source or companion metadata file only for integrated development tools.
- Migrate only `jackie-plan` through the richer contract in the first slice.
- Make `setup_dev_checkouts` and `setup_jackie_plan` consume one source of truth for Jackie Plan's repo URL, branch, checkout path, compatibility symlink, and installer path.
- Keep `tuicr` out of this model because it is a runtime-only managed checkout.

Acceptance criteria:
- Missing Jackie Plan checkouts still clone to `~/src/jackie-plan`.
- Clean checkouts still fast-forward conservatively.
- Dirty, customized, or branch-mismatched checkouts still skip with warnings.
- `~/.local/share/jackie-plan/repo` remains a compatibility symlink only when absent or already pointing at the active checkout.
- Docs name the new source of truth and preserve the `~/src` development checkout versus `~/.local/share` runtime checkout distinction.
- Focused tests cover metadata parsing and Jackie Plan integration behavior.
