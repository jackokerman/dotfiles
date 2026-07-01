---
id: 2026-06-25-route-codex-config-coach-token-follow-up-to-dotfiles
title: Route codex-config-coach token follow-up to dotfiles
state: complete
createdAt: 2026-06-25T21:50:30.007Z
updatedAt: 2026-06-26T00:50:01.414Z
sourcePlan: 2026-06-25-continue-codex-token-audit
---

Resolved with a narrow `codex-config-coach` deferred-reference update in `home/.codex/skills/codex-config-coach/references/audit-details.md`: public-repo plan artifacts moved from private, local, or later-overlay roots should have source metadata and prose rewritten to the generic public purpose before staging, and should stay in the private/later-overlay root if that would lose necessary context.

Measured `codex-config-coach` with `plugin-eval analyze` and `plugin-eval explain-budget`. Static evaluation does not justify a larger structure change from this task alone; invoke cost is about 719 tokens and the added rule only increases deferred reference text. The next deeper step, if this skill becomes a real token hotspot, is measured usage rather than more static splitting.
