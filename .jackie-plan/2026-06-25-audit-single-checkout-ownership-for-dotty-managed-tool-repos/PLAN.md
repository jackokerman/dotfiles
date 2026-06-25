---
id: 2026-06-25-audit-single-checkout-ownership-for-dotty-managed-tool-repos
title: audit single-checkout ownership for dotty-managed tool repos
state: inbox
createdAt: 2026-06-25T15:55:17.861Z
updatedAt: 2026-06-25T15:55:17.861Z
---

# audit single-checkout ownership for dotty-managed tool repos

## Plan

## Why this exists

The current `tmux-agent-bar` setup now has both a development checkout under `~/src/tmux-agent-bar` and a managed runtime clone under `~/.local/share/tmux-agent-bar/repo`. That split made sense when the runtime checkout was only an install detail, but it is now causing ownership ambiguity and risks version drift.

## Goal

Decide which dotty-managed tools should have a single canonical checkout, which should stay runtime-only, and whether compatibility paths should be symlinks instead of separate clones.

## Preliminary inventory

- `tmux-agent-bar`
  - currently has both `~/src/tmux-agent-bar` and `~/.local/share/tmux-agent-bar/repo`
  - dotfiles scripts/docs still describe the `~/.local/share` clone as the default runtime path
  - likely candidate for one canonical `~/src` checkout plus optional compatibility symlink
- `jackie-plan`
  - already follows the preferred shape: canonical `~/src/jackie-plan`
  - compatibility path under `~/.local/share/jackie-plan/repo` is only a symlink when needed
- `tuicr`
  - still appears to be runtime-only under `~/.local/share/tuicr/repo`
  - likely fine if it remains install/use only, but should be reviewed if it becomes an actively developed personal tool
- `dotty`
  - local executable resolves to `~/.dotty/bin/dotty -> ~/.dotty/dotty`
  - ownership/update model should be verified before assuming it should follow the same repo-checkout pattern

## Questions to answer

- Which tools should be treated as active development repos versus runtime implementation details?
- For active development repos, should dotty standardize on a single canonical `~/src/<repo>` checkout?
- When compatibility with an old runtime path is still needed, should dotty create a symlink instead of a second clone?
- Should `tmux-agent-bar` now follow the same model as `jackie-plan`?
- Does `tuicr` still justify a runtime-only clone, or should its policy be documented more explicitly?
- Is `dotty` itself managed in a way that should be folded into the same ownership model, or is it intentionally separate?

## Concrete follow-ups

- Audit dotfiles docs, scripts, and tests that currently assume a managed `tmux-agent-bar` runtime clone.
- Propose one documented ownership model for actively developed personal tools.
- If the model changes, migrate `tmux-agent-bar` first and update wrapper path resolution, sync logic, and tests accordingly.
- Consider whether the broken `dotty guard-check` hook placeholder issue belongs in the same audit or should be split into a separate dotty follow-up after tool ownership is clarified.

## Notes

Directly editing a script in the canonical checkout should be picked up on the next invocation of that script path; shell re-sourcing only matters when the behavior depends on shell startup state, exported environment, or command resolution rather than the script file contents themselves.
