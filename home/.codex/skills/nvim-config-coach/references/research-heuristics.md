# Research Heuristics

Use these rules when evaluating Neovim changes for this setup.

## Source Order

1. Read the live local config.
2. Read official docs, help pages, READMEs, and compatibility notes.
3. Check community adoption and maintenance health.
4. Use the trusted repos for inspiration and concrete configuration examples.

## Plugin Selection

- Check built-in Neovim first.
- Check whether an existing plugin already solves the request before adding a new one.
- Prefer plugins with clear docs, active maintenance, and a narrow dependency surface.
- Prefer the smallest tool that cleanly solves the current request.
- Avoid adding a plugin platform, helper layer, or abstraction just to prepare for hypothetical future features.

## `snacks.nvim` Policy

- Evaluate `snacks.nvim` first for capabilities that align with its module set, such as pickers, explorer-style workflows, input, notifier, terminal, dashboard, scratch buffers, rename helpers, or UI toggles.
- Choose `snacks.nvim` when it is mature for the requested capability and keeps the config simpler than adding a separate plugin.
- Skip `snacks.nvim` when the community has clearly converged on a different tool, when the standalone tool is materially better documented, or when the feature fit is obviously stronger elsewhere.
- Do not force Snacks into areas it does not naturally own, such as LSP setup, formatting, or unrelated editor infrastructure.

## Reference Repo Usage

- Use the trusted repos to see how experienced users map keys, name modules, and wire features into real configs.
- Do not copy package-manager-specific syntax from `lazy.nvim` or distro-specific APIs into this `vim.pack` setup.
- Do not treat a trusted repo's choice as automatically correct for this config. Re-justify it against the current local baseline and the official docs.

## Option Presentation

- Present one recommended approach and one fallback by default.
- Explain why the recommended option fits this setup better, not just why it is popular.
- Call out external CLI prerequisites, changed keymaps, and likely maintenance cost.
- Keep the tradeoff summary concise unless the user asks for a deeper survey.

## Implementation Boundary

- Preserve `vim.pack` and the modular `lua/config/*.lua` layout.
- Keep plugin declarations in `lua/config/packages.lua`.
- Create a new `lua/config/<feature>.lua` file for a meaningful new capability.
- Extend an existing module instead of creating a new one when the change belongs to an existing concern.
- Keep the diff minimal and easy to explain.

## Teaching Mode

- Explain the chosen plugin or built-in feature in the context of the exact change.
- Tell the user how to trigger the new behavior, what keymaps or commands changed, and where the setup lives.
- Suggest one or two next things to explore instead of turning the answer into a broad Neovim course.
