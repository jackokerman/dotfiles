# tmux and Fleet

This directory defines the tmux keybindings, Nightfly theme, and Fleet agent dashboard integration.

## Status bar

- The first row keeps the full tmux session name and numbered window name because those identify the workspace and distinguish programs such as an editor and Fleet.
- The right side omits the volatile pane title. It shows `pane N/M` only when the current window is split, followed by a compact clock.
- The second row is Fleet's attention surface. It always shows the sidebar button and adds a named agent only when it needs permission, has a question, or is ready for review.

## Fleet workflow

- `Ctrl+F` opens the Fleet dashboard in a 55% by 60% popup, matching the sesh popup dimensions.
- `Ctrl+S` runs `fleet sidebar --from '#{pane_id}'`, so Fleet toggles one 34-column sidebar in the invoking window.
- `Ctrl+N` runs `fleet next`, jumping to the highest-priority waiting agent and cycling through waiting agents on repeated presses. Fleet orders permission prompts before questions, then completed agents ready for review.
- All three bindings work without the tmux prefix in both normal and nested pass-through modes.
- `?` inside Fleet shows its dashboard keybindings.
- Working and idle agents remain visible in the Fleet dashboard and sidebar without occupying the status bar.

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
tmux -L fleet-check list-keys -T root | rg 'C-f.*display-popup.*fleet'
tmux -L fleet-check list-keys -T root | rg 'C-s.*fleet sidebar'
tmux -L fleet-check list-keys -T root | rg 'C-n.*fleet next'
tmux -L fleet-check list-keys -T off | rg 'C-[fsn].*fleet'
tmux -L fleet-check kill-server
```

For end-to-end verification, start a fresh Codex session in tmux and confirm its state transitions in the status row, sidebar, and `prefix` + `F` popup.
