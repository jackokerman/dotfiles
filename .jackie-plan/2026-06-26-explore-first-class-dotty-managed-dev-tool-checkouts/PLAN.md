---
id: 2026-06-26-explore-first-class-dotty-managed-dev-tool-checkouts
title: Explore first-class dotty-managed dev tool checkouts
state: ready-to-implement
createdAt: 2026-06-26T06:52:25.121Z
updatedAt: 2026-06-26T16:34:10.119Z
---

# Explore first-class dotty-managed dev tool checkouts

## Plan

## Goal
Define whether dotty should grow from today’s manifest-based development-checkout sync into a first-class dev-tool model that can declare checkout location, update policy, install or sync actions, and compatibility wiring for reusable personal tools.

## Why this exists
The current repo already has part of this model, but the boundary is fragmented. `.dotty/dev-checkouts.tsv` plus `scripts/sync-dev-checkouts.sh` manage clone and conservative fast-forward behavior for selected repos under a configurable source root, while tool-specific install and compatibility behavior still lives in separate code paths such as `.dotty/commands/install-jackie-plan` and the runtime-only `tuicr` flow in `.dotty/run.sh`. Adding another reusable tool means remembering which parts belong in the manifest, which parts need a dedicated installer or hook step, and which docs need to explain the result.

## Confirmed repo facts
- `.dotty/dev-checkouts.tsv` currently tracks `comment-width-check`, `jackie-plan`, `oxlint-config`, and `tmux-agent-bar` under `~/src` by default.
- `scripts/sync-dev-checkouts.sh` only understands `name`, `repo_url`, and `branch`, plus a shared `DEV_CHECKOUTS_SRC_ROOT` override. It has no declarative per-tool hook, install, compatibility-path, or integration metadata.
- `.dotty/run.sh` runs `setup_dev_checkouts` and then `setup_jackie_plan` as separate phases, which means checkout bootstrap and tool installation are not one first-class contract today.
- `.dotty/commands/install-jackie-plan` still owns its own clone fallback, compatibility symlink management for `~/.local/share/jackie-plan/repo`, and installer dispatch.
- `tuicr` is still intentionally a runtime-only managed checkout with its own sync and install path, which provides the contrasting model.
- Repo docs already describe `~/src` development checkouts and `~/.local/share/` runtime-only checkouts, but they do not yet describe a single declarative way to add a new managed personal tool end to end.

## Questions to answer
1. Which current tools should stay in the lightweight manifest-only model, and which ones need a richer first-class tool contract because dotty also installs, links, or exposes them?
2. Should the development-checkout root become explicit shared configuration instead of an implied `~/src` default with script-local overrides?
3. What is the smallest declarative schema that covers checkout bootstrap plus follow-on integration without making `dotty update` opaque or hard to debug?
4. Should `dotty` itself ever participate in the same model, or is self-management a separate bootstrap problem that should stay out of scope for the first slice?
5. Does any cross-tool shared steering surface belong in this model, or should repo-local `AGENTS.md` and tool-specific config stay separate?

## Deliverable
Produce a short design recommendation grounded in the current repo behavior. It should compare the existing split model with at least one richer first-class alternative, name the tradeoffs around transparency and bootstrap risk, and recommend the smallest worthwhile implementation slice rather than a full framework rewrite.

## Recommended first slice
Start with one concrete candidate: replace the bare TSV manifest with a richer tracked metadata source for tools that dotty both checks out and integrates, then prove the model on `jackie-plan` because it already spans checkout sync, compatibility-path handling, and installation. Keep `tuicr` out of that first slice unless the exploration finds a concrete reason to promote runtime-only tools into the same system.

## Definition of done
- The plan names the current split responsibilities clearly enough that a future implementation does not rediscover them.
- The exploration yields a recommendation, not just an inventory.
- The recommendation identifies one small follow-up implementation slice and one explicit non-goal.
- Any `dotty` self-management or broader agent-steering questions that do not belong in the first slice are either ruled out or captured as follow-up work.

## Verification
Use local source inspection for the affected scripts and docs, then make the recommendation durable in the plan artifacts. No broad repo validation is required unless the exploration turns into a code or docs change.
