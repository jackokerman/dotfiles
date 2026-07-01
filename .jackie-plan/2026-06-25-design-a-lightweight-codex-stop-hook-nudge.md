---
id: 2026-06-25-design-a-lightweight-codex-stop-hook-nudge
title: Design a lightweight Codex Stop hook nudge
state: inbox
createdAt: 2026-06-25T17:15:13.561Z
updatedAt: 2026-06-30T03:12:34.188Z
---

# Design a lightweight Codex Stop hook nudge

## Plan

## Context

The user asked whether their habit of running `codex-config-coach` after every session should be automated, possibly with a stop hook.

Relevant findings from the session:

- Codex supports hooks and the current `home/.codex/hooks.json` already defines lifecycle hooks for tmux status.
- Codex `Stop` hooks run at turn scope, not necessarily once at true session exit.
- `Stop` matchers are ignored.
- Multiple matching command hooks run concurrently.
- `async` hooks are parsed but skipped; `agent` and `prompt` handlers are parsed but skipped. Only command hooks run today.
- Running `codex exec` directly from a `Stop` hook would be risky/noisy unless recursion, permissions, and throttling are handled carefully.
- Public coding-agent guidance recommends hooks for deterministic automation and fresh-context reflection, but also recommends periodic meaningful reviews because stale config becomes drag.

## Goal

Evaluate a lightweight `Stop` hook that nudges or captures review input without launching a full agent or editing config automatically.

## Proposed design constraints

- Do not auto-edit `AGENTS.md`, skills, or config from the hook.
- Do not run a nested interactive/agentic Codex review on every `Stop` event.
- Prefer one of these low-risk behaviors:
  - write a small local note saying a long/corrective session may merit `codex-coach-latest-session`
  - throttle reminders, e.g. once per day or only after sessions with visible correction/friction markers if those can be detected cheaply
  - expose a manual command in the final report rather than interrupting the agent loop
- Avoid recursion by disabling hooks for any nested Codex invocation if one is ever added.
- Keep hook runtime short and deterministic.
- Preserve existing tmux status `Stop` hook behavior.

## Open questions

- Can the hook reliably access enough session metadata to know whether the session had real friction, or would it only be a time/counter based nudge?
- Should this be implemented as a separate command hook, or should the existing tmux status hook remain the only `Stop` hook and the nudge live elsewhere?
- Is a scheduled/weekly review better than a turn-scoped hook?
- Should this wait until `codex-coach-latest-session` exists so the hook can point at a concrete, tested command?

## Acceptance criteria

- A short design note or implementation plan decides whether to proceed.
- If implemented, the hook is throttled, report-only, and tested.
- The design explicitly handles recursion, command timeout, trust, and generated/live config propagation through `dotty update`.
- The hook does not increase routine session noise or token use materially.

## Routing

Generic personal Codex hook behavior belongs in the base dotfiles repo.

## Agent handoff

# Design a lightweight Codex Stop hook nudge

Evaluate whether a lightweight `Stop` hook should nudge or capture review input without launching a full agent or editing config automatically.

Constraints:

- Do not auto-edit `AGENTS.md`, skills, or config from the hook.
- Do not run a nested interactive/agentic Codex review on every `Stop` event.
- Keep any hook runtime short, deterministic, throttled, and recursion-safe.
- Preserve the existing tmux status `Stop` hook behavior.

Open questions include whether enough session metadata is available for useful nudging, whether a scheduled review is better than a turn-scoped hook, and whether this should wait until a manual session-review helper exists.
