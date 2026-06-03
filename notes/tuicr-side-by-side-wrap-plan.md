# tuicr side-by-side wrap handoff

## Summary

This note is the handoff for fixing `wrap = true` in side-by-side diff mode in
`tuicr`.

The short version:

- This is a real product gap, not user error.
- `wrap = true` is wired up and the side-by-side renderer does call
  `Paragraph::wrap(...)`.
- That still does not wrap long diff code lines in practice because the
  side-by-side renderer truncates or pads each pane to a fixed width before the
  paragraph renderer sees the content.
- A correct fix should wrap each side-by-side pane explicitly before building
  the final rendered rows.

## What is happening now

Relevant code paths in `tuicr`:

- `src/main.rs` applies config `diff_view = "side-by-side"` and `wrap = true`
  on startup.
- `src/ui/diff_side_by_side.rs` computes a fixed `content_width` for each pane.
- `src/ui/diff_side_by_side.rs` builds one logical row per paired side-by-side
  annotation.
- `src/ui/diff_side_by_side.rs` uses `truncate_or_pad(...)` and
  `truncate_or_pad_spans(...)` for side-by-side content before render.
- `src/ui/diff_side_by_side.rs` then renders the finished rows in a `Paragraph`
  with `Wrap { trim: false }`.

That means long code lines are already ellipsized before `ratatui` gets a
chance to wrap them. The current wrapping path can still affect annotations,
comment boxes, or other rows, but it does not give true wrapped code columns in
side-by-side diff mode.

## Local evidence already confirmed

These code locations matter:

- `src/ui/diff_side_by_side.rs`
  - pane width is derived from `SBS_OVERHEAD`
  - long rows are measured after row assembly
  - `Paragraph::wrap(...)` is enabled when `wrap_lines` is on
  - actual content is pre-truncated with `truncate_or_pad*`
- `src/ui/text_utils.rs`
  - `truncate_or_pad(...)` and `truncate_or_pad_spans(...)` currently return a
    single row, not wrapped continuation rows
- `src/app.rs`
  - the app model already supports multiple visual rows mapping back to one
    annotation through `diff_row_to_annotation`
  - selection and cursor mapping in side-by-side mode assume a fixed pane width
    and repeated annotation indices for wrapped rows

Relevant history from local git:

- `feat: add line wrapping for unified view (#88)`
- `fix: correct scroll behavior when line wrapping is enabled (#130)`
- `feat(config): add show_file_list, diff_view, and wrap config options (#218)`
- `feat: gutter-aligned word wrap with continuation marker (#382)`
- `fix(ui): align diff row backgrounds with word-wrapped text (#401)`

Important read on that history:

- wrap started in unified view
- later fixes focused on wrapped row accounting and overlays
- nothing in local history indicates that side-by-side diff code wrapping was
  ever fully implemented

## Comparable tools

Two useful precedents:

### `delta`

`delta` explicitly supports side-by-side view with automatic long-line wrapping.

Useful patterns from its docs and source:

- side-by-side wrapping is a first-class feature, not a side effect of generic
  paragraph wrapping
- it has dedicated side-by-side wrapping and alignment logic
- it tracks wrapped row state separately from unwrapped minus/plus rows
- it supports continuation markers for wrapped rows

Useful source areas:

- `src/features/side_by_side.rs`
- `src/wrapping.rs`

The key lesson for `tuicr`:

- wrapping needs to happen before the final side-by-side row is painted
- wrapped continuation rows are part of the diff layout model

### `difftastic`

`difftastic` is closer to the shape `tuicr` should probably use.

Useful patterns from its source:

- compute equal content widths for left and right panes
- wrap left content and right content independently to that pane width
- zip the wrapped fragments together
- render `max(left_rows, right_rows)` visual rows for a single aligned pair
- continuation rows keep alignment by reusing blank or continuation gutters

Useful source area:

- `src/display/side_by_side.rs`

The key lesson for `tuicr`:

- the rendering unit in side-by-side mode should become "a paired annotation
  expands to N visual rows", not "one annotation always produces one row"

## Recommended implementation shape for `tuicr`

This is the safest plan that matches the current app model.

### 1. Stop pre-truncating side-by-side diff content when wrap is enabled

Do not call `truncate_or_pad(...)` or `truncate_or_pad_spans(...)` for actual
side-by-side diff code rows when `wrap_lines` is true.

Those helpers are still fine for:

- no-wrap mode
- some metadata rows
- places where a single-row display is intentional

### 2. Add a span-aware side-by-side pane wrapper

Add a helper that takes:

