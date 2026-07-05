---
id: 2026-07-05-simplify-godspeedjs-client-types
title: Simplify GodspeedJS client types
state: inbox
createdAt: 2026-07-05T19:28:04.297Z
updatedAt: 2026-07-05T19:34:23.267Z
sourcePlan: 2026-07-03-restore-godspeedjs-lint-standard-enforcement
---

# Simplify GodspeedJS client types

## Plan

After the ArkType schema migration is accepted, simplify `godspeed-client` so validated schema-derived snake_case resource objects become the public client contract.

Rationale:

- `godspeed-js` is primarily for agent-facing CLIs and shell workflows, where matching the Godspeed API's JSON shape is simpler than maintaining an idiomatic JavaScript object facade.
- Returning schema-derived objects directly removes duplicate manual resource types, hand-written field JSDoc drift, and explicit response normalization for `list_id`, `label_ids`, `updated_at`, `timeless_due_at`, and similar API fields.
- The API-shape change should happen after the ArkType migration so the implementation can use the new schema definitions as the single source of truth.

Implementation scope:

- In `/Users/jackokerman/src/godspeed-js`, make the exported `GodspeedList`, `GodspeedLabel`, and `GodspeedTask` resource types derive from the response schemas.
- Delete response normalization helpers for resources, or reduce them to only the narrow endpoint compatibility logic that remains necessary for Godspeed's inconsistent envelope names such as `task` vs. `todo_item`.
- Update `createGodspeedClient` so resource-returning methods return validated snake_case objects directly.
- Update pagination and helper logic from camelCase resource fields to snake_case fields, for example `updatedAt` to `updated_at` and `listId` to `list_id`.
- Decide during implementation whether client input option objects should remain camelCase for ergonomics or also move to snake_case. Prefer the smallest change that removes response-type duplication without unnecessarily breaking call sites.
- Update `godspeed-cli` command-tree tests and JSON expectations for any changed output keys.
- Audit dotfiles consumers of the installed `godspeed` and `godspeed-tasks` CLIs. Update only the consumers or docs that actually depend on raw `godspeed` CLI output shape; keep the legacy high-level `godspeed-tasks` output stable unless deliberately consolidating that command in its own plan.

Non-goals:

- Do not migrate schemas to ArkType in this plan; that should already be complete.
- Do not introduce generic deep key conversion utilities such as `toCamelCaseKeys` or `toSnakeCaseKeys`. They add type opacity and can accidentally transform user-owned metadata keys.
- Do not consolidate the legacy `godspeed-tasks` compatibility CLI here; that remains tracked separately by `2026-07-03-consolidate-godspeed-task-compatibility-cli`.

Verification:

- In `/Users/jackokerman/src/godspeed-js`, run `bun run check`.
- Smoke CLI output shape for representative read commands, such as `godspeed lists --json`, `godspeed labels --json`, and `godspeed tasks list --json` when credentials are available.
- In `/Users/jackokerman/dotfiles`, run the relevant check path if any skill/docs/config consumers are updated, and run `dotty update` when tracked generated/live config needs propagation.

Review gate:

- Stop for review after the snake_case/schema-derived public type cleanup is implemented and verified.
- Treat this as a deliberate breaking API cleanup for the private `godspeed-js` client; do not add compatibility aliases unless a current consumer needs them.
