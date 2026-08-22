# Vim Basics in Neovim

Use `which-key` for the configured mappings that are active in Neovim. In the tables below, `<leader>` means `Space`. Press `Space` and pause to see leader mappings, or pause after a prefix such as `d`, `c`, `y`, `<C-w>`, `g`, or `z` to see the available next keys.

For broader learning and reference:

- Run `:Tutor` for the interactive tutorial.
- Run `:help quickref` for Neovim's built-in quick reference.
- Search `:help` when a command or concept needs more detail.

## Files, Explorer, and windows

`<C-p>` means hold `Control` and press `p`. The Explorer is the file-tree sidebar on the left.

### Find files

| Keys | Action |
| --- | --- |
| `<C-p>` | Open the file picker. Type to filter, use `<C-j>` / `<C-k>` or the arrow keys to select, then press `Enter` to open. |
| `<leader>/` | Search for text across project files. |
| `<leader>,` | Switch between open buffers. |
| `<leader>r` | Open a recent file. |
| `<Esc>` | Close a picker without opening a result. |

### Explorer

| Keys | Action |
| --- | --- |
| `<leader>e` | Toggle the Explorer. |
| `j` / `k` in the Explorer | Move down or up the file tree. |
| `Enter` / `l` in the Explorer | Open the selected file or expand the selected directory. |
| `h` in the Explorer | Collapse the selected directory. |
| `q` in the Explorer | Close the Explorer. |

### Windows

| Keys | Action |
| --- | --- |
| `<C-w>h` / `<C-w>l` | Move into the Explorer on the left or back to the editor on the right. |
| `<C-w>w` | Cycle through open windows when their layout is unfamiliar. |
| `<C-w>c` | Close the current window. |
| `:only` | Close every window except the current one. |
| `:w` / `:q` / `:qa` | Save, quit, or quit all. |

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

## Markdown review

Markdown files render in place while you read them in normal mode. Enter insert mode to edit the raw Markdown; returning to normal mode restores the rendered view. On the cursor line, concealed syntax is revealed when needed for editing.

| Keys | Action |
| --- | --- |
| `<leader>mt` | Toggle rendering for the current Markdown buffer. |

## Diagnostics

A red squiggle marks the affected text, `E` in the gutter marks an error on that line, and a red icon in the explorer marks a file containing diagnostics.

| Keys | Action |
| --- | --- |
| `<leader>d` | Show the diagnostic under the cursor. |
| `]d` / `[d` | Move to the next or previous diagnostic. |
| `<leader>sd` | Search diagnostics across the project. |
| `<leader>ca` | Show available code actions. |
| `:LspInfo` | Inspect attached language servers. |

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
