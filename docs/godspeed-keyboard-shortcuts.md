# Godspeed Keyboard Shortcuts

This is the durable setup guide for my Godspeed desktop shortcuts. It documents
the scheme, not the private account-specific list IDs.

Official references:

- [Hotkeys](https://godspeedapp.com/guides/hotkeys)
- [Macros](https://godspeedapp.com/guides/macros)
- [Update macro variables with JavaScript](https://godspeedapp.com/updating-macro-variables-with-javascript)

## Concepts

Godspeed has two separate pieces here:

- Key chords are keyboard sequences assigned to commands or macros, such as
  `ctrl + g w t`.
- Macros are Godspeed actions that do the work, such as jumping to a list,
  collapsing a folder, or moving selected tasks.

The shortcut should be memorable, but the macro is the behavior.

## Shortcut Scheme

Use a hybrid leader strategy:

- `ctrl + g` is the workspace/navigation leader. The `g` is for
  Godspeed/GTD, and it avoids conflicts with tmux and Neovim.
- `ctrl + m` is the move/triage leader. Godspeed's hotkey guide uses
  `ctrl + m` for move-to-list macro examples, so this follows the app's own
  convention.

Avoid these:

- `ctrl + t`, because tmux uses it for `sesh-pick`.
- `ctrl + a`, because tmux uses it as prefix.
- `space` or `ctrl + space`, because Neovim already uses space as leader and
  Space-like bindings are more likely to collide with text input or task
  selection.

## Bindings

Start with a small set of bindings. Add list-specific navigation only after the
default workflow feels too slow.

Core navigation macros:

- `ctrl + g w`: show Work and jump to Work Today.
- `ctrl + g p`: show Personal and jump to Personal Today.
- `ctrl + g t`: jump to the default Today view for this machine. On a work
  machine, default this to Work Today.

Move macros:

- `ctrl + m n`: move selected task(s) to Next Actions in the same workspace.
- `ctrl + m s`: move selected task(s) to Someday in the same workspace.

Keep `M` as the fallback for uncommon moves.

Optional navigation macros:

- `ctrl + g w i`, `ctrl + g w n`, `ctrl + g w s`: jump to Work Inbox, Next
  Actions, or Someday.
- `ctrl + g p i`, `ctrl + g p n`, `ctrl + g p s`: jump to Personal Inbox, Next
  Actions, or Someday.

## Navigation Macro Pattern

The `Expand/collapse folder` action operates on the currently selected folder.
To switch workspace context, first jump to the folder you want to hide, collapse
it, then jump to the folder you want to use and expand it.

Work navigation macros should use this shape:

1. `Jump to list` -> Personal folder.
2. `Expand/collapse folder` -> `Collapse`.
3. `Jump to list` -> Work folder.
4. `Expand/collapse folder` -> `Expand`.
5. `Jump to list` -> the target Work list. Use Today for the core workspace
   focus macro.

Personal navigation macros should use the same shape with Work and Personal
reversed.

## Setup

1. Install and sign into the Godspeed desktop app.
2. Enable task/list cloud sync.
3. Enable `Settings > Text > Key chords`.
4. Enable `Settings > Sync > hotkey sync`.
5. Create the navigation macros in the Macro Editor.
6. Create the move macros with `Update macro variables with JavaScript`, then
   `Move to list` using `{{destinationListID}}`.
7. Bind the shortcuts in the Hotkey Editor with `?`.
8. Test `ctrl + g w`, `ctrl + g p`, `ctrl + g t`, and one move shortcut.

## Account-Specific IDs

The move macros need Godspeed list IDs to route tasks correctly. Do not commit
those IDs to this public repo. Keep the current IDs in the private in-app
Godspeed note named `Godspeed keyboard shortcuts`, or recopy them from Godspeed
with `Copy list ID`.

The private note should include IDs for:

- Work folder, Today, Inbox, Next Actions, and Someday.
- Personal folder, Today, Inbox, Next Actions, and Someday.
- Which workspace should be the default target for `ctrl + g t` on the current
  machine.

## Test Plan

- Press `?` and verify every new chord has no conflict.
- Run `ctrl + g w` and `ctrl + g p`. Confirm the target Today opens and the
  other workspace collapses.
- Run `ctrl + g t`. Confirm it opens the machine's default Today view.
- From Work Inbox, run `ctrl + m n`. Confirm the task moves to Work Next
  Actions.
- From Personal Inbox, run `ctrl + m s`. Confirm the task moves to Personal
  Someday.
- Test multi-select with two inbox tasks.
