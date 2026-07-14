---
id: 2026-07-14-make-homebrew-sesh-effective
title: Make Homebrew sesh effective
state: ready-to-implement
createdAt: 2026-07-14T18:31:24.058Z
updatedAt: 2026-07-14T18:31:45.390Z
sourcePlan: 2026-06-27-design-sesh-config-layering-for-the-dotty-chain
---

# Make Homebrew sesh effective

## Plan

## Problem

The `sesh` config-layering work should be implemented and verified against the package-managed `sesh` binary, not a stale local development build.

Current local checks show `sesh` resolves to `~/go/bin/sesh`, which reports `sesh version dev`. The package-managed binary at `/opt/homebrew/bin/sesh` reports `sesh version 2.27.0` and includes current commands such as `sesh cache`, `sesh window`, and `sesh mkdir`.

The package is already permitted by host-managed Homebrew policy on the work laptop. This is local provenance and PATH cleanup, not a package-approval task.

Source plan: `2026-06-27-design-sesh-config-layering-for-the-dotty-chain`. Complete this cleanup before implementing that plan so the layering work uses the intended `sesh` command.

## Target contract

Make `sesh` resolve to the package-managed Homebrew binary on this machine without adding a repo-wide compatibility layer, wrapper, or alternate install path.

Prefer removing the obsolete manually installed `~/go/bin/sesh` binary if nothing still depends on it. If a broader `~/go/bin` PATH ordering issue is discovered, fix the specific cause that makes manual Go-installed tools shadow tracked Homebrew tools, but do not add a `sesh`-specific shim unless direct cleanup is unsafe.

## Implementation slices

1. Confirm current resolution with `type -a sesh`, `command -v sesh`, `sesh --version`, and `/opt/homebrew/bin/sesh --version`.
2. Inspect enough provenance to justify cleanup: file metadata for `~/go/bin/sesh`, whether Go is currently installed, and whether the binary appears to be a manual development build.
3. Remove or quarantine the obsolete `~/go/bin/sesh` binary, or adjust PATH ordering only if that is the actual source-of-truth fix for this dotfiles setup.
4. Open a fresh shell or run a direct PATH-resolution check and confirm `sesh` now resolves to `/opt/homebrew/bin/sesh` and reports `2.27.0`.
5. Run the small `sesh` command-surface checks needed by the source plan: `sesh --help`, `sesh list --help`, `sesh picker --help`, and help for `sesh cache`, `sesh window`, and `sesh mkdir`.
6. If cleanup changes tracked shell startup or docs, update the corresponding `README.md`/`AGENTS.md` guidance in the same change. If cleanup is only deleting a stale untracked binary, do not add tracked docs or tests.

## Non-goals

- Do not change `setup_sesh` or the generated `sesh.toml` layering contract in this cleanup plan.
- Do not open a Homebrew package-approval PR unless a fresh host-policy check proves the package is no longer permitted.
- Do not remove `~/go/bin` from PATH wholesale unless a focused audit shows that is the intended source-of-truth change for this dotfiles repo.
- Do not add a `sesh` wrapper solely to hide PATH ordering.

## Acceptance criteria

- `command -v sesh` resolves to `/opt/homebrew/bin/sesh` in the normal shell environment.
- `sesh --version` reports the same version as `/opt/homebrew/bin/sesh --version`.
- Homebrew no longer warns that `sesh` is shadowed by `~/go/bin/sesh`.
- The source config-layering plan can rely on the package-managed `sesh` binary for implementation and verification.
- Any tracked source changes, if needed, are minimal and verified through the repo's normal check path.

## Verification

- `type -a sesh`
- `command -v sesh`
- `sesh --version`
- `/opt/homebrew/bin/sesh --version`
- `brew info sesh`
- `sesh --help`
- `sesh list --help`
- `sesh picker --help`
- `sesh cache --help`
- `sesh window --help`
- `sesh mkdir --help`
- `git status --short --branch`
- If tracked files change: `./scripts/check --quiet`

## Next honest step

Start by confirming whether `~/go/bin/sesh` is still needed. If it is just a stale manual development build, remove or quarantine it and verify that the Homebrew `sesh` becomes the effective command in a fresh shell.
