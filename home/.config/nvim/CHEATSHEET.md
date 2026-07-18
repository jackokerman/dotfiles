# Neovim Cheat Sheet

`<leader>` is `Space`. Press `q` to close this sheet.

## Discover

| Keys | Action |
| --- | --- |
| `<leader>?` | Open this cheat sheet |
| `<leader>sk` | Search active keymaps |
| `<leader>sh` | Search Neovim help |
| `:Tutor` | Open the interactive tutorial |
| `:help quickref` | Open the built-in quick reference |

## Move

| Keys | Action |
| --- | --- |
| `h` `j` `k` `l` | Left, down, up, right |
| `w` / `b` / `e` | Next word, previous word, end of word |
| `0` / `^` / `$` | Line start, first text, line end |
| `gg` / `G` | Start/end of file |
| `{` / `}` | Previous/next paragraph |
| `%` | Matching bracket, brace, or parenthesis |
| `f<char>` / `t<char>` | Jump to/before a character on the line |
| `;` / `,` | Repeat/reverse the last `f` or `t` |
| `<C-d>` / `<C-u>` | Half-page down/up |
| `zz` | Center the current line |

## Search And Jump

| Keys | Action |
| --- | --- |
| `/text` | Search forward |
| `n` / `N` | Next/previous search result |
| `*` / `#` | Search forward/backward for word under cursor |
| `<C-o>` / `<C-i>` | Back/forward through jump history |
| `gd` / `gr` | Go to definition/references |
| `K` | Show documentation for symbol |

## Edit

Operators combine with motions: `d` delete, `c` change, and `y` yank.

| Keys | Action |
| --- | --- |
| `i` / `a` | Insert before/after cursor |
| `o` / `O` | Open a line below/above |
| `v` / `V` | Select characters/lines |
| `x` | Delete character |
| `p` / `P` | Paste after/before |
| `u` / `<C-r>` | Undo/redo |
| `.` | Repeat the last change |
| `dw` / `d$` | Delete word/to end of line |
| `ciw` / `ci"` | Change inside word/quotes |
| `di{` / `yap` | Delete inside braces/yank paragraph |

## Files And Windows

| Keys | Action |
| --- | --- |
| `<C-p>` / `<leader>/` | Find files/search project text |
| `<leader>e` | Open file explorer |
| `<leader>,` / `<leader>r` | Open buffers/recent files |
| `<C-w>h/j/k/l` | Move between windows |
| `<C-w>w` / `<C-w>c` | Cycle/close windows |
| `:w` / `:q` / `:qa` | Save/quit/quit all |
