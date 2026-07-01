---
id: 2026-06-26-reduce-wasted-raw-find-tool-calls-in-codex-sessions
title: Reduce wasted raw find tool calls in Codex sessions
state: inbox
createdAt: 2026-06-26T01:06:53.102Z
updatedAt: 2026-06-30T03:12:34.131Z
---

# Reduce wasted raw find tool calls in Codex sessions

## Plan

Problem:
Agents sometimes attempt raw `find` commands during repository exploration, triggering a hook that blocks raw `find` and tells them to use `rg --files -g '<pattern>'` or Glob instead. In a recent repository inspection, another agent hit this twice before switching to `rg --files`. This wastes tool calls and creates noisy session output.

Why this is worth capturing:
This appears to be recurring friction, not just a one-off command mistake. Existing steering already says to prefer `rg`, but agents may still fall back to habitual `find`, so the fix may need to be more specific than another generic preference.

Preserve these details:

- The blocked hook feedback was: "Raw `find` is banned. Use `rg --files -g '<pattern>'` to find files by name, or use the Glob tool."
- The concrete behavior to prevent is exploratory raw `find` usage before trying `rg --files`.
- The desired outcome is fewer wasted pre-tool blocked calls, not removing the hook.
- Potential implementation surfaces include personal Codex steering, a more targeted skill/routing note, or hook feedback/behavior changes.
- Before changing always-loaded instructions, audit whether the existing `rg` guidance is too weak, duplicated, or in the wrong layer.

Suggested next step:
Inspect tracked Codex/dotty steering and hook implementation, then make the narrowest durable change that causes future agents to use `rg --files` first when locating files by name. Run the relevant dotty/check workflow if tracked config changes are made.

## Agent handoff

# Reduce wasted raw find tool calls in Codex sessions

Agents sometimes attempt raw `find` during repository exploration even though local guidance and hooks prefer `rg --files -g '<pattern>'` or Glob. This wastes blocked tool calls and adds noisy session output.

The follow-up should inspect tracked Codex/dotty steering and hook behavior, then make the narrowest durable change that causes future agents to use `rg --files` first when locating files by name. The goal is fewer blocked calls, not removing the hook.
