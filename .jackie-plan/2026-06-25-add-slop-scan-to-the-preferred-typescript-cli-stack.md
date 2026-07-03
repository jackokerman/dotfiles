---
id: 2026-06-25-add-slop-scan-to-the-preferred-typescript-cli-stack
title: Add slop-scan to the preferred TypeScript CLI stack
state: complete
createdAt: 2026-06-25T21:31:56.940Z
updatedAt: 2026-07-03T17:38:41.829Z
---

# Add slop-scan to the preferred TypeScript CLI stack

## Plan

Close out the `slop-scan` preferred-stack decision.

The durable source of truth is `home/.ruler/skills/typescript-style/`. `SKILL.md` mentions `slop-scan` as part of the preferred validation stack for non-temporary Bun/TypeScript CLI tools that agents will edit or invoke repeatedly, and `references/tooling-defaults.md` owns the exact command and config policy.

The locked policy is:

- Keep `slop-scan` repo-local by default.
- Make the check blocking by parsing `slop-scan scan . --json` for `summary.findingCount`.
- Print `slop-scan scan . --lint` output when findings exist.
- Prefer a clean baseline with no repo-local config.
- Allow only narrow repo-local `slop-scan.config.json` exceptions when needed.
- Capture follow-up ratchet work when exceptions are introduced.
- Avoid a global wrapper until at least two repos need the same JSON/lint bridge.

Do not duplicate this guidance into `codex-config-coach`, README, or broad `AGENTS.md` steering unless a future workflow shows agents are missing the TypeScript skill path.

## Verification

Confirmed on 2026-07-03:

- `home/.ruler/skills/typescript-style/SKILL.md` points to the `slop-scan` validation default.
- `home/.ruler/skills/typescript-style/references/tooling-defaults.md` contains the command and config policy.
- The Godspeed API tooling plan includes `slop-scan` in its scaffold/check contract.
- No additional current Jackie Plan item obviously needs a `slop-scan` retrofit.

## Agent handoff

Closed out during planning/refinement on 2026-07-03. Fresh inspection showed the durable TypeScript tooling guidance already contains the `slop-scan` default and the Godspeed API tooling plan already includes `slop-scan` in its scaffold/check contract, so the plan was revised from an implementation question into a verification closeout artifact.
