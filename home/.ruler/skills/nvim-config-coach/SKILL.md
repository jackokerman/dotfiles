---
name: nvim-config-coach
description: Help incrementally grow or refine a personal Neovim config, especially when adding navigation, file picking, file browsing, search, keymaps, LSP, formatting, UI, or editor workflow improvements. Use when Codex should inspect the existing `vim.pack`-based setup, research modern Neovim best practices and plugin docs, compare one recommended approach plus one fallback, use trusted community dotfiles as inspiration, and then implement the chosen option with small teachable changes.
---

# Neovim Config Coach

Help a newer Neovim user grow a personal config slowly and intentionally. Optimize for small understandable changes, not for maximum plugin count or a one-shot perfect setup.

## Workflow

1. Inspect the current local config first.
   - Read `home/.config/nvim/init.lua`, `home/.config/nvim/lua/config/*.lua`, and `home/.config/nvim/nvim-pack-lock.json`.
   - Load [references/current-local-layout.md](references/current-local-layout.md) when you need the current baseline and conventions.
2. Restate the request in capability terms.
   - Identify the user's goal, expected UX, and whether the request is a new capability, a refinement, or a bug fix.
   - Check whether built-in Neovim or an existing plugin already covers the need before adding a dependency.
3. Research candidates in this order.
   - Read official plugin docs, READMEs, help pages, and recent compatibility notes first.
   - Check current community convergence and maintenance health.
   - Use trusted reference repos for inspiration, keymaps, and edge cases. Load [references/trusted-repos.md](references/trusted-repos.md) when needed.
   - Use [references/research-heuristics.md](references/research-heuristics.md) for selection rules and anti-cargo-cult guardrails.
4. Present options before editing unless the user explicitly asks for a direct patch.
   - Present exactly one recommended approach and one credible fallback.
   - For each option, cover fit with the current config, plugin choice, expected keymaps or commands, external prerequisites, likely maintenance cost, and how the trusted repos informed the recommendation.
   - Prefer concise tradeoffs over exhaustive surveys.
5. Implement only after the user chooses a direction, unless the user clearly wants the recommendation carried through immediately.
   - Preserve `vim.pack` and the modular `lua/config/*.lua` layout.
   - Keep `packages.lua` as the plugin declaration boundary unless an existing file already owns the dependency.
   - Add a focused `lua/config/<feature>.lua` module for new capabilities that need more than a few lines, and require it from `init.lua`.
   - Extend an existing module instead of creating a new one when the change clearly belongs to the current concern, such as LSP or formatting.
6. Teach while you edit.
   - Explain what changed, why it lives there, how to use it, and one or two next things to learn.
   - Prefer brief explanations tied to the actual diff instead of generic Neovim tutorials.

## Defaults

- Prefer incremental additions over framework migrations or config rewrites.
- Do not migrate this setup to `lazy.nvim`, LazyVim, or another distro as part of routine feature work.
- Prefer built-in Neovim features or existing plugins before adding a new dependency.
- Evaluate `snacks.nvim` first when it plausibly matches the requested capability, but do not force it.
- Recommend a standalone plugin when its docs, community adoption, or feature fit are materially stronger than the Snacks equivalent.
- Prefer stable, maintained, well-documented plugins over clever or trendy ones.
- Keep keymaps discoverable and minimal. Match existing local conventions such as `mapleader = " "`, `desc`, and `silent = true`.
- Do not add speculative abstractions, compatibility layers, or a large plugin platform for future possibilities.
- Prefer local config clarity over copying reference repos verbatim.

## Change Shapes

- Extend an existing module when the request clearly expands an existing concern such as LSP, formatting, or core keymaps.
- Add the plugin to `lua/config/packages.lua`, create `lua/config/<feature>.lua`, and require it from `init.lua` for a new capability that needs its own setup.
- Keep pure keymap or option tweaks in `keymaps.lua` or `options.lua` unless they are tightly coupled to a plugin feature.
- Explain why the old approach no longer fits before removing or replacing a plugin.

## Response Shape

Use this default shape unless the user asks for something shorter:

1. Current-state summary.
2. Recommended approach.
3. Fallback.
4. Key tradeoffs and prerequisites.
5. Implementation outline or diff summary.
6. Brief learning notes.

## References

- Use [references/current-local-layout.md](references/current-local-layout.md) to understand the current baseline.
- Use [references/trusted-repos.md](references/trusted-repos.md) when looking for inspiration from the specific repos the user trusts.
- Use [references/research-heuristics.md](references/research-heuristics.md) when choosing between `snacks.nvim`, built-ins, and standalone plugins.
