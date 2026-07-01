---
id: 2026-06-25-make-dotty-agent-output-generation-target-aware
title: Make dotty agent output generation target-aware
state: inbox
createdAt: 2026-06-25T01:02:56.584Z
updatedAt: 2026-06-30T03:12:53.048Z
---

# Make dotty agent output generation target-aware

## Plan

## Source

Captured from a Codex config-coach discussion about whether dotty should keep generating Claude runtime files when the current workflow only uses Codex.

## Friction

Dotty's Ruler-backed portable path currently generates Codex and Claude outputs together when portable skills are present. That keeps outputs consistent, but it also creates live `~/.claude` artifacts even when Claude is not actively used.

Disabling Claude is not a small cleanup today because the target list is baked into hook branching, `sync-ruler.ts` portable mode, tests, and docs.

## Goal

Add an explicit tracked config surface for enabled coding-agent targets, so dotty can generate only the requested runtime outputs and clean up disabled managed outputs safely.

## Candidate shape

- Add a tracked target config near `home/.ruler/ruler.toml` or `home/.codex/`, with enabled targets such as `codex` and `claude`.
- Teach `sync-ruler.ts` to accept a target list for portable output instead of hardcoding `codex` plus `claude`.
- Teach dotty hooks to generate outputs only for enabled targets.
- Remove only dotty-managed disabled outputs, using generated headers and `.dotty-managed-skills.tsv` as safety checks.
- Preserve rollback/fallback paths like `DOTTY_CODEX_RULER=0` until they are intentionally retired.

## Acceptance criteria

- Codex-only config generates `~/.codex/AGENTS.md` and `~/.codex/skills/` without refreshing `~/.claude/CLAUDE.md` or `~/.claude/skills/`.
- Re-enabling Claude regenerates Claude outputs from the same tracked sources.
- Disabling Claude removes only generated/dotty-managed Claude outputs, not unrelated Claude runtime state.
- Tests cover target selection and cleanup behavior in `sync-ruler` and the hook path.
- Docs explain where to select enabled agent targets and how cleanup safety works.

## Agent handoff

# Make dotty agent output generation target-aware

Add an explicit tracked config surface for enabled coding-agent targets, so dotty can generate only requested runtime outputs and clean up disabled managed outputs safely.

Candidate shape:

- Add a tracked target config near the Ruler or Codex config sources.
- Teach `sync-ruler.ts` and dotty hooks to generate only enabled targets.
- Remove only dotty-managed disabled outputs using generated headers and managed-skill indexes as safety checks.
- Preserve rollback paths until they are intentionally retired.

Acceptance criteria include Codex-only generation, re-enabling Claude outputs from the same tracked sources, safe cleanup of generated Claude outputs, tests for target selection/cleanup, and docs for target selection.
