---
id: 2026-06-25-make-dotty-agent-output-generation-target-aware
title: Make dotty agent output generation target-aware
state: inbox
createdAt: 2026-06-25T01:02:56.584Z
updatedAt: 2026-06-30T03:12:53.048Z
---

# Make dotty agent output generation target-aware

Add an explicit tracked config surface for enabled coding-agent targets, so dotty can generate only requested runtime outputs and clean up disabled managed outputs safely.

Candidate shape:

- Add a tracked target config near the Ruler or Codex config sources.
- Teach `sync-ruler.ts` and dotty hooks to generate only enabled targets.
- Remove only dotty-managed disabled outputs using generated headers and managed-skill indexes as safety checks.
- Preserve rollback paths until they are intentionally retired.

Acceptance criteria include Codex-only generation, re-enabling Claude outputs from the same tracked sources, safe cleanup of generated Claude outputs, tests for target selection/cleanup, and docs for target selection.
