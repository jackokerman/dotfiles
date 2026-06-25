---
id: 2026-06-25-decide-markdown-prose-formatting-policy-for-personal-repos
title: decide markdown prose formatting policy for personal repos
state: inbox
createdAt: 2026-06-25T23:56:16.784Z
updatedAt: 2026-06-25T23:56:16.784Z
---

# Summary

## Problem

A recent cleanup removed artificial hard line breaks from Markdown prose across the approved personal repos. The immediate steering fix is in place: base AGENTS says not to hard-wrap Markdown prose, `readme-maintainer` already says the same for docs work, and the Jackie Plan skills now repeat the rule where plan artifacts are created.

That likely stops most of the bleeding, but it does not answer the long-term policy question for personal repos:

- Should shared formatter policy own Markdown paragraph shape?
- Should this stay instruction-led, with a separate read-only audit helper for drift?
- Should both exist, with one as the default and the other as verification?

## Findings to use

- `oxfmt` does support Markdown and exposes `proseWrap`.
- With the current shared config, the default behavior is effectively `preserve`, which keeps already wrapped paragraphs as-is.
- A probe showed `proseWrap: "never"` collapses a hard-wrapped paragraph back to a single logical line, while `proseWrap: "always"` rewraps prose to print width.
- That means formatter adoption is possible, but it would be a real policy change, not a no-op safety net.

## Scope

- Decide whether the preferred personal-repo policy should be:
  - shared Oxfmt config for Markdown,
  - a read-only Markdown paragraph audit helper,
  - or a combined approach.
- If formatter policy is preferred, decide the narrowest safe setting and scope, especially whether Markdown should use `proseWrap: "never"` via overrides instead of a broader global change.
- If audit is preferred, define the lowest-ceremony contract: suspicious hard-wrapped paragraph detection, repo selection, and whether it should stay opt-in or become part of routine checks.
- Decide where this guidance belongs in the shared stack: `oxlint-config`, `readme-maintainer`, `codex-config-coach`, repo scaffolding, or another owned surface.

## Acceptance criteria

- There is a documented preferred policy for Markdown prose formatting in personal repos.
- The chosen owner is explicit: shared formatter config, audit helper, steering only, or a combination.
- If tooling is chosen, the first implementation path and rollout scope are defined.
