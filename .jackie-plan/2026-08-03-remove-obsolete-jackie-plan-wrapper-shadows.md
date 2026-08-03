---
id: 2026-08-03-remove-obsolete-jackie-plan-wrapper-shadows
title: Remove obsolete Jackie Plan wrapper shadows
state: ready-to-implement
createdAt: 2026-08-03T18:48:01.827Z
updatedAt: 2026-08-03T18:50:32.642Z
---

# Remove obsolete Jackie Plan wrapper shadows

## Plan

## Objective

Remove obsolete live `jp` and `jackie-plan` wrapper scripts left by the pre-manifest installation path so the current repo-owned Bun link is the executable resolved on all managed machines.

## Evidence

On the current devbox, all four obsolete wrappers are identical regular files created on July 14:

- `~/.dotty/bin/jp`
- `~/.dotty/bin/jackie-plan`
- `~/.local/bin/jp`
- `~/.local/bin/jackie-plan`

They hard-code `/home/owner/src/jackie-plan/src/cli.ts`, which does not exist on this devbox. Because `~/.dotty/bin` and `~/.local/bin` precede `~/.bun/bin`, they shadow the valid Bun link at `~/.bun/bin/jp`. This caused `jp doctor`, `jp review`, and `jp --help` to fail during a planning session even though the managed Jackie Plan checkout and repo installer were healthy.

The base dotfiles migration commit `9c4be56` removed `.dotty/commands/install-jackie-plan` in favor of the devtools manifest, but no one-time cleanup removed these generated wrapper outputs.

## Scope

1. Add a base-dotfiles `.dotty/cleanups/` task that removes only legacy Jackie Plan wrappers owned by the removed installation mechanism.
   - Cover both command names in `~/.dotty/bin` and `~/.local/bin`.
   - Guard deletion by verifying the files match the known legacy wrapper shape or checksum; do not remove arbitrary user-authored executables with the same names.
   - Leave the repo-owned `~/.bun/bin/jp` and `~/.bun/bin/jackie-plan` links untouched.
2. Add focused cleanup verification following existing dotfiles cleanup-test conventions.
3. Update documentation only if any current text still claims the legacy wrappers are installed or owned.

## Non-goals

- Do not add another wrapper, fallback path, PATH override, or compatibility shim.
- Do not change Jackie Plan's current repo-owned `scripts/install.sh` behavior; the existing install-only follow-up remains separate.
- Do not hard-code machine-specific home paths in the cleanup.

## Verification

1. Run `dotty cleanups` and confirm the new cleanup is discovered.
2. Run the required dry-run update path and confirm it reports only the four matching legacy wrappers.
3. Remove only any receipts created accidentally during local cleanup verification, following repo policy.
4. Run `./scripts/check --extended --quiet` because this changes managed-tool installation cleanup behavior.
5. After the real laptop/devbox propagation, confirm `command -v jp` resolves the valid Bun-linked CLI and `jp doctor` succeeds.
6. Commit conventionally and push `main` through the base dotfiles workflow.

## Agent handoff

Implement in the public base `dotfiles` repository, which owned the removed wrapper mechanism and its migration to manifest-managed devtools. Inspect commit `9c4be56`, the current `.dotty/devtools.tsv` Jackie Plan row, and nearby cleanup tasks before editing. Preserve unrelated dirty files and avoid editing generated live wrappers directly except through cleanup verification.
