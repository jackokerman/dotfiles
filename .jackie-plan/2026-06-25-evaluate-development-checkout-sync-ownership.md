---
id: 2026-06-25-evaluate-development-checkout-sync-ownership
title: Evaluate development checkout sync ownership
state: inbox
createdAt: 2026-06-25T03:21:04.323Z
updatedAt: 2026-06-25T03:21:04.323Z
sourcePlan: 2026-06-25-build-preferred-personal-tooling-stack
---

# Evaluate development checkout sync ownership

## Plan

# Evaluate development checkout sync ownership

Decide whether the new dotfiles `~/src` development checkout sync should remain a dotfiles hook convention, grow overlay support, or become a dotty first-class feature.

## Context

Dotfiles now has `.dotty/dev-checkouts.tsv` and `dotty run sync-dev-checkouts`, which clone selected public tool repos under `~/src` and conservatively fast-forward clean checkouts. This is intentionally dotfiles-owned for now.

Questions to revisit:

- Should dotty eventually have a first-class checkout manifest for source repos, separate from the registered dotfiles chain?
- Should base and later dotty-chain overlays each be able to contribute manifests, for example a later overlay listing work-related repos?
- Should the active dotty-managed `dotfiles` checkout stay under `~/.dotty/repos/dotfiles`, or should there be a separate `~/src/dotfiles` contribution checkout?
- Is there any cleanup to do for legacy locations, especially the old `~/.local/share/jackie-plan/repo` clone once all references point at `~/src/jackie-plan`?

## Suggested next step

After using the dotfiles hook for a few weeks, inspect whether it created useful behavior or noise. If it is useful in both public dotfiles and a later overlay, draft the smallest dotty core shape. If it is only personal workflow glue, keep it in dotfiles.
