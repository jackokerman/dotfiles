# tuicr Nightfly theme handoff

## Summary

This note is the full handoff for adding a built-in `nightfly` theme to
`tuicr` on a personal machine.

The intended shape of the change is:

- Add a built-in dark `nightfly` theme to `tuicr`.
- Keep it upstreamable.
- Use accurate Nightfly UI colors and accurate syntax colors.
- Update the user-facing docs.
- Do not add a light variant.
- Do not turn this into a generic custom-theme feature in the same change.

The key design decision is that `tuicr` should bundle its own Nightfly syntect
theme asset instead of blocking on a separate upstream change to `two-face` or
`syntect`.

## Why this should live in `tuicr`

`tuicr` currently stores a `two_face::theme::EmbeddedThemeName` on its `Theme`
struct and feeds that into the syntax highlighter. That is an implementation
choice, not a hard product constraint.

`syntect` itself can load a `.tmTheme` directly. That means `tuicr` can support
Nightfly cleanly with a small refactor:

- Keep existing themes on embedded `two-face` themes.
- Add one more syntax theme source for bundled custom themes.
- Vendor a bundled `nightfly.tmTheme` asset inside `tuicr`.

This is better than trying to upstream Nightfly elsewhere first:

- `syntect` is the highlighting engine, not the right place for a broad app
  theme catalog.
- `two-face` ships generated embedded theme assets and a fixed enum, so
  upstreaming there first means a separate PR, waiting for a release, and then
  bumping `tuicr`.
- `tuicr` still needs its own UI palette work even if Nightfly landed in
  `two-face`, so that dependency work does not remove the main implementation
  task.

The simplest correct change is to bundle Nightfly directly in `tuicr`.

## Current repo touchpoints

These are the main files involved:

- `src/theme/mod.rs`
- `src/syntax/mod.rs`
- `src/config/mod.rs`
- `README.md`

Relevant behavior:

- `src/theme/mod.rs` defines the `Theme` struct, built-in themes, theme CLI
  parsing, config theme parsing, and theme resolution.
- `src/syntax/mod.rs` builds the `SyntaxHighlighter` and currently expects an
  embedded `two-face` theme name.
- `src/config/mod.rs` already accepts arbitrary strings for `theme`,
  `theme_dark`, and `theme_light`, so adding `nightfly` is mostly a
  theme-resolution concern rather than a config-schema concern.
- `README.md` currently documents the built-in theme list and config examples.

Places already confirmed during investigation:

- `ThemeArg` and `THEME_CHOICES` live in `src/theme/mod.rs`.
- `resolve_theme(...)` lives in `src/theme/mod.rs`.
- `Theme::syntax_highlighter()` currently calls
  `SyntaxHighlighter::new(self.syntect_theme, ...)`.
- `SyntaxHighlighter::new(...)` currently accepts
  `EmbeddedThemeName` and resolves via `two_face::theme::extra()`.
- Existing theme parser and resolution tests already live in
  `src/theme/mod.rs`.

## Source of truth

Use this precedence when picking values:

1. Bundled `nightfly.tmTheme` for syntax token colors and syntax-scope diff
   backgrounds.
2. Canonical Nightfly palette from `bluz71/vim-nightfly-colors` for non-syntax
   UI surfaces.
3. Existing user `git-delta` Nightfly/OpenCode diff values for add/delete
   accents and diff affordances when they differ from generic UI colors.
4. Only make manual tweaks after a live preview proves a real contrast problem.

Do not approximate Nightfly with a nearby embedded theme such as Nord, One Half,
or Base16.

## Primary syntax asset

The best syntax source is:

- `/Users/jackokerman/dotfiles/home/.codex/themes/nightfly.tmTheme`

Why this is the right source:

- It is already syntect-compatible.
- It is derived from the `fly16` / bat ecosystem rather than being a raw Vim
  theme export.
- It already includes concrete diff-related scopes like `meta.separator`,
  `markup.inserted`, and `markup.deleted`.
- It is closer to `tuicr`'s syntax stack than trying to reconstruct Nightfly
  from UI colors alone.

Important values already present in that file:

