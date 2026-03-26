---
name: nerd-font
description: Advisory for safely editing files containing nerd font icons (PUA characters). Loads when working on tmux configs, terminal prompts, status bars, or CLI scripts with glyph rendering.
user-invocable: false
---

# Nerd font icons

## Background

Nerd Fonts patch programming fonts with thousands of icons from Font Awesome, Devicons, Octicons, etc. These icons live in Unicode's Private Use Area (PUA), primarily:

- `U+E000–U+F8FF` (BMP PUA)
- `U+F0000–U+FFFFF` (Supplementary PUA-A)

The Ghostty terminal config uses `font-family` for the primary font and `font-family = "Symbols Nerd Font Mono"` as a fallback to render these glyphs.

## The corruption problem

Claude Code's Edit and Write tools silently strip or corrupt PUA characters. These characters are invisible in most editors and look like empty strings in tool output, so corruption is easy to miss.

**Real incident:** Commit `95824f0` in dotfiles moved the Claude tmux session status bar from an overlay repo. The nerd font icons (check, clock, bolt) were silently stripped during the move, leaving colored session names with no icons. The fix required restoring exact bytes via `sed` + `printf`.

## Safe insertion method

Never use the Edit or Write tools to insert nerd font icons. Instead, use `sed` with `printf` hex escapes:

```bash
# Insert a single icon
sed -i '' "s/PATTERN/REPLACEMENT$(printf '\xef\x80\x8c')SUFFIX/" file.sh

# Or write a placeholder and replace it
echo 'status="ICON_CHECK Done"' > file.sh
sed -i '' "s/ICON_CHECK/$(printf '\xef\x80\x8c')/" file.sh
```

To find the hex bytes for any codepoint:

```bash
printf '\U0000F00C' | xxd -p  # outputs: ef808c
```

## Safe editing of files with existing icons

When editing a file that already contains nerd font icons:

1. **Prefer `sed`** for targeted changes. It preserves bytes it doesn't touch.
2. **If Edit/Write is unavoidable**, hex dump the relevant lines before and after to verify icons survived:
   ```bash
   sed -n '29,31p' file.sh | xxd
   ```
3. **Never trust visual inspection alone.** PUA characters can appear as blank in tool output even when present.

## Common icons reference

| Name | Icon | Codepoint | printf command |
|------|------|-----------|----------------|
| check | nf-fa-check | `U+F00C` | `printf '\xef\x80\x8c'` |
| times | nf-fa-times | `U+F00D` | `printf '\xef\x80\x8d'` |
| clock | nf-fa-clock_o | `U+F017` | `printf '\xef\x80\x97'` |
| bolt | nf-fa-bolt | `U+F0E7` | `printf '\xef\x83\xa7'` |
| git-branch | nf-dev-git_branch | `U+E725` | `printf '\xee\x9c\xa5'` |
| folder | nf-fa-folder | `U+F07B` | `printf '\xef\x81\xbb'` |
| file | nf-fa-file | `U+F15B` | `printf '\xef\x85\x9b'` |
| warning | nf-fa-warning | `U+F071` | `printf '\xef\x81\xb1'` |
| info | nf-fa-info_circle | `U+F05A` | `printf '\xef\x81\x9a'` |
| cog | nf-fa-cog | `U+F013` | `printf '\xef\x80\x93'` |
| arrow-right | nf-fa-arrow_right | `U+F061` | `printf '\xef\x81\xa1'` |
| search | nf-fa-search | `U+F002` | `printf '\xef\x80\x82'` |

## Looking up arbitrary icons

Browse [nerdfonts.com/cheat-sheet](https://www.nerdfonts.com/cheat-sheet) for the full catalog. To convert any codepoint to printf bytes:

```bash
# From codepoint to printf command
codepoint="F00C"
printf "\\U0000${codepoint}" | xxd -p | sed 's/\(..\)/\\x\1/g'
# Output: \xef\x80\x8c
```
