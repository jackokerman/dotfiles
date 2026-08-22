---
name: terminal-rendering
description: "Use when diagnosing terminal or TUI rendering problems: ANSI color/theme mismatches, truecolor vs xterm-256 vs terminal-palette behavior, Markdown/code renderer differences, pager output, tmux or fzf preview wrapping, or CLI UI screenshots that look different from expected."
---

# Terminal Rendering

## Overview

Use this skill to debug terminal presentation from observable output instead of screenshots alone. Separate renderer behavior, terminal color semantics, width/pager context, and local config before changing themes or wrappers.

## Workflow

1. Reproduce the exact surface: direct terminal, tmux pane, fzf preview, pager, or piped stdout. Record the command and relevant env such as `TERM`, `COLORTERM`, `NO_COLOR`, `CLICOLOR_FORCE`, `PAGER`, renderer-specific theme vars, and width vars.
2. Build a tiny fixture plus one real fixture. Include the construct under debate, such as wrapped bullets, Markdown headings, fenced code blocks, comments, strings, links, or tables.
3. Compare raw ANSI output before trusting visual impressions:

```bash
renderer command > /tmp/rendered.txt
perl -pe 's/\e/\\e/g' /tmp/rendered.txt | sed -n '1,120p'
rg -o $'\x1b\\[[0-9;]*m' /tmp/rendered.txt | sort | uniq -c
```

4. Classify color semantics explicitly. Distinguish terminal-palette SGR codes such as `31`, `37`, and `93`; xterm-256 codes such as `38;5;222`; and truecolor codes such as `38;2;r;g;b`. Do not assume the same hex color can force the same terminal palette slot across tools.
5. Inspect config ownership. Check tracked source, generated/live config, command flags, global defaults, and wrapper scripts. For width issues, test both inside and outside the target pane before adding or removing fixed width settings.
6. Verify the exposed control surface from strongest sources first: local `--help`, official docs, local config schema/types, then upstream source. If a library has a knob, confirm whether the actual CLI exposes it before recommending it.
7. Make narrow changes only. Tune one token, width source, or renderer option at a time; re-run the ANSI comparison and the target visual check after each change. Avoid broad theme rewrites based only on one screenshot.
8. When choosing a renderer, state the tradeoff plainly. Markdown renderers usually read better for documents; code viewers usually match syntax themes better. Prefer a primary renderer plus a simple fallback when that matches the workflow.

## Upstream Limits

When the desired behavior appears unsupported, check upstream issues or PRs before concluding. Capture the exact confirmed boundary: "supported by underlying library but not exposed by CLI", "available only in TTY mode", "disabled when stdout is piped", or "renderer intentionally normalizes to xterm-256".
