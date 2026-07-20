# Neovim config

This config uses Neovim's built-in `vim.pack` plugin manager with a small feature-oriented module layout. Keep plugin declarations in `lua/config/packages.lua`, then configure each plugin in the module that owns the editor capability.

## Layout

| Path | Owns |
| --- | --- |
| `init.lua` | Load order for the config modules. |
| `lua/config/options.lua` | Core editor options. |
| `lua/config/keymaps.lua` | Global keymaps that are not owned by one plugin feature. |
| `lua/config/packages.lua` | `vim.pack.add` declarations and the colorscheme load. |
| `lua/config/navigation.lua` | File explorer, file picker, grep, buffers, recent files, and search pickers through `snacks.nvim`. |
| `lua/config/discovery.lua` | Keymap discovery and leader groups through `which-key.nvim`. |
| `lua/config/lsp.lua` | Diagnostics, LSP attach keymaps, and enabled language servers through `nvim-lspconfig`. |
| `lua/config/format.lua` | The `:Format` command and formatter routing through `conform.nvim`. |
| `nvim-pack-lock.json` | Locked plugin revisions managed by `vim.pack`. Do not edit this by hand. |

## Plugin ownership

| Plugin | Declared in | Configured by |
| --- | --- | --- |
| `nightfly` | `lua/config/packages.lua` | `lua/config/packages.lua` |
| `snacks.nvim` | `lua/config/packages.lua` | `lua/config/navigation.lua` |
| `which-key.nvim` | `lua/config/packages.lua` | `lua/config/discovery.lua` |
| `nvim-lspconfig` | `lua/config/packages.lua` | `lua/config/lsp.lua` |
| `conform.nvim` | `lua/config/packages.lua` | `lua/config/format.lua` |

## Conventions

- Add new plugins to `lua/config/packages.lua`.
- Put setup code in an existing feature module when the plugin clearly belongs there.
- Create a new `lua/config/<feature>.lua` module only when a new editor capability needs its own setup.
- Keep `init.lua` as the readable load-order map.
- Use `:lua vim.pack.update(nil, { offline = true })` to inspect plugin state and `:lua vim.pack.update()` to update plugins.
