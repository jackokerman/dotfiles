---
id: 2026-06-25-audit-single-checkout-ownership-for-dotty-managed-tool-repos
title: audit single-checkout ownership for dotty-managed tool repos
state: complete
createdAt: 2026-06-25T15:55:17.861Z
updatedAt: 2026-06-26T00:38:54.806Z
---

Implemented the first slice: tmux-agent-bar wrappers now prefer the `~/src/tmux-agent-bar` development checkout when present, fall back to `~/.local/share/tmux-agent-bar/repo`, and the sync script uses the same model. The sync script creates the legacy runtime path as a compatibility symlink when a dev checkout exists and the legacy path is absent, while preserving existing legacy checkouts. Updated focused tests and docs/steering surfaces to describe the `~/src` development-checkout ownership model and `tuicr` as runtime-only.

Verified with `./tests/tmux-agent-bar/test-runtime-path.sh`, `./tests/tmux-agent-bar/test-sync.sh`, `./tests/tmux-agent-bar/test-wrappers.sh`, and `./scripts/check --extended --quiet`.
