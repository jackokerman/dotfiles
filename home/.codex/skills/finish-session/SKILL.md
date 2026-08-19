---
name: finish-session
description: "Use when asked to finish or close out a Codex session: verify completion, apply durable fixes from friction, capture follow-ups, and report avoidable context or token waste."
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
   - do not use existing guidance as the sole reason to skip a fix when the user reports recurrence; strengthen the narrowest owner, or explain why added steering would cost more than the likely savings;
   - update an existing owner before proposing a new skill.
4. Use `codex-config-coach` for any steering, skill, plugin, hook, MCP, or context-cost change. Apply clear bounded fixes now and complete the owning repository workflow. Capture a follow-up only when the change is larger, risky, ambiguous, or blocked.
5. Reconcile durable work tracking:
   - update an existing active plan when the session changed its status, decisions, or next step;
   - capture only actionable unfinished work in the applicable plan or task system;
   - do not create a follow-up for completed work, vague ideas, or a small fix that can be completed now.
   - persist session-owned plan artifacts through required commit and push on invocation. Stage only those paths; stop for overlap or unsafe remote state.
6. Audit efficiency with evidence. Run `codex-session-snippets --latest --usage` for current-session token counts. Do not estimate dollar cost, attribute tokens to individual skills, or inspect historical sessions unless the user explicitly requests historical analysis. Use `plugin-eval analyze` and `plugin-eval explain-budget` only for a specific suspect skill or plugin. Do not start paid benchmark runs without explicit approval.
7. Report a compact closeout:
   - outcome and verification;
   - durable improvements applied, or none;
   - plan or task updates, or none;
   - one concrete efficiency observation and its disposition: fix applied, concrete follow-up captured, or no action with a reason that addresses recurrence risk or steering cost;
   - unresolved blockers, if any.

Avoid numeric quality scores without a calibrated rubric and comparison set. Do not write a per-session report merely to prove that closeout ran.
