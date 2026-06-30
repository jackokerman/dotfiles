---
id: 2026-06-25-build-report-only-codex-config-coach-session-review
title: Build report-only Codex config coach session review
state: inbox
createdAt: 2026-06-25T17:15:00.272Z
updatedAt: 2026-06-30T03:12:34.159Z
---

# Build report-only Codex config coach session review

Create a manual report-only workflow for the post-session `codex-config-coach` ritual without automatically editing config from a hook.

Likely shape:

- Add a helper such as `codex-coach-latest-session`.
- Gather bounded latest-session context with `codex-session-snippets`.
- Run `codex exec` in report-only mode with hooks disabled and least privilege.
- Output a compact recommendation with observed friction, whether durable steering is warranted, target surface, proposed edit, and token/tool-surface opportunities.

The first version should avoid broad transcript loading, recursive hooks, and tracked-file edits by default.
