# Godspeed keyboard shortcuts

Durable setup note for the Godspeed desktop app. The in-app task note is useful
once Godspeed is synced, but this file is the bootstrap source of truth on a new
machine.

## Setup status

- Use the Godspeed desktop app for these shortcuts. Desktop-app hotkeys sync to
  other Mac desktop apps, but not to the PWA/web app.
- Enable `Settings > Text > Key chords` on every Mac.
- Enable `Settings > Sync > hotkey sync` on every Mac desktop app.
- Configure macros and hotkeys through the Godspeed UI. Do not edit
  `~/Library/Application Support/Godspeed/godspeed-db.sqlite` directly.

## Leader keys

- Navigation/workspace leader: `ctrl + g`.
- Move/triage leader: `ctrl + m`.
- Reason: `ctrl + g` is mnemonic for Godspeed/GTD, low conflict with current
  dotfiles, and app-local. `ctrl + m` matches Godspeed's own hotkey guide examples
  for move-to-list macros, so use it where the operation is specifically moving
  tasks.
- Avoid `ctrl + t` because tmux uses it for `sesh-pick`.
- Avoid `ctrl + a` because tmux uses it as prefix.
- Avoid `space`/`ctrl + space` because Neovim already uses space as leader, and
  Space-like bindings are more likely to conflict with app text/input behavior.
- Fallback if `ctrl + g` conflicts inside Godspeed: use `ctrl + m` for all Godspeed
  chords.

## Macro and shortcut map

Navigation macros:

- `ctrl + g w t`: expand Work, collapse Personal, jump to Work Today.
- `ctrl + g p t`: expand Personal, collapse Work, jump to Personal Today.
- `ctrl + g w i`: jump to Work Inbox.
- `ctrl + g p i`: jump to Personal Inbox.
- `ctrl + g w n`: jump to Work Next Actions.
- `ctrl + g p n`: jump to Personal Next Actions.
- `ctrl + g w s`: jump to Work Someday.
- `ctrl + g p s`: jump to Personal Someday.

Triage macros:

- `ctrl + m n`: move selected task(s) to Next Actions in the same workspace.
- `ctrl + m s`: move selected task(s) to Someday in the same workspace.
- Keep `M` as the fallback for uncommon moves.

## List IDs

Work:

- Folder: `c8c7c376-26a3-4aec-9d2b-db6db4265276`
- Today: `e5ae448e-a500-43df-8604-930a11ccad2a`
- Inbox: `aeace149-9164-4dda-b37b-42ddaf6688fd`
- Next Actions: `e08357c8-ad9b-49f2-838f-d8719dd8286f`
- Someday: `eb13c4e0-4292-41c1-b8c6-49163c4613dd`

Personal:

- Folder: `8783c3cf-1f02-484d-9c89-94dc731ba7a7`
- Today: `319cf6c1-3304-4e16-888b-df68630e90e1`
- Inbox: `2b8f88f8-0942-4af5-b576-adf14587ac30`
- Next Actions: `f10d60cc-541f-4018-acac-687eceb35b4d`
- Someday: `00c56517-501b-4b53-bdf0-e4c5719134be`

## New Mac checklist

1. Install and sign into the Godspeed desktop app.
2. Confirm task/list cloud sync is enabled.
3. Enable `Settings > Sync > hotkey sync`.
4. Enable `Settings > Text > Key chords`.
5. Open the Hotkey Editor with `?` and confirm `ctrl + g` chords synced.
6. If macros did not sync, recreate them from this note.
7. Test `ctrl + g w t` and one triage shortcut before relying on the setup.

## Workspace-aware move macro: Next Actions

Create a macro named `Move to same workspace Next Actions`. Add an `Update
macro variables with JavaScript` action, then a `Move to list` action using
`{{destinationListID}}`.

```js
const updateVariables = (currentVariables, state) => {
  const WORK_LIST_IDS = new Set([
    "c8c7c376-26a3-4aec-9d2b-db6db4265276",
    "e5ae448e-a500-43df-8604-930a11ccad2a",
    "aeace149-9164-4dda-b37b-42ddaf6688fd",
    "e08357c8-ad9b-49f2-838f-d8719dd8286f",
    "eb13c4e0-4292-41c1-b8c6-49163c4613dd",
  ]);
  const PERSONAL_LIST_IDS = new Set([
    "8783c3cf-1f02-484d-9c89-94dc731ba7a7",
    "319cf6c1-3304-4e16-888b-df68630e90e1",
    "2b8f88f8-0942-4af5-b576-adf14587ac30",
    "f10d60cc-541f-4018-acac-687eceb35b4d",
    "00c56517-501b-4b53-bdf0-e4c5719134be",
  ]);

  const selectedListID = state.selectedTasks[0]?.listID ?? state.selectedList?.id;

  if (WORK_LIST_IDS.has(selectedListID)) {
    return {
      ...currentVariables,
      destinationListID: "e08357c8-ad9b-49f2-838f-d8719dd8286f",
    };
  }

  if (PERSONAL_LIST_IDS.has(selectedListID)) {
    return {
      ...currentVariables,
      destinationListID: "f10d60cc-541f-4018-acac-687eceb35b4d",
    };
  }

  return currentVariables;
};
```

## Workspace-aware move macro: Someday

Create a macro named `Move to same workspace Someday`. Add an `Update macro
variables with JavaScript` action, then a `Move to list` action using
`{{destinationListID}}`.

```js
const updateVariables = (currentVariables, state) => {
  const WORK_LIST_IDS = new Set([
    "c8c7c376-26a3-4aec-9d2b-db6db4265276",
    "e5ae448e-a500-43df-8604-930a11ccad2a",
    "aeace149-9164-4dda-b37b-42ddaf6688fd",
    "e08357c8-ad9b-49f2-838f-d8719dd8286f",
    "eb13c4e0-4292-41c1-b8c6-49163c4613dd",
  ]);
  const PERSONAL_LIST_IDS = new Set([
    "8783c3cf-1f02-484d-9c89-94dc731ba7a7",
    "319cf6c1-3304-4e16-888b-df68630e90e1",
    "2b8f88f8-0942-4af5-b576-adf14587ac30",
    "f10d60cc-541f-4018-acac-687eceb35b4d",
    "00c56517-501b-4b53-bdf0-e4c5719134be",
  ]);

  const selectedListID = state.selectedTasks[0]?.listID ?? state.selectedList?.id;

  if (WORK_LIST_IDS.has(selectedListID)) {
    return {
      ...currentVariables,
      destinationListID: "eb13c4e0-4292-41c1-b8c6-49163c4613dd",
    };
  }

  if (PERSONAL_LIST_IDS.has(selectedListID)) {
    return {
      ...currentVariables,
      destinationListID: "00c56517-501b-4b53-bdf0-e4c5719134be",
    };
  }

  return currentVariables;
};
```

## Test plan

- Press `?` and verify every new chord has no conflict.
- Run `ctrl + g w t` and `ctrl + g p t`. Confirm the target Today opens and the
  other workspace collapses.
- From Work Inbox, run `ctrl + m n`. Confirm the task moves to Work Next Actions.
- From Personal Inbox, run `ctrl + m s`. Confirm the task moves to Personal
  Someday.
- Test multi-select with two inbox tasks.
