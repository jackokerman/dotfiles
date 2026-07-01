---
id: 2026-06-25-add-slop-scan-to-the-preferred-typescript-cli-stack
title: Add slop-scan to the preferred TypeScript CLI stack
state: inbox
createdAt: 2026-06-25T21:31:56.940Z
updatedAt: 2026-06-25T21:32:47.770Z
---

# Add slop-scan to the preferred TypeScript CLI stack

## Plan

Decide where and how to encode `slop-scan` as part of the preferred stack for new personal TypeScript/Bun CLI tools.

Context:

- A recent TypeScript CLI adopted `slop-scan@0.3.0` as a deterministic blocking check with a clean repo-local baseline.
- The intended benefit is early adoption: new tools get deterministic feedback from the beginning, avoiding later cleanup sessions and discouraging generated-code patterns before they become entrenched.
- The guidance likely belongs in the shared tool/config scaffolding path rather than only in individual repo AGENTS files.

Questions to resolve:

- Whether the default belongs in a reusable package/tool template, `typescript-style`, `codex-config-coach`, README/contributor guidance, or another tracked bootstrap surface.
- Whether the standard command should be a direct `slop-scan scan . --lint`, a JSON-parsing blocking wrapper, or a reusable helper package.
- What initial config policy should be recommended for new tools: zero exceptions by default, narrow repo-local exceptions only, and follow-up ratchet plans when exceptions are necessary.
- Whether existing personal tools should get a sweep: Jackie Plan first, then other Bun/TypeScript CLIs if applicable.

Acceptance criteria:

- There is a documented preferred-stack recommendation for `slop-scan` adoption in new TypeScript/Bun CLI repos.
- The recommendation includes dependency pinning, command shape, failure policy, and config policy.
- Existing candidate repos are either updated or have explicit follow-up plans.

## Agent handoff

Decide where and how to encode `slop-scan` as part of the preferred stack for new personal TypeScript/Bun CLI tools.

Context:

- A recent TypeScript CLI adopted `slop-scan@0.3.0` as a deterministic blocking check with a clean repo-local baseline.
- The intended benefit is early adoption: new tools get deterministic feedback from the beginning, avoiding later cleanup sessions and discouraging generated-code patterns before they become entrenched.
- The guidance likely belongs in the shared tool/config scaffolding path rather than only in individual repo AGENTS files.

Questions to resolve:

- Whether the default belongs in a reusable package/tool template, `typescript-style`, `codex-config-coach`, README/contributor guidance, or another tracked bootstrap surface.
- Whether the standard command should be a direct `slop-scan scan . --lint`, a JSON-parsing blocking wrapper, or a reusable helper package.
- What initial config policy should be recommended for new tools: zero exceptions by default, narrow repo-local exceptions only, and follow-up ratchet plans when exceptions are necessary.
- Whether existing personal tools should get a sweep: Jackie Plan first, then other Bun/TypeScript CLIs if applicable.

Acceptance criteria:

- There is a documented preferred-stack recommendation for `slop-scan` adoption in new TypeScript/Bun CLI repos.
- The recommendation includes dependency pinning, command shape, failure policy, and config policy.
- Existing candidate repos are either updated or have explicit follow-up plans.
