---
id: 2026-08-07-compact-generic-codex-steering-while-preserving-personal
title: Compact generic Codex steering while preserving personal defaults
state: complete
createdAt: 2026-08-07T01:09:26.458Z
updatedAt: 2026-08-07T02:20:04.507Z
sourcePlan: 2026-08-07-sequence-codex-steering-cleanup-across-dotty-layers
---

# Compact generic Codex steering while preserving personal defaults

## Plan

## Objective

Reduce the always-loaded generic Codex instruction budget while preserving the personal defaults that materially change communication, implementation, research, and configuration behavior across repositories.

The implementation should make the active Ruler source and the tracked rollback source one compact behavior contract, then verify that the generated live chain still composes the base and later overlays correctly.

## Refreshed baseline

Measured on 2026-08-06 from the owning repository:

- `home/.ruler/AGENTS.md`, the active base source, is 18,759 bytes and 2,779 words.
- `home/.codex/AGENTS.md`, the `DOTTY_CODEX_RULER=0` rollback source, is 11,671 bytes and 1,723 words and has drifted from the active source.
- Repo-root `AGENTS.md` is 13,750 bytes and already owns Dotfiles-specific commit, push, check, Dotty propagation, generated-config, cleanup, and source-routing procedure.
- The current generated `~/.codex/AGENTS.md` is 26,456 bytes and 3,874 words because it composes the base source with a later overlay. Total live size is useful operational evidence but is not the base reduction metric.
- `.dotty/run.sh` and `scripts/ts/sync-ruler.ts` make `home/.ruler/AGENTS.md` the default source and retain `home/.codex/AGENTS.md` only for the explicit rollback path.

## Preserved behavior contract

Retain compact, always-loaded rules when they materially encode these personal defaults:

- Communication stays concise, direct, complete-sentence, low-filler, willing to challenge weak assumptions, and biased toward concrete code or commands. Requests for the user to paste text preserve the macOS clipboard behavior.
- Implementation stays simple and scoped: one explicit source of truth, no speculative fallbacks or configuration, removal of obsolete personal-tooling paths, fixes at the consumption boundary, readable control flow, and compliance with repository lint, typing, formatting, and documentation standards.
- Work stays bounded and verifiable: clarify materially different interpretations, keep one-off machine work ephemeral, fix upstream environment sources before startup workarounds, avoid low-value tests for personal glue, preserve stable identifiers across presentation-only picker boundaries, handle dirty Git state narrowly, and run and report the smallest relevant verification.
- Research stays evidence-first: inspect exact targets and narrow local context first, prefer official documentation and local CLI/types/source, use local checkouts and authenticated GitHub tooling before generic web search, check upstream issues and pull requests before declaring a limitation, and distinguish confirmed facts from uncertainty.
- Tool adoption stays narrow: prefer the smallest native workflow and existing config surface, keep native commands usable, avoid wrappers until repeated friction justifies them, keep standalone-tool implementation in its owning repository, and preserve Bun/TypeScript as the default helper stack where appropriate.
- Ownership stays explicit: generic personal steering belongs in the base repository, private or host-specific behavior belongs in later layers, repo-specific procedure belongs in repo instructions, and detailed task procedure belongs in triggered skills or deferred references.

These are behavior categories, not a requirement to preserve every current sentence. Merge overlapping rules aggressively when one short rule carries the same contract.

## Rule disposition and file ownership

Before editing, build an ephemeral bullet-by-bullet disposition map for the active source. Classify every current rule as one of:

- retained universal preference;
- repo-local instruction;
- existing routed skill or deferred-reference content;
- missing skill detail that must move before deletion;
- exact duplicate;
- built-in restatement;
- obsolete rule.

Do not commit the map or add an AGENTS hygiene helper. Use it as the completeness check for the rewrite.

Apply these ownership decisions:

- Rewrite `home/.ruler/AGENTS.md` and `home/.codex/AGENTS.md` to identical compact content so the default and rollback paths do not encode different personal behavior.
- Remove the global Dotfiles workflow section rather than copying it; repo-root `AGENTS.md` already owns the procedure. Change repo-root instructions only if the disposition map identifies a concrete missing boundary needed to preserve current behavior.
- Remove standalone frontend, Godspeed, Neovim, README, writing, shell, and Codex-config procedure when the existing skill already owns it. Confirm ownership in `home/.ruler/skills/*`, `home/.codex/skills/codex-config-coach/`, and their deferred references before deletion.
- Move a removed rule into an existing owning skill only when the audit proves that the skill lacks required behavior. The known likely gap is the zsh special-parameter warning in `bash-style`; do not churn other skills whose current contract already covers the rule.
- Preserve only short skill-routing rules whose invocation or proactive trigger would otherwise be lost. Do not repeat the skill's internal workflow in global instructions.
- Do not change generator code, add a cleanup, add a new skill, or add tests for prose unless implementation uncovers a concrete generated-output defect or an unowned durable behavior. Stop and revise the plan before expanding into those changes.

