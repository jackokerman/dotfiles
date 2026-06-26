---
id: 2026-06-25-route-codex-config-coach-token-follow-up-to-dotfiles
title: Route codex-config-coach token follow-up to dotfiles
state: inbox
createdAt: 2026-06-25T21:50:30.007Z
updatedAt: 2026-06-25T21:50:30.007Z
sourcePlan: 2026-06-25-continue-codex-token-audit
sourceRepo: private-overlay
sourcePath: codex-token-audit
---

# Route codex-config-coach token follow-up to dotfiles

## Plan

Base `codex-config-coach` work should stay out of overlay-specific token-audit plans.

## Why

- `codex-config-coach` is owned in `~/dotfiles/home/.codex/skills/codex-config-coach`.
- Current static budget from 2026-06-25 narrow audit: trigger `33`, invoke `682`, deferred `1509`, total `2224`.
- The overlay-side plan had a clearer local candidate in `review-pr`, so keep generic skill follow-up separate.

## Next time

If the token audit returns to base-skill work, start in `~/dotfiles` and decide whether `codex-config-coach` needs measured usage, a smaller reference split, or no change.
