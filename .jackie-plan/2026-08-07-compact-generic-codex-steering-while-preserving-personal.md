---
id: 2026-08-07-compact-generic-codex-steering-while-preserving-personal
title: Compact generic Codex steering while preserving personal defaults
state: inbox
createdAt: 2026-08-07T01:09:26.458Z
updatedAt: 2026-08-07T01:13:52.188Z
sourcePlan: 2026-08-07-sequence-codex-steering-cleanup-across-dotty-layers
---

# Compact generic Codex steering while preserving personal defaults

## Plan

## Objective

Reduce the always-loaded generic Codex instruction budget while preserving durable communication style, engineering preferences, and cross-repository workflow boundaries.

## Current evidence

- `home/.ruler/AGENTS.md` is 18.8 KiB and about 2,779 words.
- The largest sections are execution workflow, research workflow, engineering style, tool adoption, writing workflow, and Dotfiles workflow.
- Some content restates built-in Codex behavior, while detailed Dotfiles and task-specific procedure can be routed to repository instructions or existing skills.

## Scope

- Refresh the base source and regenerated live instruction budget before editing.
- Preserve concise personal communication, implementation-style, research-source, and configuration-ownership invariants that materially differ from default Codex behavior.
- Move Dotfiles-only commit, push, check, Dotty propagation, and cleanup procedure into the repository `AGENTS.md` or the owning skill.
- Move task-specific writing, README, frontend, Neovim, Godspeed, and Codex-configuration procedure into the existing routed skills and deferred references.
- Remove exact duplicates and rules that merely restate active built-in Codex steering without adding a personal policy difference.
- Keep the generated Ruler source chain and managed-skill ownership explicit but concise.

## Non-goals

- Do not change unrelated personal tooling behavior.
- Do not add a new AGENTS hygiene helper unless implementation exposes a repeated deterministic check that existing `codex-config-coach` guidance cannot cover.
- Do not optimize individual skill bodies before the post-cleanup measurement.

## Behavior-preservation method

Classify every removed rule as one of: retained universal preference, repository-local instruction, routed skill content, deferred reference, deterministic helper/check, exact duplicate, built-in restatement, or obsolete rule. Preserve or relocate the first five; delete only the last three when evidence supports it.

## Verification

- Run the appropriate broad `dotfiles` checks, including the extended lane because this changes generated Codex behavior.
- Apply the tracked source through the documented Dotty workflow and confirm the live source header and managed skill index.
- Measure the base source and final live global `AGENTS.md` size.
- In a fresh Codex session outside a work overlay, exercise concise drafting, a simple code change, README work, shell-script work, frontend work, and a Dotfiles change to confirm routing and personal style remain intact.
- Re-check repository status, commit with a conventional commit, and push to `main` through the normal workflow.

## Success target

Reduce the base source from 18.8 KiB to approximately 8–10 KiB without a pressure-scenario regression.

## Next honest step

Refresh the live baseline, then build the base rule-classification map before editing.

## Agent handoff

### Resume state

The draft contract was reviewed on 2026-08-06 and intentionally remains `inbox` so its live baseline can be refreshed before promotion.

Resume planning from the owning root:

```bash
cd /Users/jackokerman/dotfiles
jp pick --plan 2026-08-07-compact-generic-codex-steering-while-preserving-personal --action plan
```

Do not launch implementation directly until that planning pass confirms the current baseline and marks the contract ready.
