---
id: 2026-06-25-design-agents-md-hygiene-helper
title: Design AGENTS.md hygiene helper
state: inbox
priority: normal
createdAt: 2026-06-25T19:28:25.578Z
updatedAt: 2026-06-25T23:56:16.755Z
---

# Summary

# Design AGENTS.md hygiene helper

## Problem

Recent steering updates exposed a recurring risk: small `AGENTS.md` edits can duplicate nearby guidance, add always-loaded weight, or encode a one-off correction too broadly. The current `readme-maintainer` skill covers README and adjacent docs freshness, and `codex-config-coach` covers routing steering updates, but there is not a focused reusable checklist for editing agent instruction files themselves.

## Scope

- Audit whether this should be a new skill, an addition to `codex-config-coach`, or an extension of `readme-maintainer`.
- Define a lightweight AGENTS/instruction-file review checklist: avoid duplicate rules, merge overlapping bullets, keep always-loaded guidance thin, route detailed procedure into skills or references, and preserve source-of-truth ownership across dotty layers.
- Prefer a skill-triggered or deferred checklist over more always-loaded `AGENTS.md` guidance.
- Include one or two pressure scenarios from this session, including the duplicated fallback/source-of-truth rule.
- Keep the first implementation small and verify with existing dotfiles checks.

## Priority

Normal. This is useful workflow polish, but not the next urgent implementation item.
