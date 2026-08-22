# Current Local Layout

Use this file as a quick map of the current personal Neovim setup before reading the live files.

## Runtime And Entry Points

- Target runtime is currently `Neovim 0.12.x`.
- The entrypoint is `home/.config/nvim/init.lua`.
- `init.lua` currently loads, in order:
  - `config.options`
  - `config.keymaps`
  - `config.packages`
  - `config.navigation`
  - `config.discovery`
  - `config.lsp`
  - `config.format`

## Current Modules

### `lua/config/options.lua`

- Enables line numbers.
- Uses relative numbers off by default.
- Enables true color, clipboard integration, mouse support, and a persistent sign column.
- Uses right and below split defaults.
- Uses `ignorecase` plus `smartcase`.
- Enables `incsearch` and `undofile`.
- Uses 2-space indentation defaults.

### `lua/config/keymaps.lua`

- Sets `mapleader = " "` and `maplocalleader = "\\"`.
- Adds diagnostic navigation with `[d` and `]d`.
- Adds `<leader>d` for diagnostic float.
- Adds `<leader>f` for formatting the buffer or selection through `:Format`.

### `lua/config/packages.lua`

- Uses `vim.pack.add`, not `lazy.nvim`.
- Current plugins are:
  - `bluz71/vim-nightfly-colors`
  - `folke/snacks.nvim`
  - `folke/which-key.nvim`
  - `neovim/nvim-lspconfig`
  - `stevearc/conform.nvim`
- Sets the colorscheme in the same file.
- Treat this as the declaration boundary. Plugin setup belongs in the feature module that owns the behavior.

### `lua/config/navigation.lua`

- Wraps `snacks.nvim`.
- Enables the picker and explorer modules.
- Replaces netrw with Snacks explorer.
- Includes hidden files in explorer, file picker, and grep sources.
- Adds keymaps for file explorer, file search, grep, buffers, recent files, keymaps, commands, help, and diagnostics.

### `lua/config/discovery.lua`

- Wraps `which-key.nvim`.
- Disables mapping icons.
- Adds leader groups for code and search actions.
- Adds `<leader>?` for buffer-local keymap discovery.

### `lua/config/lsp.lua`

- Configures diagnostics with rounded float borders and severity sorting.
- Adds local `LspAttach` keymaps for definition, references, hover, rename, and code actions.
- Enables `ts_ls` and `eslint`.
- Includes an explicit `eslint` config that disables format-on-save behavior.

### `lua/config/format.lua`

- Wraps `conform.nvim`.
- Exposes a user command `:Format` with range support.
- Uses Prettier for the current web-oriented filetypes.
- Forces `lsp_format = "never"` in the current setup.

## Conventions To Preserve

- Read `home/.config/nvim/README.md` for the human-facing module and plugin ownership map.
- Keep the config small and modular under `lua/config/`.
- Prefer direct Neovim APIs over framework layers.
- Treat `packages.lua` as the plugin declaration boundary.
- Configure plugins in the feature module that owns the behavior, not in a single `lazy.nvim`-style plugin spec file.
- Add a new `lua/config/<feature>.lua` file only when a capability deserves its own setup.
- Keep keymaps intentional, documented with `desc`, and quiet with `silent = true` when appropriate.
- Use `home/.config/nvim/nvim-pack-lock.json` as the lockfile for plugin state.
