---
id: 2026-06-26-reduce-wasted-raw-find-tool-calls-in-codex-sessions
title: Reduce wasted raw find tool calls in Codex sessions
state: inbox
createdAt: 2026-06-26T01:06:53.102Z
updatedAt: 2026-06-30T03:12:34.131Z
---

# Reduce wasted raw find tool calls in Codex sessions

Agents sometimes attempt raw `find` during repository exploration even though local guidance and hooks prefer `rg --files -g '<pattern>'` or Glob. This wastes blocked tool calls and adds noisy session output.

The follow-up should inspect tracked Codex/dotty steering and hook behavior, then make the narrowest durable change that causes future agents to use `rg --files` first when locating files by name. The goal is fewer blocked calls, not removing the hook.
