---
id: 2026-07-13-gate-homebrew-python-on-managed-machines
title: Gate Homebrew Python on managed machines
state: complete
priority: high
createdAt: 2026-07-13T18:03:18.976Z
updatedAt: 2026-07-13T18:05:47.994Z
---

# Gate Homebrew Python on managed machines

## Plan

## Objective

Prevent userland Homebrew Python from being installed or preferred by default on managed machines, while keeping Python available on personal machines where user-managed tooling is appropriate.

The expected steady state is:

- Personal machines can still install Homebrew Python from the base `Brewfile`.
- Managed machines do not install Homebrew Python just because the base dotfiles package list is applied.
- Agent and shell workflows on managed machines prefer host-provided Python when a script uses `#!/usr/bin/env python3`, unless a repo-local tool deliberately chooses its own virtual environment or runtime.
- Validation scripts that need third-party Python packages do not assume those packages are globally installed into Homebrew Python.

## Current evidence

- The base `Brewfile` currently has an unconditional `brew "python"` entry.
- `HOMEBREW_DOTFILES_ENV` already gates personal-only packages elsewhere in the `Brewfile`; Python should use the same profile split if it is only user-managed on personal machines.
- On the current laptop, `python3` resolves to Homebrew Python before host/system Python because `/opt/homebrew/bin` is early in the agent shell `PATH`.
- The observed failure came from manually invoking a bundled skill validation script with `#!/usr/bin/env python3`; it was not triggered by `dotty update`, repo checks, pre-commit, or an approved managed validation lane.
- The failure mode was missing `PyYAML` in Homebrew Python. Installing `PyYAML` globally into Homebrew Python is not the right fix; it would deepen reliance on a user-managed Python environment.
- Some Homebrew packages may depend on Python transitively. Removing the explicit `brew "python"` entry may not remove every Homebrew Python installation from a machine, so implementation must distinguish package ownership from PATH precedence and cleanup behavior.

## Proposed implementation

1. Update the base `Brewfile` so `brew "python"` is personal-only, matching the pattern used for other user-managed tools that should not be installed by default on managed machines.
2. Audit `scripts/brew-sync.sh` and the Brewfile tests to make sure the active package set can be verified for at least these profiles:
   - managed/laptop profile excludes explicit Python ownership;
   - personal profile includes Python;
   - remote profile behavior remains intentional.
3. Add or update Brewfile regression tests so this does not drift back:
   - assert Python is absent from the managed active Brewfile formula set;
   - assert Python is present in the personal active Brewfile formula set;
   - keep existing host-provider behavior for tools such as `gh` unchanged.
4. Audit PATH setup that is tracked in this repo and keep any generic managed-machine behavior aligned with the package ownership decision. If a later/private overlay owns additional managed-machine PATH ordering, record a separate follow-up there rather than encoding private paths in this public repo.
5. Do not run destructive Homebrew cleanup automatically. If implementation needs to remove an already-installed Homebrew Python from the current machine, first check whether it is still required by installed formulae and present that as a manual cleanup step or a separate explicit action.
6. Do not add global `pip install`, `--break-system-packages`, or user-site package workarounds for validation scripts. If a validation path needs third-party Python packages, make that tool own a virtual environment, use an existing repo runtime, or switch to a dependency-free/parser-light implementation.

## Verification

- Run the relevant Brewfile/brew-sync tests for profile gating.
- Run the repo check lane that covers changed files, preferably `./scripts/check --staged --quiet` after staging.
- Verify the active managed profile no longer includes explicit `python` in `brew bundle list --file Brewfile --formula` under the managed environment variable.
- Verify the personal profile still includes `python`.
- If PATH logic changes, verify `python3` resolution in the intended managed-shell scenario and document any remaining Homebrew Python presence that comes only from transitive dependencies.

## Done when

- The base `Brewfile` no longer explicitly installs Homebrew Python for managed-machine profiles.
- Personal-machine setup still installs Homebrew Python.
- Tests cover the profile split.
- No global PyYAML or pip workaround is added.
- Any required current-machine cleanup is either performed after explicit approval or left as a clear manual follow-up.