## Implementation sequence and stopping points

1. Capture the baseline counts and complete the ephemeral disposition map. Stop if a personal invariant has no valid owner or if the active and rollback sources reveal a material behavior conflict that this contract does not settle.
2. Rewrite the two tracked global sources as the same compact contract. Make only the narrowly justified repo-instruction or existing-skill edits identified by the map.
3. Compare the rewritten files, inspect the diff against every disposition, and measure the base source. Prefer the smaller wording when two versions preserve the same behavior.
4. Run repository validation, commit the intended tracked changes with a conventional commit, and apply the committed source through the documented `dotty update` path before pushing.
5. Verify the live generated header, managed-skill indexes, composed overlay behavior, and pressure scenarios. Fix only regressions caused by this rewrite, then push `main` when the worktree and upstream state are safe.

## Verification

Static and repository checks:

- Confirm `home/.ruler/AGENTS.md` and `home/.codex/AGENTS.md` are identical.
- Reconcile every removed active-source bullet with the disposition map; no rule may disappear merely to hit the byte target.
- Measure bytes and words for both tracked sources and the final generated live file. Target 8–10 KiB for the identical base contract and treat 10 KiB as a guardrail, not a reason to discard a demonstrated personal invariant.
- Run `./scripts/check --extended --quiet` because this changes generated Codex behavior. Before the commit, stage only owned paths and use the repository's staged check/pre-commit workflow.
- After the commit, run `dotty update`; confirm the live file starts with the Ruler-generated Dotty header and that the Codex and Claude managed-skill indexes still resolve portable and Codex-native skills to their tracked owners.
- Re-check `git status --short --branch` and commits ahead of upstream before pushing. Stop for overlapping dirty changes, unexpected ahead commits, or non-fast-forward remote state.

Behavior pressure scenarios:

- In a fresh base-only context, request a short technical draft and confirm concise complete sentences, low filler, and correct identifier formatting without loading detailed writing procedure globally.
- In a fresh base-only context, request a small personal-tooling bug fix and confirm the response chooses the narrowest implementation, avoids speculative fallbacks and low-value tests, researches the strongest source available, and reports focused verification.
- In the Dotfiles repository, request a task that clearly routes to one existing skill and confirm global steering triggers the skill while repo-root instructions still control local checks, Dotty propagation, commit, and push behavior.

Keep these as bounded manual smoke checks. Do not add prose fixtures, initialize `.plugin-eval/`, or run benchmark suites without separate explicit approval.

## Non-goals

- Do not change unrelated personal tooling behavior or later-overlay policy.
- Do not optimize individual skill bodies beyond a narrowly required relocation.
- Do not redesign Ruler, the Dotty generation chain, managed-skill ownership, or rollback support.
- Do not add compatibility paths, configuration knobs, new helpers, or speculative checks.
- Do not execute implementation, commit, push, or change lifecycle state during planning.

## Approval boundary

Before marking this plan `ready-to-implement`, show the full persisted plan and obtain explicit approval that this is the implementable contract. Approval authorizes the normal plan-artifact lifecycle and Git persistence, but does not authorize implementation.

## Next honest step

No implementation work remains. Preserve the completed plan and final verification handoff in Git; the compact steering is active after `dotty update` and both implementation and lifecycle commits should be pushed to `main`.

## Agent handoff

### Resume state

The approved implementation is complete. The plan is `complete`, and no implementation work remains.

Outcome:

- `home/.ruler/AGENTS.md` and `home/.codex/AGENTS.md` are byte-identical at 7,902 bytes and 1,116 words, down from the 18,759-byte and 2,779-word active baseline.
- The zsh special-parameter warning is owned by `home/.ruler/skills/bash-style/SKILL.md`.
- `dotty update` succeeded. The live composed `~/.codex/AGENTS.md` is 15,599 bytes and 2,211 words, down from 26,456 bytes and 3,874 words, and its generated header names both tracked Ruler sources.
- The Codex and Claude managed-skill indexes point portable skills to `home/.ruler/skills/`, and the Codex index points `codex-config-coach` to `home/.codex/skills/`.
- Extended repository checks, focused skill validation, static source identity and size checks, generated-output checks, and all three approved fresh-context smoke scenarios pass.

The implementation is committed as `aa753d4` (`refactor: compact generic Codex steering`). This final plan lifecycle and checkpoint update is approved for a separate lifecycle commit because the commit-first Dotty workflow required activation and smoke verification after the implementation commit. Neither commit has been pushed yet.

### Process notes

The disposition audit found only one genuine unowned rule and relocated it to `bash-style`; all other removed procedure already belonged to repo instructions, existing skills, or active built-in steering. The final lightweight improvement audit found no repeated friction or missing durable rule that warrants another config edit, helper, test, cleanup, skill, or follow-up plan.
