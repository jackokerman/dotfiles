# tmux and Fleet

This directory defines the tmux keybindings, Nightfly theme, and Fleet agent dashboard integration.

## Fleet workflow

- `prefix` + `F` opens the Fleet dashboard in a 55% by 60% popup, matching the sesh popup dimensions.
- `prefix` + `f` runs `fleet sidebar --from '#{pane_id}'`, so Fleet toggles one 34-column sidebar in the invoking window.
- `?` inside Fleet shows its dashboard keybindings.
- The second status row always shows the sidebar button. It adds agents only when they need permission, have a question, or are ready for review; working and idle agents remain visible in the dashboard and sidebar.
- `prefix` + `n` keeps tmux's normal next-window behavior instead of running `fleet next`.

## Configuration ownership

- `tmux.conf` owns the Fleet bindings and loads the status row after the theme.
- `themes/nightfly.tmux` owns the first status row and normal session/window styling.
- `../fleet/theme.toml` owns Fleet's Nightfly agent-state palette.

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

For end-to-end verification, start a fresh Codex session in tmux and confirm its state transitions in the status row, sidebar, and `prefix` + `F` popup.
