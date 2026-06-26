---
id: 2026-06-26-explore-first-class-dotty-managed-dev-tool-checkouts
title: Explore first-class dotty-managed dev tool checkouts
state: complete
createdAt: 2026-06-26T06:52:25.121Z
updatedAt: 2026-06-26T16:49:22.090Z
---

# Explore first-class dotty-managed dev tool checkouts

## Plan

## Goal
Define whether dotty should grow from today's manifest-based development-checkout sync into a first-class dev-tool model that can declare checkout location, update policy, install or sync actions, and compatibility wiring for reusable personal tools.

## Why this exists
The current repo already has part of this model, but the boundary is fragmented. `.dotty/dev-checkouts.tsv` plus `scripts/sync-dev-checkouts.sh` manage clone and conservative fast-forward behavior for selected repos under a configurable source root, while tool-specific install and compatibility behavior still lives in separate code paths such as `.dotty/commands/install-jackie-plan` and the runtime-only `tuicr` flow in `.dotty/run.sh`. Adding another reusable tool means remembering which parts belong in the manifest, which parts need a dedicated installer or hook step, and which docs need to explain the result.

## Confirmed repo facts
- `.dotty/dev-checkouts.tsv` currently tracks `comment-width-check`, `jackie-plan`, `oxlint-config`, and `tmux-agent-bar` under `~/src` by default.
- `scripts/sync-dev-checkouts.sh` only understands `name`, `repo_url`, and `branch`, plus a shared `DEV_CHECKOUTS_SRC_ROOT` override. It has no declarative per-tool hook, install, compatibility-path, or integration metadata.
- `.dotty/run.sh` runs `setup_dev_checkouts` and then `setup_jackie_plan` as separate phases, which means checkout bootstrap and tool installation are not one first-class contract today.
- `.dotty/commands/install-jackie-plan` still owns its own clone fallback, compatibility symlink management for `~/.local/share/jackie-plan/repo`, and installer dispatch.
- `tuicr` is still intentionally a runtime-only managed checkout with its own sync and install path, which provides the contrasting model.
- Repo docs already describe `~/src` development checkouts and `~/.local/share/` runtime-only checkouts, but they do not yet describe a single declarative way to add a new managed personal tool end to end.

## Recommendation
Do not replace the current lightweight development-checkout sync with a broad tool framework. Keep the transparent checkout behavior as the base model: a tracked list of repos, non-interactive clone/fetch, conservative fast-forward only, and clear skip warnings when the local checkout has diverged. That behavior is easy to inspect, safe for contribution workspaces, and already has focused tests.

Add a richer first-class contract only for the narrower category of tools that dotty both checks out and integrates after clone. Today that category is Jackie Plan. It is already a normal development checkout under `~/src/jackie-plan`, but dotty also installs its CLI and plugin and maintains a compatibility path at `~/.local/share/jackie-plan/repo`. That makes it the smallest useful proof point for metadata beyond `name`, `repo_url`, and `branch`.

The recommended shape is a single tracked metadata source for dev tools that preserves the existing checkout fields and adds optional integration fields. The first useful fields are the checkout name, repo URL, branch, development root class or explicit path, install command, and compatibility symlink target. The sync implementation should continue to print direct per-tool actions and warnings; metadata should remove duplicated ownership knowledge, not hide what `dotty update` is doing.

## Alternatives Considered
Keeping the current split model is viable for the current repo size. It has low bootstrap risk and the implementation is obvious, but it leaves a repeated trap: a future reusable tool may get added to `.dotty/dev-checkouts.tsv` without the corresponding installer, docs, compatibility path, or hook ordering being considered.

A full generic dev-tool framework would centralize every checkout, installer, generated config hook, runtime clone, and agent integration. That is too much ceremony for the current evidence. It would make `dotty update` harder to debug and would risk mixing contribution workspaces under `~/src` with runtime-only implementation checkouts under `~/.local/share/`.

The middle path is best: introduce richer metadata only where the existing split has already proven a real second responsibility. Jackie Plan has that responsibility now; `comment-width-check`, `oxlint-config`, and `tmux-agent-bar` can remain manifest-only until they need integration hooks beyond checkout sync.

## Recommended Implementation Slice
Replace the bare TSV with a richer tracked metadata source or add a companion metadata file for integrated dev tools, then migrate only `jackie-plan` through it. The implementation should make `setup_dev_checkouts` and `setup_jackie_plan` consume one source of truth for Jackie Plan's repo URL, branch, checkout path, compatibility symlink, and installer path.

Keep the first slice behavior-preserving: missing Jackie Plan checkouts should still clone to `~/src/jackie-plan`, clean checkouts should still fast-forward conservatively, dirty or customized checkouts should still be skipped with warnings, and `~/.local/share/jackie-plan/repo` should remain a compatibility symlink only when absent or already pointing at the active checkout.

## Explicit Non-Goals
- Do not promote `tuicr` into the same model in the first slice. It is a runtime-only managed checkout and should stay under `~/.local/share/tuicr/repo` unless a concrete contribution-workspace need appears.
- Do not make dotty self-management part of this exploration. Bootstrapping the manager itself has different failure modes than syncing reusable tool checkouts.
- Do not add a generic cross-tool agent steering surface. Repo-local `AGENTS.md`, generated Codex or Claude config, and tool-specific plugin installation should stay separate unless repeated duplication appears.
- Do not add per-machine configuration knobs beyond the existing root override unless the implementation hits an actual local need.

## Definition of Done
- The current split responsibilities are named clearly enough that a future implementation does not rediscover them.
- The exploration yields a recommendation, not just an inventory.
- The recommendation identifies one small follow-up implementation slice and one explicit non-goal.
- `dotty` self-management and broader agent-steering questions are ruled out for the first slice.

## Verification
This recommendation was based on local source inspection of `.dotty/dev-checkouts.tsv`, `scripts/sync-dev-checkouts.sh`, `.dotty/commands/install-jackie-plan`, `.dotty/run.sh`, `scripts/sync-tuicr.sh`, `tests/dev-checkouts/test-sync.sh`, `README.md`, `docs/agent-tooling.md`, and `AGENTS.md`. No broad repo validation is required because this slice only updates Jackie Plan artifacts.
