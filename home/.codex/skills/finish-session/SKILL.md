---
name: finish-session
description: "Finish a Codex session: verify completion, improve steering from friction, capture durable follow-ups, and flag context or token waste. Use when asked to finish, close out, wrap up, end session, reflect, or run pre-close checks."
---

# Finish Session

Close the session without duplicating the workflows that own configuration, planning, task capture, or repository delivery.

## Workflow

1. Check the requested outcome and repository state. If required work or verification remains, finish it before closeout. Do not treat invocation as permission for unrelated external writes.
2. Review the visible session for concrete friction and useful context:
   - clear user corrections with an identifiable wrong action and corrected action;
   - repeated clarification, failed approaches, brittle workarounds, or unnecessary supervision;
   - context, skills, tools, searches, logs, diffs, polling, or output that materially helped or wasted time.
3. Apply the generalization gate to each possible learning:
   - derive the narrow rule that would prevent the class of failure;
   - search existing instructions, skills, and config for the rule;
   - skip an isolated incident or a rule that is already clear; this is an adherence failure, not a knowledge gap;
   - update an existing owner before proposing a new skill.
4. Use `codex-config-coach` for any steering, skill, plugin, hook, MCP, or context-cost change. Apply clear bounded fixes now and complete the owning repository workflow. Capture a follow-up only when the change is larger, risky, ambiguous, or blocked.
5. Reconcile durable work tracking:
   - update an existing active plan when the session changed its status, decisions, or next step;
   - capture only actionable unfinished work in the applicable plan or task system;
   - do not create a follow-up for completed work, vague ideas, or a small fix that can be completed now.
6. Audit efficiency with evidence. Run `codex-session-snippets --latest --usage` for current-session token counts. Do not estimate dollar cost, attribute tokens to individual skills, or inspect historical sessions unless the user explicitly requests historical analysis. Use `plugin-eval analyze` and `plugin-eval explain-budget` only for a specific suspect skill or plugin. Do not start paid benchmark runs without explicit approval.
7. Report a compact closeout:
   - outcome and verification;
   - durable improvements applied, or none;
   - plan or task updates, or none;
   - one concrete efficiency observation, or none;
   - unresolved blockers, if any.

Avoid numeric quality scores without a calibrated rubric and comparison set. Do not write a per-session report merely to prove that closeout ran.
