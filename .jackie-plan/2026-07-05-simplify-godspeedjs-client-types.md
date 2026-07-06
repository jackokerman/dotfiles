---
id: 2026-07-05-simplify-godspeedjs-client-types
title: Simplify GodspeedJS client API shape
state: ready-to-implement
createdAt: 2026-07-05T19:28:04.297Z
updatedAt: 2026-07-06T00:17:27.988Z
sourcePlan: 2026-07-03-restore-godspeedjs-lint-standard-enforcement
---

# Simplify GodspeedJS client API shape

## Plan

After the ArkType schema migration is accepted, simplify `godspeed-client` so validated schema-derived snake_case resource objects become the public client contract, and make client input option objects snake_case as well.

This is a deliberate breaking API cleanup for a private, agent-facing TypeScript client and JSON-first CLI. The new contract should match the Godspeed API's JSON shape at the resource and client-input boundary instead of maintaining a parallel camelCase facade.

## Rationale

- `godspeed-js` is primarily for agent-facing CLIs and shell workflows, where matching the Godspeed API's JSON shape is simpler than translating every field into idiomatic JavaScript names.
- Returning schema-derived objects directly removes duplicate manual resource types, hand-written field JSDoc drift, and explicit response normalization for `list_id`, `label_ids`, `updated_at`, `timeless_due_at`, and similar API fields.
- Using snake_case for client input objects too keeps the contract consistent. Keeping camelCase inputs while returning snake_case outputs would preserve a split boundary and continue requiring body-conversion helpers for ordinary API fields.
- The ArkType migration is complete, so the implementation can use the new schema definitions as the single source of truth.

## Implementation Scope

In `/Users/jackokerman/src/godspeed-js`:

- Make exported resource types derive directly from ArkType schema outputs:
  - `GodspeedList = GodspeedListWire`
  - `GodspeedLabel = GodspeedLabelWire`
  - `GodspeedTask = GodspeedTaskWire`
- Change public client input types and call sites from camelCase fields to snake_case fields, including:
  - `listId` -> `list_id`
  - `taskId` -> `task_id`
  - `taskIds` -> `task_ids`
  - `updatedAfter` -> `updated_after`
  - `updatedBefore` -> `updated_before`
  - `completedAt` -> `completed_at`
  - `colorHexString` -> `color_hex_string`
  - task body fields such as `dueAt`, `durationMinutes`, `labelIds`, `startsAt`, `timelessDueAt`, and `timelessStartsAt` -> their API-shaped snake_case names.
- Keep non-API control fields in their natural local shape unless there is an API-field equivalent. For example, keep `signal`, `status`, `maxItems`, `method`, `path`, `body`, and `searchParams` unchanged unless implementation shows a concrete reason to rename them.
- Delete `normalizeList`, `normalizeLabel`, and `normalizeTask` response mappers. Delete or shrink `normalize.ts` to only the narrow request-body cleanup that remains necessary, such as removing `undefined` values before sending JSON.
- Update `createGodspeedClient` so resource-returning methods return validated snake_case objects directly.
- Update pagination and helper logic from camelCase resource fields to snake_case fields, for example `updatedAt` to `updated_at` and `nextUpdatedBefore` to `next_updated_before` in `TaskPage`.
- Keep command-line flag names stable (`--list-id`, `<task-id>`, `--json`) while translating those CLI flags into the new snake_case client input objects internally. Do not expose JavaScript-style input names in CLI flags.
- Update `godspeed-cli` command-tree tests and JSON expectations for changed raw `godspeed` output keys.
- Audit dotfiles consumers of the installed `godspeed` and `godspeed-tasks` CLIs. Update only consumers or docs that actually depend on raw `godspeed` CLI output shape.
- Do not preserve camelCase solely for compatibility. If the shared-client API cleanup breaks the legacy `godspeed-tasks` executable, update its internal calls or tests as needed for this migration, but keep full removal of the compatibility executable in `2026-07-03-consolidate-godspeed-task-compatibility-cli`.

## Non-Goals

- Do not migrate schemas to ArkType in this plan; that is already complete.
- Do not introduce generic deep key conversion utilities such as `toCamelCaseKeys` or `toSnakeCaseKeys`. They add type opacity and can accidentally transform user-owned metadata keys.
- Do not add camelCase compatibility aliases, dual input support, feature flags, or deprecation shims. This is a private breaking cleanup.
- Do not rename CLI flags from kebab-case to snake_case.
- Do not remove the legacy `godspeed-tasks` compatibility CLI here; that remains tracked separately by `2026-07-03-consolidate-godspeed-task-compatibility-cli`.

## Verification

In `/Users/jackokerman/src/godspeed-js`:

- Run `bun run check`.
- Run a focused audit such as `rg 'listId|taskId|taskIds|updatedAt|updatedAfter|updatedBefore|completedAt|colorHexString|durationMinutes|labelIds|timelessDueAt|timelessStartsAt' packages/godspeed-client packages/godspeed-cli/src/command-tree.ts tests README.md docs` and confirm remaining camelCase names are either intentionally local control fields, legacy `godspeed-tasks` implementation details awaiting the removal plan, or unrelated text.
- Run `bun run install:local`, `godspeed --help`, and `godspeed-tasks --help` if package install behavior, bin links, or CLI entrypoints change.
- Smoke raw `godspeed` CLI output shape for representative read commands when credentials are available, such as `godspeed lists --json`, `godspeed labels --json`, and `godspeed tasks list --json`.

In `/Users/jackokerman/dotfiles`:

- Run the relevant check path if any dotfiles skill/docs/config consumers are updated.
- Run `dotty update` when tracked generated/live config needs propagation.

## Review Gate

Stop for review after the snake_case/schema-derived public API cleanup is implemented and verified.

Do not commit, push, mark complete, archive, or start `2026-07-03-consolidate-godspeed-task-compatibility-cli` without explicit approval after review.
