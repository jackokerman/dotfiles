---
id: 2026-06-25-build-report-only-codex-config-coach-session-review
title: Build report-only Codex config coach session review
state: inbox
createdAt: 2026-06-25T17:15:00.272Z
updatedAt: 2026-06-30T03:12:34.159Z
---

# Build report-only Codex config coach session review

## Plan

## Context

The user often manually runs `codex-config-coach` after sessions and asked whether that should be automated with a hook. We inspected Codex docs and local config:

- `home/.codex/hooks.json` already has a `Stop` hook, but only for tmux status.
- Codex docs say `Stop` runs at turn scope, not true session-exit scope.
- `Stop` matchers are ignored.
- Command hooks for the same event run concurrently.
- Hook `agent` and `prompt` handlers are parsed but skipped today; only command hooks run.
- `codex exec` exists for non-interactive automation, with `--ephemeral`, `--disable hooks`, and sandbox flags.
- `codex-config-coach` already has good guidance: repeated friction, cost audit, narrow durable surface, propose before high-impact edits.
- Local evaluation found the existing skill low risk and within a reasonable static token budget.

Public guidance from mature coding-agent workflows suggests stop hooks can reflect while context is fresh and propose config updates, but also recommends periodic meaningful reviews because stale instructions, skills, and hooks become overhead as models and tool harnesses improve.

## Goal

Create a manual, report-only workflow that gives the user the post-session `codex-config-coach` ritual without letting a hook automatically edit config after every turn.

## Proposed work

- Add a helper command, tentatively `codex-coach-latest-session`.
- Use the existing `codex-session-snippets` helper to gather bounded latest-session context instead of dumping a full transcript.
- Run `codex exec` in report-only mode, probably with:
  - `--ephemeral`
  - `--disable hooks` to avoid recursive hook behavior
  - a read-only or least-privilege sandbox
  - an explicit prompt invoking `$codex-config-coach`
- Output a short recommendation report with sections like:
  - observed friction
  - whether a durable rule is warranted
  - target surface, if any
  - proposed edit, not applied change
  - token/tool-surface opportunities
  - whether this should wait for a broader periodic review
- Do not modify tracked config by default.
- Consider an opt-in flag later for preparing a patch, but keep the first version read-only.

## Acceptance criteria

- Running the helper after a session produces a compact recommendation without editing files.
- It avoids broad transcript loading and avoids recursive hooks.
- It makes clear when no config update is warranted.
- It routes suggested changes to the right surface: `AGENTS.md`, a skill, a helper, plugin/MCP config, or a later overlay repo.
- It is documented enough that future agents know to use it instead of ad hoc transcript reads.

## Routing

Generic personal Codex setup belongs in the base dotfiles repo, especially because `codex-session-snippets` and `codex-config-coach` live there.

## Agent handoff

# Build report-only Codex config coach session review

Create a manual report-only workflow for the post-session `codex-config-coach` ritual without automatically editing config from a hook.

Likely shape:

- Add a helper such as `codex-coach-latest-session`.
- Gather bounded latest-session context with `codex-session-snippets`.
- Run `codex exec` in report-only mode with hooks disabled and least privilege.
- Output a compact recommendation with observed friction, whether durable steering is warranted, target surface, proposed edit, and token/tool-surface opportunities.

The first version should avoid broad transcript loading, recursive hooks, and tracked-file edits by default.
