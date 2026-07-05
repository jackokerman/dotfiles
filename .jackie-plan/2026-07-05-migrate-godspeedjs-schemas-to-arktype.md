---
id: 2026-07-05-migrate-godspeedjs-schemas-to-arktype
title: Migrate GodspeedJS schemas to ArkType
state: inbox
createdAt: 2026-07-05T19:28:04.253Z
updatedAt: 2026-07-05T19:34:23.208Z
sourcePlan: 2026-07-03-restore-godspeedjs-lint-standard-enforcement
---

# Migrate GodspeedJS schemas to ArkType

## Plan

Move `godspeed-js` from Valibot response schemas to ArkType as a focused schema-library migration before changing the public client object shape.

Rationale:

- ArkType appears to fit the preferred direction for Bun/TypeScript CLIs and agent-facing tooling: TypeScript-like schema syntax, runtime validation, inferred types via `typeof Schema.infer`, `.assert(...)` for throwing validation, and Standard Schema/JSON Schema interop.
- The schema-library migration should be separated from the later snake_case public API cleanup so validator semantics, error formatting, inferred types, response keys, and docs do not all change in one pass.
- The first migration should preserve current `godspeed-client` public behavior as much as practical; public camelCase response objects and existing CLI JSON expectations should not be deliberately changed in this plan.

Implementation scope:

- In `/Users/jackokerman/src/godspeed-js`, replace Valibot usage in `packages/godspeed-client/src/schemas.ts` with ArkType definitions.
- Update `parseResponse` and `GodspeedValidationError` handling in `packages/godspeed-client/src/index.ts` only as needed for ArkType validation results or thrown errors.
- Preserve the current exported client contract, including camelCase normalized resource types and the existing normalization layer, unless a small type export adjustment is strictly required by the ArkType migration.
- Update package dependencies from Valibot to ArkType.
- Update `godspeed-js` docs if they mention Valibot directly.
- Update dotfiles preferred TypeScript CLI/tooling guidance after the migration proves clean. The durable guidance should prefer or recommend ArkType for new Bun/TypeScript agent-facing CLI schema validation while still allowing existing Valibot/Zod use when already established.

Non-goals:

- Do not switch public Godspeed client resource objects from camelCase to snake_case in this plan.
- Do not remove `normalize.ts` or the manual public client resource types in this plan, except for incidental import/type adjustments required to keep the ArkType migration compiling.
- Do not consolidate the legacy `godspeed-tasks` compatibility CLI here; that remains tracked separately by `2026-07-03-consolidate-godspeed-task-compatibility-cli`.

Verification:

- In `/Users/jackokerman/src/godspeed-js`, run `bun run check`.
- Smoke the installed CLI shape if package exports or install behavior changes: `bun run install:local`, `godspeed --help`, and one no-write JSON command when credentials are available.
- In `/Users/jackokerman/dotfiles`, if preferred-stack guidance is updated, run the repo's relevant check path and propagate generated skill/config output as required by dotfiles workflow.

Review gate:

- Stop for review after the ArkType migration and preferred-stack guidance update are implemented and verified.
- Only proceed to the snake_case/schema-derived public type cleanup after this migration is reviewed and accepted.
