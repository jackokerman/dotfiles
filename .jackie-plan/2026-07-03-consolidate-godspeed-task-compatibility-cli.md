---
id: 2026-07-03-consolidate-godspeed-task-compatibility-cli
title: Remove Godspeed task compatibility CLI
state: ready-to-implement
createdAt: 2026-07-03T19:03:56.995Z
updatedAt: 2026-07-06T00:17:28.029Z
sourcePlan: 2026-07-03-build-godspeed-api-tooling
---

# Remove Godspeed task compatibility CLI

## Plan

Replace the legacy `godspeed-tasks` compatibility executable with first-class `godspeed` command-tree support, then update the dotfiles Godspeed skill and any local consumers to call `godspeed` directly.

This plan should run after `2026-07-05-simplify-godspeedjs-client-types` has landed, because the replacement commands should use the schema-derived snake_case `@jackokerman/godspeed-client` contract instead of preserving the old camelCase compatibility payloads.

The goal is not to preserve a second compatibility surface forever. We own the client, CLI, Codex skill, and local consumers end to end, so this is a deliberate breaking cleanup once `godspeed` has the high-level commands needed by the skill.

## Rationale

- The old high-level `godspeed-tasks` helper was moved into `godspeed-js` as a temporary compatibility executable so dotfiles could stop carrying a separate Godspeed-specific TypeScript project.
- Keeping that moved helper indefinitely preserves duplicate command parsing, duplicate task-shape types, file-level lint/type waivers, and camelCase compatibility payloads that no longer match the preferred API-shaped `godspeed-js` contract.
- The durable target is one maintained CLI surface: `godspeed`, backed by `@jackokerman/godspeed-client` and the current schema-derived snake_case API model.

## Implementation Scope

In `/Users/jackokerman/src/godspeed-js`:

- Add first-class `godspeed` subcommands for the high-level workflows currently provided only by `godspeed-tasks`:
  - `discover-lists`
  - `discover-labels`
  - `inbox-snapshot`
  - `task-snapshot`
  - `get-task`
  - `create-task`
  - `update-task`
  - `complete-task`
  - `delete-task`
  - `ensure-label`
  - `set-task-labels`
  - `remove-task-labels`
  - `reposition-task-block`
  - `preview-bulk-labeling`
  - `apply-bulk-labeling`
  - `smart-list-plan`
  - `ensure-smart-list`
- Back those workflows with shared `@jackokerman/godspeed-client` calls and the current snake_case client/resource contract.
- Preserve write-safety semantics while moving commands: destructive/live writes must remain behind explicit commands, and bulk-label workflows must keep preview/apply separation.
- Remove `packages/godspeed-cli/src/godspeed-tasks.ts` once its behavior is represented in the main command tree.
- Remove the `godspeed-tasks` bin from package metadata after dotfiles consumers are updated.
- Remove file-level lint/type waivers and moved legacy tests that only exist to tolerate the compatibility helper. Replace them with focused tests for the equivalent `godspeed` command-tree behavior.

In `/Users/jackokerman/dotfiles`:

- Update the tracked `godspeed-tasks` Codex skill to call the new `godspeed` commands directly, or rename/split the skill if the old name becomes misleading.
- Update docs that mention `godspeed-tasks` as an installed compatibility executable.
- Run `dotty update` after tracked skill or generated/live config changes so the live skill state reflects the repo.

## Non-Goals

- Do not preserve the `godspeed-tasks` executable solely for compatibility if all current consumers are updated in the same change.
- Do not add camelCase compatibility aliases or dual output shapes. Prefer updating consumers to the current `godspeed` JSON contract.
- Do not reintroduce Godspeed-specific TypeScript helper code into dotfiles.
- Do not weaken write-safety behavior for task mutation, label mutation, or smart-list creation.

## Verification

In `/Users/jackokerman/src/godspeed-js`:

- Run `bun run check`.
- Run `bun run install:local` after package bins or install behavior change.
- Run `godspeed --help` and representative new high-level command help output.
- Run `rg 'godspeed-tasks|packages/godspeed-cli/src/godspeed-tasks' package.json packages README.md docs tests` and confirm remaining references are absent or intentionally historical.
- When credentials are available, smoke read-only command paths that replace `godspeed-tasks` discovery and snapshot workflows.

In `/Users/jackokerman/dotfiles`:

- Run the relevant repo check path for skill/docs/config changes.
- Run `dotty update` after tracked skill or generated/live config changes.
- Run `rg 'godspeed-tasks' home docs README.md .jackie-plan` and confirm remaining references are absent or intentionally historical.
- Smoke the updated Godspeed skill entrypoints through their installed CLI commands when credentials are available.

## Review Gate

Stop for review after the compatibility executable is removed, dotfiles consumers point at `godspeed`, and verification passes.

Do not commit, push, mark complete, or archive without explicit approval after review.
