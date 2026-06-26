---
id: 2026-06-26-explore-leaner-dotty-run-file-structure
title: Explore leaner dotty run file structure
state: complete
createdAt: 2026-06-26T15:53:34.972Z
updatedAt: 2026-06-26T16:17:03.524Z
---

# Explore leaner dotty run file structure

## Plan

## Goal
Decide whether dotty run files should stay as thin orchestration entrypoints that delegate real logic to separate runnable scripts, and identify any other worthwhile run-file structure improvements.

## Exploration Summary
The current structure already uses the right pattern for most `dotty run` commands: `.dotty/commands/brew-sync`, `install-nvim-js-tools`, `macos-setup`, `sync-dev-checkouts`, and `sync-tmux-agent-bar` are 6-7 line wrappers that resolve the repo root and `exec` a script under `scripts/`. That is the convention worth preserving.

The two meaningful exceptions are:

- `.dotty/run.sh` is a 689-line post-link hook that mixes orchestration, small generated-config renderers, and full install/update workflows.
- `.dotty/commands/install-jackie-plan` is a 50-line command wrapper with real clone, update, compatibility symlink, and installer dispatch behavior inline.

The cleanup run files are not the same problem. They are one-shot migration units under `.dotty/cleanups/`, and their logic is tightly coupled to the cleanup receipt model. Keeping them inline is acceptable unless a cleanup grows enough reusable behavior to deserve a tested helper.

## Recommendation
Keep `.dotty/commands/<name>` as thin command entrypoints. The default shape should be:

- `set -euo pipefail`
- resolve `REPO_ROOT` or `PROJECT_ROOT`
- `exec "$REPO_ROOT/scripts/<name>.sh" "$@"`

Extract logic when a run file or command file has a standalone invocation surface, needs focused tests, or owns a workflow that may be debugged outside `dotty update`. Do not extract tiny generated-config renderers solely to reduce line count when the behavior is only meaningful inside the post-link hook.

The first refactor should be `setup_tuicr` in `.dotty/run.sh`. It is a complete managed-checkout workflow, already has behavior tests in `tests/tuicr/test-setup.sh`, and is the clearest mismatch with the hook's role as an orchestration entrypoint. Move it to `scripts/sync-tuicr.sh`, have `.dotty/run.sh` delegate to that script, and update the tests to target the script directly instead of sourcing `.dotty/run.sh`.

The second refactor should be `.dotty/commands/install-jackie-plan`. Move its behavior to `scripts/install-jackie-plan.sh` and leave the dotty command as a thin wrapper. Add focused tests around clone failure tolerance, compatibility symlink creation, and existing checkout handling before or during that move.

Leave these inline for now:

- `setup_sesh` and `setup_glow`, because they generate live config from chain-aware tracked fragments and are naturally part of the post-link hook.
- `setup_codex`, until a separate Codex sync command or more granular tests need to invoke the whole hook-owned sync flow directly.
- cleanup `run.sh` files, unless a specific cleanup gets large or reusable.

## Follow-Up Order
1. Extract `setup_tuicr` to `scripts/sync-tuicr.sh` and retarget `tests/tuicr/test-setup.sh`.
2. Extract `install-jackie-plan` to `scripts/install-jackie-plan.sh` and add focused tests.
3. Revisit `setup_codex` only if Codex sync debugging continues to require sourcing `.dotty/run.sh` or if the hook keeps growing.

## Non-Goals
Do not assume every run file needs extraction. Do not optimize for abstract flexibility without a concrete maintenance or testing win. Do not move one-shot cleanup logic just to satisfy a uniform file layout.