- a pane width
- plain text or highlighted spans
- the base style / diff style
- possibly the diff prefix style for continuation rows

And returns:

- `Vec<Vec<Span>>` or a similar structure representing wrapped visual rows for
  one pane

Requirements:

- preserve syntax highlighting across wrapped rows
- use display width, not byte length
- keep behavior deterministic for tabs and wide characters
- pad continuation rows to the pane width so alignment stays stable

This should live near the current text utility helpers, or in a new
side-by-side-specific wrapping helper.

### 3. Build visual rows from wrapped left/right pane fragments

For each side-by-side annotation:

- wrap the old side into `left_rows`
- wrap the new side into `right_rows`
- render `max(left_rows.len(), right_rows.len())` final rows

Continuation row policy:

- first row keeps the real line number and diff marker
- continuation rows should render blank line numbers
- continuation rows can either keep the diff marker or show a simple wrap
  marker; blank line numbers plus the same diff marker is a good first pass

This is the core change. It replaces the current one-row-per-annotation
rendering assumption inside `src/ui/diff_side_by_side.rs`.

### 4. Separate annotation indexing from rendered row indexing in the renderer

Today the side-by-side renderer effectively increments one line counter as it
emits rows. That only works cleanly when one annotation maps to one rendered
row.

After wrapping:

- `line_annotations` should stay at the annotation level
- rendered visual rows should be allowed to repeat the same annotation index
- `diff_row_to_annotation` should be populated from the actual emitted visual
  rows, not inferred from "one logical line equals one rendered row"

This fits the existing app model, because `App` already expects wrapped rows to
repeat the same annotation index.

### 5. Keep selection and cursor math based on fixed pane width

This is the main reason to prefer explicit pane wrapping over `Paragraph::wrap`.

Current side-by-side selection math assumes:

- one pane has a known content width
- the wrapped visual row number inside an annotation maps to
  `which_row * pane_width + col_in_row`

That model still works if `tuicr` wraps side-by-side panes explicitly at
`content_width`.

It is much less reliable if `ratatui` does free-form word wrapping over the
fully assembled side-by-side row.

### 6. Consider dropping `Paragraph::wrap(...)` for diff code rows in side-by-side mode

Once side-by-side rows are explicitly wrapped before render, generic paragraph
wrapping becomes unnecessary for those rows and may become actively confusing.

It may still make sense for some non-diff annotation rows, but the cleaner
mental model is:

- unified mode can use its existing wrap strategy
- side-by-side mode should render pre-wrapped rows explicitly

## Suggested scope for a first pass

Keep the first implementation narrow.

Include:

- context lines
- deletion/addition pairs
- standalone additions
- correct scroll and cursor behavior
- correct visual selection behavior
- correct inline comment placement below wrapped rows

Do not add in the same change:

- user-facing wrap symbol configuration
- multiple wrap styles
- a generic wrapping abstraction shared across every renderer
- speculative fallback logic

If continuation markers are useful, keep them hard-coded in the first pass.

## Test plan

Add focused tests for side-by-side mode with `wrap = true` covering:

1. A long context line wraps on both panes instead of truncating.
2. A long deletion/addition pair wraps both sides and keeps row alignment.
3. A wrapped left side with a short right side still keeps the separator and
   right content aligned.
4. `diff_row_to_annotation` repeats the same annotation index across wrapped
   continuation rows.
5. Mouse selection / `cell_to_sel_point(...)` maps continuation rows to the
   correct char offsets.
6. Inline comment cursor placement stays correct when the active line above it
   wraps.
7. Scrolling can still reach the bottom of a long wrapped side-by-side diff.

If there is not yet a good render-level test harness for side-by-side rows, add
small helper-level tests around the pane wrapper first.

## Recommended order of work

1. Add one failing test that demonstrates current truncation in side-by-side
   wrap mode.
2. Add a pane-wrapping helper for plain text and highlighted spans.
3. Refactor side-by-side row building so one annotation can emit multiple
   visual rows.
4. Update `diff_row_to_annotation` population to use those emitted rows.
5. Verify selection, cursor, and comment placement on wrapped rows.
6. Update docs if behavior becomes truly supported.

## Practical recommendation

This is worth taking on, but it is medium-sized, not a quick patch.

It is a good candidate for a focused, upstreamable change because:

- the current config and docs imply that wrapping is a general diff-view
  feature
- the app model already has most of the state needed for wrapped visual rows
- the missing piece is mostly renderer architecture in side-by-side mode

The best implementation model is closer to `difftastic` than to "let
`Paragraph::wrap` handle it".
