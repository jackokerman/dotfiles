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

Navigation macros:

- `ctrl + g w t`: show Work and jump to Work Today.
- `ctrl + g p t`: show Personal and jump to Personal Today.
- `ctrl + g w i`: jump to Work Inbox.
- `ctrl + g p i`: jump to Personal Inbox.
- `ctrl + g w n`: jump to Work Next Actions.
- `ctrl + g p n`: jump to Personal Next Actions.
- `ctrl + g w s`: jump to Work Someday.
- `ctrl + g p s`: jump to Personal Someday.

Move macros:

- `ctrl + m n`: move selected task(s) to Next Actions in the same workspace.
- `ctrl + m s`: move selected task(s) to Someday in the same workspace.

Keep `M` as the fallback for uncommon moves.

## Setup

1. Install and sign into the Godspeed desktop app.
2. Enable task/list cloud sync.
3. Enable `Settings > Text > Key chords`.
4. Enable `Settings > Sync > hotkey sync`.
5. Create the navigation macros in the Macro Editor.
6. Create the move macros with `Update macro variables with JavaScript`, then
   `Move to list` using `{{destinationListID}}`.
7. Bind the shortcuts in the Hotkey Editor with `?`.
8. Test one navigation shortcut and one move shortcut.

## Account-Specific IDs

The move macros need Godspeed list IDs to route tasks correctly. Do not commit
those IDs to this public repo. Keep the current IDs in the private in-app
Godspeed note named `Godspeed keyboard shortcuts`, or recopy them from Godspeed
with `Copy list ID`.

The private note should include IDs for:

- Work folder, Today, Inbox, Next Actions, and Someday.
- Personal folder, Today, Inbox, Next Actions, and Someday.

## Test Plan

- Press `?` and verify every new chord has no conflict.
- Run `ctrl + g w t` and `ctrl + g p t`. Confirm the target Today opens and the
  other workspace collapses.
- From Work Inbox, run `ctrl + m n`. Confirm the task moves to Work Next
  Actions.
- From Personal Inbox, run `ctrl + m s`. Confirm the task moves to Personal
  Someday.
- Test multi-select with two inbox tasks.
