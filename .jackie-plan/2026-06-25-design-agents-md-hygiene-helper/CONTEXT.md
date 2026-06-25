---
id: 2026-06-25-design-agents-md-hygiene-helper
title: Design AGENTS.md hygiene helper
state: inbox
priority: normal
createdAt: 2026-06-25T19:28:25.578Z
updatedAt: 2026-06-25T23:56:16.755Z
---

The recent Markdown hard-wrap cleanup is another pressure scenario for AGENTS-file hygiene.

Key takeaway:

- Do not respond to a repeated style regression by stacking another temporary always-loaded AGENTS bullet if the base rule already exists.
- Prefer the narrowest durable surface: keep the thin universal invariant in base AGENTS, put workflow-specific reinforcement in the generating skill, and use a read-only audit/helper when the failure mode is drift rather than missing instruction.
- In this case the regression came from copied wrapped examples and plan artifacts, not from an absent global rule.
