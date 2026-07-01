---
id: 2026-06-25-audit-single-checkout-ownership-for-dotty-managed-tool-repos
title: audit single-checkout ownership for dotty-managed tool repos
state: complete
createdAt: 2026-06-25T15:55:17.861Z
updatedAt: 2026-06-26T00:38:54.806Z
---

# audit single-checkout ownership for dotty-managed tool repos

## Plan

1. Document one checkout-ownership rule for dotty-managed tools:
   actively developed personal tools that are tracked in `.dotty/dev-checkouts.tsv` use `~/src/<repo>` as the canonical checkout, while `~/.local/share/<tool>/repo` is reserved for runtime-only installs or compatibility paths.
2. Align `tmux-agent-bar` with that rule by migrating dotfiles wrappers, sync logic, and tests away from treating `~/.local/share/tmux-agent-bar/repo` as the canonical source tree.
3. Keep `tuicr` as a runtime-only managed checkout unless this audit uncovers a concrete reason to promote it into `~/src` development-checkout handling.
4. Leave `dotty` self-management out of this change unless a concrete conflict appears; capture any resulting work as a separate follow-up.

## Why this exists

The repo currently mixes two ownership models for dotty-managed tools. `jackie-plan` already uses a normal development checkout under `~/src/jackie-plan` plus a compatibility symlink when needed, but `tmux-agent-bar` is now also listed in `.dotty/dev-checkouts.tsv` while docs, path resolution, and sync scripts still talk about `~/.local/share/tmux-agent-bar/repo` as the default location. That mismatch makes it unclear which checkout is authoritative and risks drift between a development clone and the runtime clone.

## Goal

Make the checkout policy explicit and consistent so actively developed personal tools have one canonical checkout, while runtime-only tools stay under `~/.local/share/` by design.

## Confirmed repo facts

- `.dotty/dev-checkouts.tsv` already tracks both `jackie-plan` and `tmux-agent-bar` under `~/src`.
- `.dotty/commands/install-jackie-plan` treats `~/src/jackie-plan` as the active checkout and creates `~/.local/share/jackie-plan/repo` only as a compatibility symlink when absent.
- `docs/agent-tooling.md`, `AGENTS.md`, `scripts/sync-tmux-agent-bar.sh`, and `tests/tmux-agent-bar/test-runtime-path.sh` still treat `~/.local/share/tmux-agent-bar/repo` as the default tmux-agent-bar location.
- `.dotty/run.sh` and `tests/tuicr/test-setup.sh` still manage `tuicr` as a runtime-only checkout under `~/.local/share/tuicr/repo`.

## Definition of done

- The repo documents one consistent ownership model for dotty-managed personal tools.
- `tmux-agent-bar` path resolution, sync behavior, and tests follow that model without requiring two independent clones.
- `tuicr` remains explicitly documented as runtime-only if it stays on the existing path.
- Any unrelated `dotty` ownership questions are captured as separate follow-up work instead of expanding this change.

## First implementation slice

Update the tmux-agent-bar path model and sync flow to treat the `~/src/tmux-agent-bar` development checkout as canonical when present, keep `~/.local/share/tmux-agent-bar/repo` only as a compatibility path, and then align the affected docs and tests.

## Notes

This plan is intentionally scoped to tool-checkout ownership. It does not include unrelated hook, guard, or shell-refresh issues unless they directly block the migration.

## Agent handoff

Implemented the first slice: tmux-agent-bar wrappers now prefer the `~/src/tmux-agent-bar` development checkout when present, fall back to `~/.local/share/tmux-agent-bar/repo`, and the sync script uses the same model. The sync script creates the legacy runtime path as a compatibility symlink when a dev checkout exists and the legacy path is absent, while preserving existing legacy checkouts. Updated focused tests and docs/steering surfaces to describe the `~/src` development-checkout ownership model and `tuicr` as runtime-only.

Verified with `./tests/tmux-agent-bar/test-runtime-path.sh`, `./tests/tmux-agent-bar/test-sync.sh`, `./tests/tmux-agent-bar/test-wrappers.sh`, and `./scripts/check --extended --quiet`.
