---
id: 2026-06-26-design-config-driven-devtool-repo-management
title: Design config-driven devtool repo management
state: ready-to-implement
createdAt: 2026-06-26T17:42:12.482Z
updatedAt: 2026-06-26T17:42:55.035Z
sourcePlan: 2026-06-26-implement-integrated-dev-tool-metadata-for-jackie-plan
---

# Design config-driven devtool repo management

## Plan

Design and implement the next slice of config-driven devtool repo management for this dotty setup. The goal is that personal development tools can be declared in tracked dotty configuration, and dotty can make the corresponding repos exist, keep them reasonably current, and run the right install or sync step without each tool needing a bespoke clone path in `.dotty/run.sh`.

## Product Goal
A reusable personal devtool should be addable by editing one declarative config surface. For each configured tool, the config should be able to say where the repo comes from, where it should live, how it updates, and what command, if any, installs or refreshes the tool after checkout. Running `dotty update` should then converge the machine toward that declared state.

This is for personal tooling, not a public package manager. Prefer a direct model that is easy to inspect and fix locally over compatibility layers for hypothetical external users. If an old path or legacy behavior is obsolete, remove it or migrate it deliberately instead of preserving it indefinitely.

## Current State
- `.dotty/dev-checkouts.tsv` declares a few development checkouts with `name`, repo URL, and branch.
- `scripts/sync-dev-checkouts.sh` clones missing repos under `~/src` and fast-forwards clean checkouts on their configured branch.
- Tool-specific integration is separate. Jackie Plan has `.dotty/commands/install-jackie-plan`, while `tuicr` has a runtime-only sync path.
- Existing docs distinguish active contribution checkouts under `~/src` from runtime implementation checkouts under `~/.local/share`.
- The current plan was originally too narrow because it framed the first slice as Jackie Plan metadata only; Jackie Plan should be the proof case, not the whole design.

## Design Direction
Replace the bare TSV or supplement it with a richer tracked devtool config that can describe both checkout-only tools and installed devtools. The config should stay small enough to read at a glance. A likely first schema has these fields:

- `name`: stable tool identifier and default checkout directory name.
- `repo`: Git remote URL.
- `branch`: branch to clone or fast-forward.
- `checkout`: explicit path or a root class such as `dev` for `~/src/<name>`.
- `update`: the update policy, initially conservative fast-forward only.
- `install`: optional command to run after checkout/update, relative to the repo or dotfiles root.
- `enabled`: optional boolean only if there is an immediate need to keep a declaration but skip it on this machine.

Do not add fallback paths, compatibility symlink fields, or multiple location aliases by default. If an existing legacy path is actively used, handle that as a one-time cleanup or migration task, then make the new config the single source of truth.

## First Implementation Slice
Implement the richer config around the existing dev checkout flow, then prove it on Jackie Plan because it currently spans checkout management plus installation. The first slice should make Jackie Plan's repo URL, branch, checkout path, and installer dispatch come from the new config instead of being repeated across `.dotty/dev-checkouts.tsv`, `scripts/sync-dev-checkouts.sh`, and `.dotty/commands/install-jackie-plan`.

Keep checkout-only tools such as `comment-width-check`, `oxlint-config`, and `tmux-agent-bar` in the same config if that keeps the source of truth simple. They do not need install commands until they actually have post-checkout integration work.

Leave `tuicr` out of the first slice unless the implementation naturally supports runtime-only tools without extra branching. It is still a useful contrast case, but the priority is personal devtools that are meant to live as editable repos.

## Non-Goals
- Do not build a broad package manager, plugin manager, or hidden orchestrator.
- Do not preserve compatibility paths just because they exist today.
- Do not add per-machine override machinery unless the implementation hits a real current need.
- Do not make dotty self-management part of this slice.
- Do not route every runtime-only checkout through the devtool model before proving it on editable devtool repos.

## Acceptance Criteria
- A tracked config can declare at least Jackie Plan as an installed devtool and at least one checkout-only devtool.
- `dotty update` and `dotty run sync-dev-checkouts` continue to converge declared devtool repos without prompting for Git credentials.
- Missing declared devtool repos are cloned to their configured location.
- Clean declared repos on the configured branch fast-forward when their origin matches the config.
- Dirty, branch-mismatched, or origin-mismatched repos are skipped with explicit warnings rather than overwritten.
- Jackie Plan installation runs from the configured checkout after sync without duplicating its repo URL, branch, or checkout path in a second script.
- Obsolete Jackie Plan compatibility behavior is removed or converted into an explicit one-time cleanup rather than kept as ongoing runtime logic.
- Docs explain the new config surface, how to add a personal devtool, and when to use this model versus a runtime-only checkout.
- Focused tests cover config parsing, checkout-only tools, installed tools, skipped dirty/customized repos, and Jackie Plan installer dispatch.
