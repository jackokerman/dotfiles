---
id: 2026-07-03-consolidate-godspeed-task-compatibility-cli
title: Consolidate Godspeed task compatibility CLI
state: inbox
createdAt: 2026-07-03T19:03:56.995Z
updatedAt: 2026-07-03T19:03:56.995Z
sourcePlan: 2026-07-03-build-godspeed-api-tooling
---

# Consolidate Godspeed task compatibility CLI

## Plan

The dotfiles Godspeed migration moved the old high-level `godspeed-tasks` helper into the private `godspeed-js` repo as a compatibility executable so dotfiles could stop carrying the helper and its Godspeed-specific TypeScript dependency.

Follow up by folding that compatibility command surface into the stricter `godspeed`/`godspeed-cli` command tree:

- replace the moved legacy helper internals with shared `@jackokerman/godspeed-client` calls;
- remove the file-level lint and `@ts-nocheck` waivers from `packages/godspeed-cli/src/godspeed-tasks.ts` and its moved tests;
- keep the installed `godspeed-tasks` bin or provide a documented migration path for the Codex skill;
- preserve current high-level workflows: list discovery, label discovery/ensure, inbox/task snapshots, create/update/move/complete, bulk label preview/apply, and smart-list planning/ensure;
- keep destructive/live writes gated by explicit commands and tests.

This is intentionally separate from the dotfiles integration because the migration needed to preserve behavior first and remove dotfiles-owned TypeScript project surface.
