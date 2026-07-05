---
id: 2026-07-03-restore-godspeedjs-lint-standard-enforcement
title: Restore GodspeedJS lint-standard enforcement
state: complete
createdAt: 2026-07-03T19:16:41.883Z
updatedAt: 2026-07-05T19:33:53.554Z
sourcePlan: 2026-07-03-build-godspeed-api-tooling
---

# Restore GodspeedJS lint-standard enforcement

## Plan

The initial `godspeed-js` scaffold used eslint suppressions too broadly, including disabling JSDoc enforcement on first-class client/schema/type code. That conflicts with the intended standards: lint rules are repo guidance and should be satisfied unless there is a narrow, documented exception.

Follow up in `/Users/jackokerman/src/godspeed-js`:

- remove JSDoc-related eslint disables from first-class `godspeed-client` and `godspeed-cli` source files;
- add proper JSDoc to exported public types, functions, and contract-bearing fields instead of disabling the rule;
- audit eslint and oxlint suppressions added during the scaffold and keep only narrow suppressions with concrete reasons;
- leave any temporary legacy-helper waivers only where tied to `2026-07-03-consolidate-godspeed-task-compatibility-cli`, and remove them when that compatibility surface is consolidated;
- run `bun run check` before shipping.

Non-goal: do not make another dotfiles/Codex steering update for lint-disable behavior in this plan; that guidance has already been handled separately.

## Agent handoff

Implemented the ready contract in `/Users/jackokerman/src/godspeed-js`: removed broad JSDoc-related eslint disables from first-class `godspeed-client` source files, added JSDoc to exported public client types, method inputs/results, error classes, schema wire types, and normalization helpers, and kept only the legacy compatibility/test suppressions that match the plan's exception criteria. Verification passed with `bun run check`.
