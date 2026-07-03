---
id: 2026-07-03-contribute-glow-tui-theming-support
title: Contribute Glow TUI theming support
state: inbox
createdAt: 2026-07-03T18:15:57.414Z
updatedAt: 2026-07-03T18:16:30.345Z
sourcePlan: 2026-06-26-add-glow-nightfly-theme-and-durable-config
---

# Contribute Glow TUI theming support

## Plan

## Problem

Dotfiles now works around Glow's custom style path behavior by generating a live `~/.config/glow/glow.yml` with an absolute style path. That only solves the rendered Markdown style. The TUI chrome is still hard-coded upstream, so Nightfly cannot theme the file-list selection color, logo badge, bottom status bar, scroll percentage, help note, or expanded help overlay through `glow.yml` or the Glamour JSON style.

The desired upstream contribution is to make Glow's TUI chrome themeable without requiring a private fork and without conflating Markdown document styling with application chrome styling.

## Confirmed context

- Local `glow --version` on 2026-07-03 reported `glow version 2.1.2` from Homebrew.
- `glow --help` documents `--style` as a built-in style name or JSON path, and `--config` as the Glow config file path.
- Upstream README documents config keys for `style`, `mouse`, `pager`, `width`, `all`, `showLineNumbers`, and `preserveNewLines`; it does not document TUI chrome theme keys.
- Upstream `ui/styles.go` hard-codes the shared TUI colors, including `fuchsia`, `yellowGreen`, dim variants, grays, and status/error colors.
- Upstream `ui/stash.go` hard-codes the file-list logo style, input prompt/cursor style, and selected-item color behavior.
- Upstream `ui/stashitem.go` uses those hard-coded styles for the selected item gutter, title, date, edited-by text, and filtered-text matches.
- Upstream `ui/pager.go` hard-codes the bottom status bar colors, status-message colors, `? Help` segment colors, help overlay background, and line-number color.
- Upstream `ui/config.go` exposes TUI config for `GLAMOUR_STYLE`, mouse, line numbers, max width, preserve-new-lines, and high-performance pager behavior, but no chrome theme fields.
- Upstream issue https://github.com/charmbracelet/glow/issues/953 tracks that TUI mode does not respect `--style`; that is related but narrower than chrome theming.
- Upstream issue https://github.com/charmbracelet/glow/issues/713 tracks `~` path expansion problems for custom JSON style paths.
- Upstream PR https://github.com/charmbracelet/glow/pull/949 attempts to fix `~` style path expansion.
- Upstream PR https://github.com/charmbracelet/glow/pull/956 was closed and targeted `--style` versus `GLAMOUR_STYLE` precedence in TUI mode.

## Proposed upstream shape

Start with a small design proposal or issue before coding. Separate two concepts clearly:

- Glamour document style: existing `style` / `--style` behavior for rendered Markdown content.
- Glow TUI theme: new chrome-level styling for application UI elements around the document.

Prefer a minimal config surface first. A good initial target is a named or file-backed `tuiTheme` config key, or another name that upstream maintainers prefer, that can style the existing chrome slots without changing default behavior.

Candidate theme slots to propose:

- `logoForeground`, `logoBackground`, and `logoBold`
- `selectedForeground`, `selectedDimForeground`, and `selectedGutterForeground`
- `accentForeground` for prompts and active UI text
- `dimForeground`, `mutedForeground`, and `subtleForeground`
- `statusBarForeground`, `statusBarBackground`, and `statusBarHelpBackground`
- `statusMessageForeground`, `statusMessageBackground`, and `statusMessageHelpBackground`
- `helpForeground` and `helpBackground`
- `lineNumberForeground`
- `errorForeground` and `errorBackground`

Keep the first implementation conservative:

- Preserve the current hard-coded colors as the default theme.
- Add a typed theme struct in `ui`, then route existing Lip Gloss style construction through that struct.
- Avoid changing interaction behavior, pagination, filtering, file discovery, or Markdown rendering in the same PR.
- Add tests around config/theme loading and default-value preservation where the codebase has existing test seams.
- Include before/after screenshots or terminal recordings for dark-background and light-background examples if upstream asks for visual evidence.

## Dotfiles-specific reference material

Use the existing Nightfly assets only as validation material, not as upstream-specific assumptions:

- `home/.config/glow/nightfly.json` shows the current Glamour document style.
- `.dotty/run.sh` `setup_glow()` explains why dotfiles generates an absolute live style path.
- The screenshot context from 2026-07-03 showed the hard-coded magenta selection and gray status/help chrome clashing with the rest of the Nightfly terminal setup.

Do not propose Nightfly as a built-in Glow theme unless maintainers explicitly want bundled themes. The more general contribution is to make TUI chrome themeable so user themes like Nightfly can exist outside Glow.

## Acceptance criteria

- There is an upstream issue or discussion that clearly separates document styling from TUI chrome styling.
- If maintainers agree with the direction, a PR adds a small theme config path for Glow TUI chrome while preserving current defaults.
- The implementation avoids a dotfiles-only fork and does not require local patching of Homebrew Glow.
- Dotfiles can eventually delete or reduce any workaround only when released Glow behavior makes the tracked config simpler and reliable.

## Verification for implementation

- Run upstream Glow's `go test ./...`.
- Build a local `glow` binary and compare TUI screenshots with default theme versus a small custom theme.
- Test document rendering separately from chrome theming so `style` regressions are easy to identify.
- Re-test `style: "~/.config/glow/nightfly.json"` and config-relative style paths only if the upstream work also touches custom style path resolution.