- background: `#011627`
- foreground: `#bdc1c6`
- lineHighlight: `#092236`
- selection: `#092236`
- gutterForeground: `#4b6479`
- `meta.separator` background: `#1d3b53`
- `markup.inserted` background: `#2a4e57`
- `markup.deleted` background: `#4e3030`

The current file also contains:

- `markup.inserted` foreground: `#a1cd5e`
- `markup.deleted` foreground: `#fc514e`

That is fine for syntax scopes. For top-level `tuicr` diff UI, prefer the
delta/OpenCode-style add/delete accents listed below.

## Canonical Nightfly palette

These values were verified from `bluz71/vim-nightfly-colors`:

- `black = #011627`
- `black_blue = #081e2f`
- `dark_blue = #092236`
- `ink_blue = #09243a`
- `storm_blue = #1b2633`
- `stone_blue = #252c3f`
- `slate_blue = #2c3043`
- `regal_blue = #1d3b53`
- `steel_blue = #4b6479`
- `grey_blue = #7c8f8f`
- `cadet_blue = #a1aab8`
- `ash_blue = #acb4c2`
- `white = #c3ccdc`
- `white_blue = #d6deeb`
- `red = #fc514e`
- `watermelon = #ff5874`
- `orange = #f78c6c`
- `peach = #ffcb8b`
- `tan = #ecc48d`
- `yellow = #e3d18a`
- `green = #a1cd5e`
- `emerald = #21c7a8`
- `turquoise = #7fdbca`
- `malibu = #87bcff`
- `blue = #82aaff`
- `violet = #c792ea`
- `purple = #ae81ff`
- `plant = #2a4e57`

## Delta / OpenCode Nightfly diff references

Relevant values from the local `git-delta` config:

- `plus-style = syntax "#2a4e57"`
- `minus-style = syntax "#4e3030"`
- `file-style = bold "#82aaff"`
- `hunk-header-style = file line-number syntax "#092236"`
- `hunk-header-file-style = bold "#82aaff"`
- `hunk-header-line-number-style = "#7c8f8f"`
- `line-numbers-plus-style = "#21c7a8" "#2a4e57"`
- `line-numbers-minus-style = "#ff5874" "#4e3030"`
- `plus-emph-style = bold "#21c7a8" "#2a4e57"`
- `minus-emph-style = bold "#ff5874" "#4e3030"`
- `whitespace-error-style = bold "#ff5874" "#4e3030"`

These should influence the `tuicr` diff UI more than the generic Nightfly
palette when choosing add/delete accents.

## Recommended `Theme` field mapping

This is the proposed Nightfly mapping for `tuicr`'s `Theme` struct.

- `panel_bg = #011627`
- `bg_highlight = #1d3b53`
- `fg_primary = #c3ccdc`
- `fg_secondary = #a1aab8`
- `fg_dim = #7c8f8f`
- `diff_add = #21c7a8`
- `diff_add_bg = #2a4e57`
- `diff_del = #ff5874`
- `diff_del_bg = #4e3030`
- `diff_context = #bdc1c6`
- `diff_hunk_header = #82aaff`
- `expanded_context_fg = #4b6479`
- `syntax_add_bg = #2a4e57`
- `syntax_del_bg = #4e3030`
- `file_added = #21c7a8`
- `file_modified = #ecc48d`
- `file_deleted = #ff5874`
- `file_renamed = #c792ea`
- `reviewed = #21c7a8`
- `pending = #ecc48d`
- `comment_note = #87bcff`
- `comment_suggestion = #7fdbca`
- `comment_issue = #fc514e`
- `comment_praise = #21c7a8`
- `border_focused = #82aaff`
- `border_unfocused = #4b6479`
- `status_bar_bg = #252c3f`
- `cursor_color = #82aaff`
- `cursor_line_bg = #092236`
- `branch_name = #87bcff`
- `help_indicator = #4b6479`
- `message_info_fg = #092236`
- `message_info_bg = #87bcff`
- `message_warning_fg = #092236`
- `message_warning_bg = #ecc48d`
- `message_error_fg = #d6deeb`
- `message_error_bg = #fc514e`
- `update_badge_fg = #092236`
- `update_badge_bg = #ecc48d`
- `mode_fg = #092236`
- `mode_bg = #82aaff`

Notes on the mapping:

