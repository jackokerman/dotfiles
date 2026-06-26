---
id: 2026-06-26-add-glow-nightfly-theme-and-durable-config
title: add glow Nightfly theme and durable config
state: complete
priority: high
createdAt: 2026-06-26T06:29:30.367Z
updatedAt: 2026-06-26T15:50:10.566Z
---

Implemented and verified the durable Glow config slice. Added `glow` to `Brewfile`, added tracked Nightfly `glamour` style JSON at `home/.config/glow/nightfly.json`, ignored `.config/glow` from direct dotty linking, added `setup_glow` to render live `~/.config/glow/glow.yml` with an absolute style path, and documented the tracked edit point in `README.md`. Verification passed: `jq empty home/.config/glow/nightfly.json`, `bash -n .dotty/run.sh`, `./scripts/check --quiet`, direct dirty-source hook invocation with the active dotty utility library, `./scripts/brew-sync.sh`, `glow --help`, pseudo-TTY `glow README.md` with `PAGER=cat`, and `./scripts/check --extended --quiet`. Follow-up audit found no separate durable follow-up.
