---
id: 2026-06-26-add-glow-nightfly-theme-and-durable-config
title: add glow Nightfly theme and durable config
state: complete
priority: high
createdAt: 2026-06-26T06:29:30.367Z
updatedAt: 2026-06-26T15:50:10.566Z
---

# add glow Nightfly theme and durable config

## Plan

## Problem

`glow` is now installed on this machine, but the setup is not yet managed by this repo. The next slice is to make `glow` durable in dotfiles:

- track installation through `Brewfile`
- provide a persistent default config
- add a Nightfly-flavored custom theme
- choose an implementation that survives `dotty update` and works from any working directory

## Confirmed findings

- Local CLI check on 2026-06-25 confirmed `glow version 2.1.2`.
- `glow --help` confirms the default config path is `~/.config/glow/glow.yml` and the `--style` flag accepts either a built-in style name or a JSON path.
- Upstream `glow` docs confirm custom styles are plain JSON files.
- Upstream `glamour` docs confirm custom styles can inline `code_block.chroma` token colors, so a local custom theme does not require upstream theme registration.
- The repo already vendors Nightfly source material in `home/.codex/references/nightfly/` and already carries Nightfly-derived assets for other tools, including `home/.codex/themes/nightfly.tmTheme` and the tracked `bat`/terminal themes.
- `Brewfile` currently does not include `glow`.
- There is no tracked `home/.config/glow/` source yet.

## Important implementation constraint

A tracked `glow.yml` cannot safely use `style: "~/.config/glow/nightfly.json"`.

This was verified in a real TTY repro:

- `glow` validates the configured style path with `~` expansion up front.
- During actual rendering, `glamour` later tries to open the literal string `~/.config/glow/style.json` and fails.
- An absolute path works.
- A relative path is not durable because it resolves against the process working directory, not the config file directory.

That means the durable solution needs more than a static tracked config file.

## Recommended implementation

- Add `glow` to `Brewfile`.
- Track a custom Nightfly `glamour` style JSON at something like `home/.config/glow/nightfly.json`.
- Build that JSON from existing Nightfly sources already in this repo instead of inventing a second palette source of truth.
- Prefer a small checked-in JSON style over a Go-based generator for this repo. A Go generator is only justified if contributing a first-class built-in theme upstream.
- Generate the live `~/.config/glow/glow.yml` during `dotty update` with an absolute style path pointing at the live `nightfly.json` location.
- Reuse the existing real-directory/generated-file pattern used for `sesh` if needed so the generated config does not write back into tracked source through a symlink.

## Suggested approach for the theme itself

- Start from one of `glamour`'s shipped dark JSON styles, likely `tokyo-night.json`, as the structural template.
- Replace document, heading, link, rule, inline code, and code-block colors with Nightfly values.
- Inline `code_block.chroma` colors directly in the JSON rather than trying to point `glamour` at a `.tmTheme`.
- Use the existing repo Nightfly assets as the source of truth for colors:
  - `home/.codex/references/nightfly/vim-nightfly-colors/autoload/nightfly.vim` for the canonical palette
  - `home/.codex/themes/nightfly.tmTheme` and `home/.config/bat/themes/fly16.tmTheme` for syntax and diff-oriented color choices
- Keep the first pass small and pragmatic. The goal is a coherent Nightfly renderer, not a generalized theme-conversion pipeline.

## Open design choices to resolve during implementation

- Whether to keep `~/.config/glow` as a symlinked tracked directory plus a separately generated `glow.yml`, or to treat the whole directory like `~/.config/sesh` and keep it real with generated content where necessary.
- Whether the Nightfly style JSON should be hand-authored from a known `glamour` base style or produced by a small Bun helper that copies existing palette values into `glamour`'s JSON schema.
- Whether README changes are necessary. At minimum, audit docs drift after implementation because install/setup behavior changes once `glow` is tracked in `Brewfile` and `dotty update` manages its config.

## Acceptance criteria

- `dotty run brew-sync` installs `glow` on macOS.
- `dotty update` leaves a working persistent `glow` config in place.
- Running `glow README.md` in a real terminal uses the custom Nightfly style without extra flags and without path-resolution errors.
- The custom theme lives in tracked dotfiles source and is maintainable from existing Nightfly references in this repo.
- Any docs affected by the install/config workflow are updated in the same change.

## Verification to run when implementing

- `glow --help`
- `glow README.md` in a real TTY after `dotty update`
- the smallest repo check that covers any hook/config changes
- `git status --short --branch` before commit/push

## Agent handoff

Implemented and verified the durable Glow config slice. Added `glow` to `Brewfile`, added tracked Nightfly `glamour` style JSON at `home/.config/glow/nightfly.json`, ignored `.config/glow` from direct dotty linking, added `setup_glow` to render live `~/.config/glow/glow.yml` with an absolute style path, and documented the tracked edit point in `README.md`. Verification passed: `jq empty home/.config/glow/nightfly.json`, `bash -n .dotty/run.sh`, `./scripts/check --quiet`, direct dirty-source hook invocation with the active dotty utility library, `./scripts/brew-sync.sh`, `glow --help`, pseudo-TTY `glow README.md` with `PAGER=cat`, and `./scripts/check --extended --quiet`. Follow-up audit found no separate durable follow-up.
