---
id: 2026-06-25-design-a-lightweight-codex-stop-hook-nudge
title: Design a lightweight Codex Stop hook nudge
state: inbox
createdAt: 2026-06-25T17:15:13.561Z
updatedAt: 2026-06-30T03:12:34.188Z
---

# Design a lightweight Codex Stop hook nudge

Evaluate whether a lightweight `Stop` hook should nudge or capture review input without launching a full agent or editing config automatically.

Constraints:

- Do not auto-edit `AGENTS.md`, skills, or config from the hook.
- Do not run a nested interactive/agentic Codex review on every `Stop` event.
- Keep any hook runtime short, deterministic, throttled, and recursion-safe.
- Preserve the existing tmux status `Stop` hook behavior.

Open questions include whether enough session metadata is available for useful nudging, whether a scheduled review is better than a turn-scoped hook, and whether this should wait until a manual session-review helper exists.
