---
id: 2026-07-05-migrate-godspeedjs-schemas-to-arktype
title: Migrate GodspeedJS schemas to ArkType
state: complete
createdAt: 2026-07-05T19:28:04.253Z
updatedAt: 2026-07-06T00:07:42.104Z
sourcePlan: 2026-07-03-restore-godspeedjs-lint-standard-enforcement
---

# Migrate GodspeedJS schemas to ArkType

## Plan

Fully migrate `godspeed-js` from Valibot to ArkType, then update the reusable dotfiles TypeScript tooling guidance so new owned Bun/TypeScript agent-facing CLIs prefer ArkType for runtime schemas going forward.

This is the schema-library migration only. Preserve the current `godspeed-client` public resource shape and CLI JSON behavior in this plan; the later snake_case/schema-derived public type cleanup is tracked separately by `2026-07-05-simplify-godspeedjs-client-types`.

## Rationale

ArkType fits the preferred direction for Bun/TypeScript CLIs and agent-facing tooling: TypeScript-like schema syntax, runtime validation, inferred types via `typeof Schema.infer`, throwing validation through `.assert(...)`, and Standard Schema/JSON Schema interop. Separating this migration from the later public API-shape cleanup keeps validator semantics, error formatting, dependency changes, response keys, tests, and docs reviewable.

## Implementation Scope

In `/Users/jackokerman/src/godspeed-js`:

- Replace Valibot usage in `packages/godspeed-client/src/schemas.ts` with ArkType definitions.
- Preserve exported wire type names such as `GodspeedListWire`, `GodspeedLabelWire`, and `GodspeedTaskWire`, but derive them from ArkType schemas.
- Update `packages/godspeed-client/src/index.ts` so `parseResponse` validates through ArkType instead of `v.safeParse` / `v.InferOutput`.
- Preserve the existing normalized camelCase public client contract and existing CLI JSON expectations. Do not deliberately change response keys in this plan.
- Remove Valibot imports from source code and remove Valibot from `package.json`, `packages/godspeed-client/package.json`, and the lockfile.
- Add ArkType to the appropriate package dependencies and update the lockfile with Bun.
- Update `godspeed-js` docs only if they mention Valibot, schema inference, or validation-library details directly.

In `/Users/jackokerman/dotfiles`:

- Update `home/.ruler/skills/typescript-style/references/tooling-defaults.md` so the Runtime Data Boundaries guidance prefers ArkType for new owned TypeScript tools when a schema library is useful and there is no stronger local pattern.
- Keep the guidance pragmatic: existing Valibot/Zod usage does not need churn merely because ArkType becomes the default for new work.
- Run the normal dotfiles validation for the tracked skill/reference change, and run `dotty update` if generated/live Codex skill output needs propagation.

## Non-Goals

- Do not switch public Godspeed client resource objects from camelCase to snake_case in this plan.
- Do not remove `normalize.ts` or the manual public client resource types in this plan, except for incidental import/type adjustments required to keep the ArkType migration compiling.
- Do not introduce generic key-conversion utilities.
- Do not consolidate the legacy `godspeed-tasks` compatibility CLI here; that remains tracked separately by `2026-07-03-consolidate-godspeed-task-compatibility-cli`.
- Do not start `2026-07-05-simplify-godspeedjs-client-types` until this migration is reviewed and accepted.

## Verification

In `/Users/jackokerman/src/godspeed-js`:

- Run `bun run check`.
- Run `rg 'valibot|from "valibot"|from "arktype"' package.json packages bun.lock` or an equivalent audit to confirm Valibot is removed and ArkType is the active schema dependency.
- If package exports, install behavior, or CLI runtime behavior changes, run `bun run install:local`, `godspeed --help`, and one no-write JSON command when credentials are available.

In `/Users/jackokerman/dotfiles`:

- Run `./scripts/check --staged --quiet` for the preferred tooling guidance update.
- If `dotty update` is needed for generated/live skill propagation, run it after the intended tracked files are committed or when the implementation handoff explicitly calls for live verification.

## Review Gate

Stop for review after the ArkType migration and preferred-stack guidance update are implemented and verified. Do not mark the plan complete, commit, push, or start the snake_case/schema-derived public type cleanup without explicit approval for that follow-through.

## Agent handoff

Implemented the ArkType migration and dotfiles TypeScript guidance update through the review gate.

GodspeedJS changes in `/Users/jackokerman/src/godspeed-js`:
- Replaced Valibot schemas in `packages/godspeed-client/src/schemas.ts` with ArkType `type(...)` definitions while preserving existing wire type exports via `typeof schema.infer`.
- Updated `packages/godspeed-client/src/index.ts` `parseResponse` to call ArkType validators directly, branch on `ArkErrors`, and continue wrapping failures as `GodspeedValidationError`.
- Replaced `valibot` with `arktype@^2.2.2` in root and client package manifests and regenerated `bun.lock`.

Dotfiles changes in `/Users/jackokerman/dotfiles`:
- Updated `home/.ruler/skills/typescript-style/references/tooling-defaults.md` so Runtime Data Boundaries prefer `arktype` for new owned TypeScript tools, without churning existing Valibot/Zod usage.

Verification passed:
- `/Users/jackokerman/src/godspeed-js`: `bun run check`
- `/Users/jackokerman/src/godspeed-js`: `rg 'valibot|from "valibot"|from "arktype"' package.json packages bun.lock` showed no Valibot references and ArkType imports in active source.
- `/Users/jackokerman/dotfiles`: staged only the guidance file, ran `./scripts/check --staged --quiet`, then unstaged it for review.

Stopped for review per plan. Do not commit, push, mark ready-to-ship, complete, archive, or start `2026-07-05-simplify-godspeedjs-client-types` without explicit user approval.
