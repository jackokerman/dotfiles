---
name: nerd-font
description: Use when editing Nerd Font icons, Private Use Area glyphs, terminal prompts, tmux status bars, or CLI UI symbols.
---

# Nerd Font Glyphs

Use this skill when a file contains or generates Nerd Font icons. Preserve exact bytes; do not trust how glyphs look in the editor.

## Background

Nerd Fonts patch programming fonts with icons from sets such as Font Awesome, Devicons, and Octicons. Many live in Unicode Private Use Area ranges:

- `U+E000` through `U+F8FF`
- `U+F0000` through `U+FFFFF`

They may render as icons, blanks, or replacement boxes depending on the tool. Visual inspection does not prove they survived an edit.

## Safe Editing Rules

- Prefer targeted command-line edits that preserve untouched bytes, such as `perl -0pi`, `sed`, or a proven formatter.
- Do not retype invisible glyphs by sight. Insert them from codepoints or byte escapes.
- Before editing a line with glyphs, capture a hex dump. After editing, compare the bytes that should have been preserved.
- Avoid broad rewrites of files containing glyphs unless the rewrite tool is known to preserve Private Use Area characters.

## Inserting Glyphs

Use codepoints or UTF-8 byte escapes:

```bash
# Print a Font Awesome check glyph by codepoint.
printf '\U0000F00C'

# Convert a codepoint to UTF-8 hex bytes.
printf '\U0000F00C' | xxd -p

# Convert a codepoint to printf-style byte escapes.
codepoint="F00C"
printf "\\U0000${codepoint}" | xxd -p | sed 's/\(..\)/\\x\1/g'
```

For macOS `sed`, use `-i ''`:

```bash
sed -i '' "s/ICON_CHECK/$(printf '\xef\x80\x8c')/" file.sh
```

For GNU `sed`, use `-i`:

```bash
sed -i "s/ICON_CHECK/$(printf '\xef\x80\x8c')/" file.sh
```

## Verifying Glyphs

Hex dump relevant lines before and after the edit:

```bash
sed -n '29,31p' file.sh | xxd
```

For a single expected codepoint:

```bash
printf '\U0000F00C' | xxd -p
```

If the expected bytes are absent after the edit, restore the line from git or reinsert the glyph from the codepoint/byte escape.

## Common Glyphs

| Name | Nerd Font name | Codepoint | UTF-8 bytes |
|------|----------------|-----------|-------------|
| check | `nf-fa-check` | `U+F00C` | `ef 80 8c` |
| times | `nf-fa-times` | `U+F00D` | `ef 80 8d` |
| clock | `nf-fa-clock_o` | `U+F017` | `ef 80 97` |
| bolt | `nf-fa-bolt` | `U+F0E7` | `ef 83 a7` |
| git branch | `nf-dev-git_branch` | `U+E725` | `ee 9c a5` |
| folder | `nf-fa-folder` | `U+F07B` | `ef 81 bb` |
| file | `nf-fa-file` | `U+F15B` | `ef 85 9b` |
| warning | `nf-fa-warning` | `U+F071` | `ef 81 b1` |
| info | `nf-fa-info_circle` | `U+F05A` | `ef 81 9a` |
| cog | `nf-fa-cog` | `U+F013` | `ef 80 93` |
| arrow right | `nf-fa-arrow_right` | `U+F061` | `ef 81 a1` |
| search | `nf-fa-search` | `U+F002` | `ef 80 82` |

Use the Nerd Fonts cheat sheet for icons not listed here, then verify the codepoint-to-byte conversion locally before editing tracked config.