- `bg_highlight` follows Nightfly visual selection semantics via `#1d3b53`.
- `cursor_line_bg` follows Nightfly `CursorLine` / `lineHighlight` via
  `#092236`.
- `status_bar_bg` uses `#252c3f`, which better matches Nightfly statusline
  surfaces than a flat panel background.
- Message and badge foregrounds use `#092236` so bright backgrounds still have
  contrast.

## Expected implementation shape

The change should stay narrow. Do not redesign the theme system beyond what is
needed to support Nightfly correctly.

Recommended shape:

1. Keep all existing built-in themes working exactly as they do now.
2. Refactor the syntax theme selector away from a raw `EmbeddedThemeName`.
3. Add a new built-in `nightfly` theme that uses a bundled `.tmTheme` asset for
   syntax.

Recommended new type:

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SyntaxThemeSource {
    Embedded(EmbeddedThemeName),
    BundledNightfly,
}
```

Then:

- Put `SyntaxThemeSource` in `src/syntax/mod.rs`.
- Change `Theme.syntect_theme` to `Theme.syntax_theme`.
- Change `SyntaxHighlighter::new(...)` to accept `SyntaxThemeSource`.
- Keep embedded themes using `two_face::theme::extra()[name].clone()`.
- Add a bundled-theme path for Nightfly using `syntect`'s theme loader.

## Bundled Nightfly asset loading

Copy the syntax asset into the repo as:

- `src/theme/nightfly.tmTheme`

Use `include_bytes!` so the binary is self-contained. A reasonable loading shape
is:

```rust
use std::io::{BufReader, Cursor};
use syntect::highlighting::ThemeSet;

let reader = Cursor::new(include_bytes!("../theme/nightfly.tmTheme"));
let mut reader = BufReader::new(reader);
let theme = ThemeSet::load_from_reader(&mut reader)
    .expect("bundled Nightfly theme should parse");
```

Implementation guidance:

- Keep this infallible at runtime with `expect(...)`.
- Cover that expectation with a unit test.
- Do not add a runtime file lookup from the filesystem for the built-in theme.
- Do not add a generic "load arbitrary path from config" feature in the same
  patch.

## Nightfly theme entry points to add

Add a new built-in theme variant:

- `ThemeArg::Nightfly`

Update all related points:

- Add `"nightfly"` to `THEME_CHOICES`.
- Make `ThemeArg::from_str("nightfly")` work.
- Add `Theme::nightfly()`.
- Route `ThemeArg::Nightfly` in `resolve_theme(...)`.
- Include `nightfly` in CLI help text automatically via the shared choice list.

This should make the following work:

- `tuicr --theme nightfly`
- `theme = "nightfly"`
- `theme_dark = "nightfly"`

Do not add:

- `Theme::nightfly_light()`
- `theme_light = "nightfly"` examples
- an appearance-paired Nightfly variant

Nightfly remains dark-only.

## Config and behavior expectations

No behavior changes are needed for theme precedence. `nightfly` should behave
exactly like any other explicit theme choice.

The existing precedence should remain:

1. `--theme`
2. `theme`
3. `theme_dark` + `theme_light`
4. single variant fallback
5. `--appearance`
6. config `appearance`
7. default system-based choice

The important detail is only that `nightfly` becomes a valid value wherever the
existing theme parser already expects a theme string.

## Where the theme fields are actually used

This is the practical mapping between `Theme` fields and UI surfaces, based on
the current code:

- `panel_bg`, `fg_primary` drive general panel and header rendering in
  `src/ui/styles.rs`.
- `bg_highlight` drives selected rows and visual selections.
- `diff_add`, `diff_add_bg`, `diff_del`, `diff_del_bg`, `diff_context`,
  `diff_hunk_header`, `expanded_context_fg` drive diff rendering.
- `syntax_add_bg` and `syntax_del_bg` drive syntax-highlighted diff padding and
  background surfaces in unified and side-by-side diff views.
- `status_bar_bg`, `mode_fg`, and `mode_bg` drive the footer and mode badge.
- `cursor_line_bg` is used in unified and side-by-side diff cursor row
  highlighting.
- `comment_*` colors are the defaults for built-in comment types in `app.rs`.
- `message_*` and `update_badge_*` colors are used in `src/ui/status_bar.rs`.

This means the proposed Nightfly values above are not speculative. They are
mapped to specific current surfaces.

## Docs to update

Update at least:

- `README.md`

Add:

- `nightfly` to the documented theme list
- a config example using `theme = "nightfly"`

If upstream `main` has added `docs/CONFIG.md` or other dedicated docs by the
time you implement this, update those too. Do not assume the older local README
structure is still the whole docs surface.

## Tests to add or update

Add or update tests for:

- `--theme nightfly`
- `--theme=nightfly`
- `ThemeArg::from_str("nightfly")`
- uniqueness / completeness of `ThemeArg::choices()`
- `resolve_theme(ThemeArg::Nightfly)`
- bundled Nightfly `.tmTheme` parsing

Recommended concrete checks:

- parser returns `Some(ThemeArg::Nightfly)`
- `resolve_theme(ThemeArg::Nightfly)` picks the Nightfly syntax theme source
- bundled theme loader successfully parses the vendored `.tmTheme`
- optionally assert a few known values from the parsed theme, such as name or
  the global background / foreground

Also keep the existing theme-resolution tests intact so the new variant does not
accidentally break unrelated theme behavior.

## Personal machine workflow

This should be implemented on a personal machine.

Reason:

- On the managed work machine, `cargo run -- --help` triggered a blocked build
  script under
  `/Users/jackokerman/src/tuicr/target/debug/build/crc32fast-2effd4628f3044bc/build-script-build`.
- That was caused by local Cargo compilation, not by `tuicr` itself.
- The cleanest way to avoid Santa is to do the actual Rust build on a personal
  machine or another unrestricted environment.

## Git and repo setup notes

Before editing:

1. Fetch `upstream`.
2. Start from current `upstream/main`.
3. Create a branch from there.

For git identity:

- Use `Jack Okerman`.
- Use the public GitHub account email or GitHub no-reply email.
- Do not use a work email for the contribution.

Known remotes in the current worktree during investigation:

- `origin = https://github.com/jackokerman/tuicr.git`
- `upstream = https://github.com/agavra/tuicr.git`

