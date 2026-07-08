---
id: 2026-06-26-reduce-wasted-raw-find-tool-calls-in-codex-sessions
title: Reduce wasted raw find tool calls in Codex sessions
state: complete
createdAt: 2026-06-26T01:06:53.102Z
updatedAt: 2026-07-08T22:10:43.010Z
---

# Reduce wasted raw find tool calls in Codex sessions

## Plan

Problem:
Agents sometimes attempt raw `find` commands during repository exploration before trying `rg --files`. On this machine, that can trigger a pre-tool guard that blocks raw `find` and reports: "Raw `find` is banned. Use `rg --files -g '<pattern>'` to find files by name, or use the Glob tool." This wastes tool calls and creates noisy session output.

Goal:
Reduce first-attempt blocked `find` calls by strengthening pre-tool steering. Do not remove or weaken the existing guard.

Confirmed context:

- `rg` is installed locally and `ripgrep` is already tracked in the base `Brewfile`.
- The active tracked Codex instruction source is `home/.ruler/AGENTS.md`; `home/.codex/AGENTS.md` remains the rollback source while `DOTTY_CODEX_RULER=0` is supported.
- Live generated `~/.codex/AGENTS.md` already includes the base `rg` guidance plus a later overlay's broader local-inspection guidance.
- The tracked base Codex hooks only contain tmux status hooks. The raw-`find` blocker was not found in tracked base or later-overlay Codex hook sources, so it appears to come from a harness/tool-runner guard outside the tracked Codex hook file.
- The current base guidance says to prefer `rg` tools directly, but it does not front-load filename discovery strongly enough to prevent habitual raw `find` attempts.

Preferred design:
Update the existing always-on base `Research Workflow` bullet in `home/.ruler/AGENTS.md` so filename discovery explicitly starts with `rg --files` or `rg --hidden --files`, with `rg --files -g '<pattern>'` for globs. Mention raw `find` only as a fallback when `rg` is unavailable or when a specific `find` predicate is genuinely needed after narrowing the path. Keep the content-search preference for `rg '<pattern>'` over recursive `grep`.

Keep the rollback Codex instruction source in `home/.codex/AGENTS.md` aligned with the same wording while that fallback remains tracked.

Do not add a new skill for this. File discovery is a universal working habit, not a task-specific workflow, and a skill would load too late unless explicitly triggered. Do not add another hook for this. The problem is avoiding the first blocked tool call; another hook would only enforce after the model already chose the wrong command, and a guard already exists.

Expected edit shape:
Replace the existing base `Research Workflow` bullet with wording close to:

```md
- For file discovery by name, start with `rg --files` or `rg --hidden --files`; use `rg --files -g '<pattern>'` for filename globs. Use raw `find` only when `rg` is unavailable or when you specifically need `find` predicates after narrowing the path. Use `rg '<pattern>'` for content search instead of recursive `grep`.
```

Then mirror the same fallback-source wording in `home/.codex/AGENTS.md` if the old dotty-only path remains supported.

## Verification

After editing tracked sources:

1. Run `dotty update` so live `~/.codex/AGENTS.md` regenerates from tracked Ruler sources.
2. Run `./scripts/check --staged --quiet` for commit-like validation.
3. Optionally inspect the generated `~/.codex/AGENTS.md` only if propagation is suspect; normal Ruler propagation can be trusted after checks pass.

## Non-goals

- Do not remove or weaken the existing raw-`find` guard.
- Do not add a new Codex hook for this behavior.
- Do not add new dependency installation logic for `ripgrep` unless verification shows it is missing from a target machine class.
- Do not add a broad command cookbook or detailed examples to always-loaded guidance.

## Agent handoff

Design pass completed during user-led refinement.

Settled direction:
- Treat this as a pre-tool steering problem, not a hook implementation problem.
- Update always-on base guidance in `home/.ruler/AGENTS.md` so file discovery by name starts with `rg --files` / `rg --hidden --files`, with raw `find` only as an explicit fallback when `rg` is unavailable or when a real `find` predicate is needed after narrowing.
- Keep `home/.codex/AGENTS.md` aligned as the rollback source while that path remains supported.
- Do not add a skill, hook, or dependency install change.

Evidence gathered:
- `rg` and `fd` are installed locally; `ripgrep` is already tracked in the base `Brewfile`.
- Live generated `~/.codex/AGENTS.md` already includes generic `rg` guidance, but it is not specific enough to stop habitual raw `find` attempts.
- Tracked Codex hooks in base/live config are only tmux status hooks. The raw-`find` blocker appears to be an external harness/tool-runner guard rather than a tracked dotfiles Codex hook.
- Codex manual guidance supports using `AGENTS.md` for durable pre-work instructions and hooks for lifecycle enforcement at tool-use time; because the goal is avoiding the first blocked call, `AGENTS.md` is the right primary surface.
