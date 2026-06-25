---
id: 2026-06-25-audit-single-checkout-ownership-for-dotty-managed-tool-repos
title: audit single-checkout ownership for dotty-managed tool repos
state: ready-to-implement
createdAt: 2026-06-25T15:55:17.861Z
updatedAt: 2026-06-25T21:46:50.858Z
---

Refined the plan from a speculative audit into an implementation-ready checkout-ownership change. Confirmed that `.dotty/dev-checkouts.tsv` already treats `tmux-agent-bar` like a development checkout, Jackie Plan already uses the canonical-`~/src` plus compatibility-symlink model, and `tuicr` still looks intentionally runtime-only. Marked the plan `ready-to-implement` with the first slice scoped to migrating tmux-agent-bar path resolution, sync behavior, docs, and tests to the single-checkout model.
