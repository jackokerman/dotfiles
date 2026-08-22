# tmux and Fleet

This directory owns the reviewed tmux integration for the Homebrew-installed Fleet agent dashboard.

## Ownership

- `prefix` + `F` opens the Fleet dashboard in a 55% by 60% popup, matching the sesh popup dimensions.
- `prefix` + `f` runs `fleet sidebar --from '#{pane_id}'`, so Fleet toggles one 34-column sidebar in the invoking window.
- `themes/nightfly.tmux` owns the normal first-row session and window styling.
- `run-shell "fleet statusline --inject" # fleet-managed` runs after Nightfly loads and gives Fleet ownership of the native second status row and its mouse bindings. The row is an attention queue: working and idle agents stay in the dashboard, while permission, question, and ready agents appear beside the always-visible sidebar button.
- `~/.config/fleet/theme.toml` is generated from the tracked Nightfly palette at `home/.config/fleet/theme.toml`.

The Fleet executable comes from `nicknisi/formulae/fleet` in the tracked `Brewfile`. `dotty update` runs Fleet's native installers non-interactively when Fleet and the applicable Claude or Codex CLI are available. The Claude plugin registration, Fleet plugin link, Codex status directory, and agent registry are mutable runtime state; tracked Claude and Codex settings keep their durable enablement and hook contracts.

The one-time `2026-08-remove-tmux-agent-bar-hooks` cleanup removes the three retired indexed server hooks only when their actions still exactly match the old refresh wrapper. It preserves unrelated actions that reuse those hook slots.

Do not add Fleet's optional `prefix` + `n` next-waiting binding or window-list state rollup here. Tmux keeps its normal next-window binding, and Nightfly remains the source of truth for window formats.

## Verification

Use an isolated tmux socket for config checks:

```bash
tmux -L fleet-check -f ~/.config/tmux/tmux.conf new-session -d
tmux -L fleet-check show-options -gv status
tmux -L fleet-check show-options -gv 'status-format[1]'
tmux -L fleet-check list-keys -T prefix | rg 'fleet sidebar'
tmux -L fleet-check list-keys -T prefix | rg 'F.*display-popup.*fleet'
tmux -L fleet-check kill-server
```

Run `fleet doctor` after the native installers. For end-to-end verification, start fresh Claude and Codex sessions in tmux and confirm their state transitions in the status row, sidebar, and `prefix` + `F` popup.
