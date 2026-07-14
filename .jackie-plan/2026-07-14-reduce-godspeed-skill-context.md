---
id: 2026-07-14-reduce-godspeed-skill-context
title: Reduce Godspeed skill context
state: complete
createdAt: 2026-07-14T05:45:34.968Z
updatedAt: 2026-07-14T05:53:31.018Z
sourcePlan: 2026-07-14-extract-gtd-workflow-cli
---

# Reduce Godspeed skill context

## Plan

# Objective

Reduce the active context cost of the tracked `godspeed-tasks` skill without weakening its Godspeed workflow coverage, mutation safeguards, or inbox-triage behavior.

# Baseline

The tracked source is `home/.ruler/skills/godspeed-tasks/`, and both Codex and Claude managed indexes resolve their live skill to that directory.

Current static measurements from `plugin-eval`:

- 5,598-byte `SKILL.md`, 116 lines
- 87 trigger tokens
- 1,396 invoke tokens
- 96 deferred tokens
- 1,579 total tokens
- score 81/100, grade C, with invoke cost reported as excessive

The completed GTD CLI extraction now provides deterministic `godspeed-gtd --help` output, so the skill no longer needs to carry a near-complete command catalog in active context.

# Approach

- Shorten the skill description while preserving reliable triggering for Godspeed discovery, inbox review, task capture, completion, labels, and smart-list work.
- Keep workflow routing, Work/Personal separation, authentication guidance, mutation approval rules, inbox-triage outcomes, and local-evidence policy in active skill text.
- Remove or consolidate command examples and explanatory prose that duplicate `godspeed-gtd --help` or the tracked `godspeed-js` agent documentation.
- Prefer directing agents to the deterministic CLI help for uncommon syntax over adding a large deferred prose reference.
- Keep the smart-list API caveat if it remains necessary to prevent incorrect verification; move it to a short deferred reference only if doing so clearly reduces active context without making the normal workflow brittle.
- Do not add a helper, MCP, plugin, compatibility path, configuration knob, or second skill.

# Verification

- Run `plugin-eval analyze home/.ruler/skills/godspeed-tasks --format markdown` and `plugin-eval explain-budget home/.ruler/skills/godspeed-tasks --format markdown` before and after the edit.
- Require a material reduction from the 87 trigger-token and 1,396 invoke-token baselines; do not delete required safety policy merely to optimize the score.
- Review the compacted skill against these representative workflows:
  - discover lists and summarize a scoped inbox;
  - capture and complete an explicit task;
  - preview before heuristic or bulk labeling;
  - create or verify a smart list without trusting task queries for membership;
  - use local evidence only when the normalized task marks it eligible.
- Confirm the tracked source contains `godspeed-gtd` and no stale `godspeed gtd` invocation.
- Run `./scripts/check --quiet`, commit the tracked source, run `dotty update`, and verify both managed indexes and live Codex/Claude skill outputs still resolve to the tracked source.

# Completion criteria

- The skill retains all current Godspeed management capabilities and approval boundaries.
- Trigger and invoke costs are measurably lower, with the before/after report recorded in the implementation handoff.
- The live generated skills match the tracked source after `dotty update`.
- The dotfiles change is committed with a conventional commit and pushed to `main` with a clean worktree.

# Non-goals

- Changing `godspeed` or `godspeed-gtd` command behavior.
- Changing the mirrored GTD taxonomy or personal category data.
- Running live task mutations as validation.
- Creating a full `plugin-eval` benchmark or real Codex-session measurement without separate approval.

## Agent handoff

Implementation is code-complete and awaiting review.

- Reduced the tracked `godspeed-tasks` skill from 5,598 bytes/116 lines to approximately 2,670 bytes/41 lines while retaining workflow routing, Work/Personal separation, authentication, mutation safeguards, smart-list verification, inbox outcomes, and local-evidence policy.
- Delegated uncommon command syntax to deterministic `godspeed-gtd --help`.
- Regenerated `agents/openai.yaml` with compact matching UI metadata.
- `plugin-eval` improved from 81/C to 100/A. Trigger cost changed from 87 to 64 tokens, invoke cost from 1,396 to 666, deferred cost from 96 to 65, and total cost from 1,579 to 795.
- Skill Creator validation and `./scripts/check --quiet` pass. No full benchmark or live task mutation was run.
- Commit, `dotty update`, live managed-skill verification, push, and plan completion remain behind the review gate.

Process notes

- The system Skill Creator generator and validator again required `PyYAML`, which is absent from system Python. A temporary `/tmp` virtual environment was used successfully. This repeats the earlier migration-session friction, but no tracked workaround was added because these system scripts are occasional and the repo's normal check path already validates the tracked skill.
