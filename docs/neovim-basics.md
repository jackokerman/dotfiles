# Vim Basics in Neovim

Use `which-key` for the configured mappings that are active in Neovim. Press `Space` and pause to see leader mappings, or pause after a prefix such as `d`, `c`, `y`, `<C-w>`, `g`, or `z` to see the available next keys.

For broader learning and reference:

- Run `:Tutor` for the interactive tutorial.
- Run `:help quickref` for Neovim's built-in quick reference.
- Search `:help` when a command or concept needs more detail.

## Movement

| Keys | Action |
| --- | --- |
| `h` `j` `k` `l` | Move left, down, up, or right. |
| `w` / `b` / `e` | Move to the next word, previous word, or end of the word. |
| `0` / `^` / `$` | Move to the line start, first text, or line end. |
| `gg` / `G` | Move to the start or end of the file. |
| `{` / `}` | Move to the previous or next paragraph. |
| `%` | Move to the matching bracket, brace, or parenthesis. |
| `f<char>` / `t<char>` | Move to or before a character on the line. |
| `;` / `,` | Repeat or reverse the last `f` or `t`. |
| `<C-d>` / `<C-u>` | Move down or up half a page. |
| `zz` | Center the current line. |

## Search and jump

| Keys | Action |
| --- | --- |
| `/text` | Search forward. |
| `n` / `N` | Move to the next or previous search result. |
| `*` / `#` | Search forward or backward for the word under the cursor. |
| `<C-o>` / `<C-i>` | Move backward or forward through jump history. |

## Operators and motions

Vim edits are built from an operator followed by a motion or text object. The common operators are `d` for delete, `c` for change, and `y` for yank.

| Keys | Action |
| --- | --- |
| `dw` / `d$` | Delete a word or to the end of the line. |
| `ciw` / `ci"` | Change inside a word or quoted string. |
| `di{` / `yap` | Delete inside braces or yank a paragraph. |

## Editing

| Keys | Action |
| --- | --- |
| `i` / `a` | Insert before or after the cursor. |
| `o` / `O` | Open a line below or above. |
| `v` / `V` | Select characters or lines. |
| `x` | Delete the character under the cursor. |
| `p` / `P` | Paste after or before the cursor. |
| `u` / `<C-r>` | Undo or redo. |
| `.` | Repeat the last change. |

## Windows and files

| Keys | Action |
| --- | --- |
| `<C-w>h/j/k/l` | Move between windows. |
| `<C-w>w` / `<C-w>c` | Cycle through or close windows. |
| `:only` | Close every window except the current one. |
| `:w` / `:q` / `:qa` | Save, quit, or quit all. |
