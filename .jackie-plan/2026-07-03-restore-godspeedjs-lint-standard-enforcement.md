---
id: 2026-07-03-restore-godspeedjs-lint-standard-enforcement
title: Restore GodspeedJS lint-standard enforcement
state: inbox
createdAt: 2026-07-03T19:16:41.883Z
updatedAt: 2026-07-03T19:16:41.883Z
sourcePlan: 2026-07-03-build-godspeed-api-tooling
---

# Restore GodspeedJS lint-standard enforcement

## Plan

The initial `godspeed-js` scaffold used lint suppressions too broadly, including disabling JSDoc enforcement on first-class client/schema/type code. That conflicts with the intended standards: lint rules are repo guidance and should be satisfied unless there is a narrow, documented exception.

Follow up in `/Users/jackokerman/src/godspeed-js`:

- remove JSDoc-related suppressions from first-class `godspeed-client` and `godspeed-cli` source files;
- add proper JSDoc to exported public types, functions, and contract-bearing fields instead of disabling the rule;
- audit all eslint/oxlint suppressions added during the scaffold and keep only narrow suppressions with concrete reasons;
- leave any temporary legacy-helper waivers only where tied to `2026-07-03-consolidate-godspeed-task-compatibility-cli`, and remove them when that compatibility surface is consolidated;
- run `bun run check` before shipping.

Also consider whether dotfiles/Codex steering should explicitly tell agents not to haphazardly disable lint rules that encode the user's standards.
