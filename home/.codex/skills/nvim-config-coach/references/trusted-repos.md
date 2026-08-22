# Trusted Repos

Use these repos as inspiration after checking official plugin docs and current community practice. Do not copy their architecture or plugin manager choices blindly.

## `nicknisi/dotfiles`

- Repo: `https://github.com/nicknisi/dotfiles`
- Best for modern Neovim workflow ideas, especially `snacks.nvim`, Treesitter, and polished editor UX.
- Use this repo when you want a mature real-world example of modern plugin ergonomics or keymap patterns.

## `joshmedeski/dotfiles`

- Repo: `https://github.com/joshmedeski/dotfiles`
- Best for terminal workflow ideas, `sesh` and `tmux` integration, and lightweight plugin overrides in a broader LazyVim setup.
- Use this repo for UX inspiration, not as a direct `vim.pack` architecture template.

## `josean-dev/dev-environment-files`

- Repo: `https://github.com/josean-dev/dev-environment-files`
- Best for beginner-friendly community defaults and approachable examples of popular plugins such as Telescope, which-key, and Treesitter.
- Use this repo when you need to sanity-check whether a plugin is broadly adopted or easy for a newer user to learn.

## `nvim-lua/kickstart.nvim`

- Repo: `https://github.com/nvim-lua/kickstart.nvim`
- Best for readable, mainstream Neovim defaults and small config option examples.
- Use this repo when adding a new option, keymap, autocmd, or plugin setup to check whether there is a simple baseline pattern before reaching for a more customized dotfiles example.

## `sodiumjoe/dotfiles`

- Repo: `https://github.com/sodiumjoe/dotfiles`
- Best for pragmatic, work-oriented Neovim organization with plugin-focused Lua modules and accompanying tests.
- Use this repo for ideas on modular config boundaries and feature ownership, not as a package-manager template.

## How To Use Them

- Use these repos as tie-breakers and inspiration, not as the source of truth.
- For picker, file explorer, search, and navigation tasks, inspect the current Neovim config in the trusted repos before recommending a direction.
- Compare what the repos are currently using for plugin choice, keymap shape, and workflow fit; do not preserve stale summaries of their choices in this reference.
- Translate ideas into the current small `vim.pack` config instead of importing a repo's full style.
- Prefer borrowing a narrow pattern such as a keymap, module boundary, or plugin option over borrowing an entire stack.