## Validation commands

After implementation:

```bash
cargo test
cargo build
```

Then visually preview:

```bash
target/debug/tuicr --theme nightfly -w
target/debug/tuicr --theme nightfly -r 'HEAD~3..HEAD'
target/debug/tuicr --theme nightfly --file path/to/file
target/debug/tuicr --theme nightfly -w -p path/to/file_or_dir
```

## Visual validation checklist

Check at least these surfaces:

- file list readability
- commit selector readability
- focused vs unfocused borders
- status bar contrast
- mode badge contrast
- hunk header visibility
- add/delete line readability
- syntax-highlighted add/delete lines
- cursor row visibility
- comment type colors
- message banners
- update badges
- side-by-side diff padding and gutters

Use a representative set of files if possible:

- Rust
- TypeScript or JavaScript
- Markdown
- one container syntax such as Vue, Svelte, Astro, MDX, PHP, or ERB if you have
  a handy repo, since `tuicr` has explicit container-language handling in the
  syntax highlighter

## Accuracy rules

- Do not replace Nightfly with the nearest built-in embedded theme.
- Do not hand-wave syntax highlighting from the UI palette.
- Do not tune colors from memory.
- Do not add a light variant.
- Do not add generic user-configurable custom theme loading in this patch.

If you need to deviate from the proposed values after a live preview:

- keep syntax scopes anchored to the bundled `.tmTheme`
- keep add/delete UI anchored to the delta/OpenCode diff colors
- keep non-diff chrome anchored to canonical Nightfly palette values
- only change a value when there is a concrete contrast or readability issue

## Optional future follow-up, not part of this change

If you later decide `tuicr` should support user-provided themes without
upstreaming them, that should be a separate feature.

That follow-up could add:

- a config path for custom syntax theme assets
- user-discoverable theme directories under `~/.config/tuicr`
- a cleaner theme registry abstraction

That is explicitly out of scope for the initial Nightfly contribution.

## Bottom line

The recommended implementation is:

- built-in `nightfly` theme
- dark-only
- bundled `src/theme/nightfly.tmTheme`
- narrow syntax-theme-source refactor
- exact Nightfly + delta-informed palette values
- docs and tests in the same patch

That is the smallest change that is both correct and upstreamable.
