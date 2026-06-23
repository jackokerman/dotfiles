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

Use workspace-first chords for predictable navigation, plus default-workspace
aliases for the views used constantly on a given machine.

Workspace navigation macros:

| Shortcut | Macro name | Behavior |
| --- | --- | --- |
| `ctrl + g w t` | `Jump to Work Today` | Show Work and jump to Work Today. |
| `ctrl + g w i` | `Jump to Work Inbox` | Show Work and jump to Work Inbox. |
| `ctrl + g w n` | `Jump to Work Next Actions` | Show Work and jump to Work Next Actions. |
| `ctrl + g w s` | `Jump to Work Someday` | Show Work and jump to Work Someday. |
| `ctrl + g p t` | `Jump to Personal Today` | Show Personal and jump to Personal Today. |
| `ctrl + g p i` | `Jump to Personal Inbox` | Show Personal and jump to Personal Inbox. |
| `ctrl + g p n` | `Jump to Personal Next Actions` | Show Personal and jump to Personal Next Actions. |
| `ctrl + g p s` | `Jump to Personal Someday` | Show Personal and jump to Personal Someday. |

Default-workspace aliases:

| Shortcut | Macro name | Behavior |
| --- | --- | --- |
| `ctrl + g t` | `Jump to Default Today` | Jump to the default workspace Today. |
| `ctrl + g i` | `Jump to Default Inbox` | Jump to the default workspace Inbox. |
| `ctrl + g n` | `Jump to Default Next Actions` | Jump to the default workspace Next Actions. |
| `ctrl + g s` | `Jump to Default Someday` | Jump to the default workspace Someday. |

On a work machine, the default workspace should be Work.

Move macros:

| Shortcut | Macro name | Behavior |
| --- | --- | --- |
| `ctrl + m n` | `Move to Same Workspace Next Actions` | Move selected task(s) to Next Actions in the same workspace. |
| `ctrl + m s` | `Move to Same Workspace Someday` | Move selected task(s) to Someday in the same workspace. |

Keep `M` as the fallback for uncommon moves.

## Navigation Macro Pattern

The `Expand/collapse folder` action operates on the currently selected folder.
To switch workspace context, first jump to the folder you want to hide, collapse
it, then jump to the folder you want to use and expand it.

Work navigation macros should use this shape:

1. `Jump to list` -> Personal folder.
2. `Expand/collapse folder` -> `Collapse`.
3. `Jump to list` -> Work folder.
4. `Expand/collapse folder` -> `Expand`.
5. `Jump to list` -> the target Work list.

Personal navigation macros should use the same shape with Work and Personal
reversed.

Examples:

- Work Today (`ctrl + g w t`): collapse Personal, expand Work, jump to Work
  Today.
- Work Inbox (`ctrl + g w i`): collapse Personal, expand Work, jump to Work
  Inbox.

## Setup

1. Install and sign into the Godspeed desktop app.
2. Enable task/list cloud sync.
3. Enable `Settings > Text > Key chords`.
4. Enable `Settings > Sync > hotkey sync`.
5. Create one navigation macro per table row in the Macro Editor.
6. Create the move macros with `Update macro variables with JavaScript`, then
   `Move to list` using `{{destinationListID}}`.
7. Bind the shortcuts in the Hotkey Editor with `?`.
8. Test `ctrl + g w t`, `ctrl + g w i`, one default-workspace alias, and one
   move shortcut.

## Account-Specific IDs

The move macros need Godspeed list IDs to route tasks correctly. Do not commit
those IDs to this public repo. Keep the current IDs in the private in-app
Godspeed note named `Godspeed keyboard shortcuts`, or recopy them from Godspeed
with `Copy list ID`.

The private note should include IDs for:

- Work folder, Today, Inbox, Next Actions, and Someday.
- Personal folder, Today, Inbox, Next Actions, and Someday.
- Which workspace should be the default target for `ctrl + g t/i/n/s` on the
  current machine.

## Test Plan

- Press `?` and verify every new chord has no conflict.
- Run `ctrl + g w t`, `ctrl + g w i`, and `ctrl + g p t`. Confirm the target
  list opens and the other workspace collapses.
- Run `ctrl + g t`, `ctrl + g i`, `ctrl + g n`, and `ctrl + g s`. Confirm each
  opens the machine's default workspace view.
- From Work Inbox, run `ctrl + m n`. Confirm the task moves to Work Next
  Actions.
- From Personal Inbox, run `ctrl + m s`. Confirm the task moves to Personal
  Someday.
- Test multi-select with two inbox tasks.
