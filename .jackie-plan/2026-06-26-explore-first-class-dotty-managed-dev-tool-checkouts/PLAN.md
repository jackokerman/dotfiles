---
id: 2026-06-26-explore-first-class-dotty-managed-dev-tool-checkouts
title: Explore first-class dotty-managed dev tool checkouts
state: inbox
createdAt: 2026-06-26T06:52:25.121Z
updatedAt: 2026-06-26T06:52:25.121Z
---

# Explore first-class dotty-managed dev tool checkouts

## Plan

## Problem

Iterating on reusable dev tools keeps hitting the same friction: some tools are part of the dotfiles workflow, but their development checkout, install path, and sync path are not all first-class in dotty. That makes it easy to forget a separate dev-sync step outside `dotty update`, leaving the live tool, generated assets, or linked integrations stale while iterating.

The current setup also creates wiring tax for new tools. Adding another reusable personal dev tool can require remembering multiple manual hooks: checkout location, sync/install behavior, Codex or skill wiring, and any runtime compatibility path. The result is avoidable drift and wasted debugging time.

## Scope

- Audit which personal development tools should follow the same managed-checkout model instead of ad hoc sync rules.
- Evaluate a first-class configurable development-tools root, with `~/src` as one likely default rather than an implicit special case.
- Explore whether `dotty` itself should participate in that model, and document the recursion or bootstrap risks if so.
- Design a declarative sync/install contract so adding a new dev tool can automatically cover checkout bootstrap, update behavior, and required integration wiring.
- Evaluate whether shared cross-tool context, such as an overarching `AGENTS.md` or similar steering surface, belongs in the model or should stay repo-local.
- Keep the first outcome exploratory: recommend the model, name the tradeoffs, and identify the smallest implementation slice worth trying.

## Open questions

- Which tools are true development checkouts versus runtime-only managed clones?
- How should per-tool install or sync hooks be declared and invoked during `dotty update`?
- How much auto-discovery is useful before the workflow becomes too implicit or hard to debug?
- If `dotty` becomes part of the same model, what is the safe bootstrap and self-update story?

## Priority

Normal. This is recurring workflow friction worth addressing, but it needs a design pass before implementation.
