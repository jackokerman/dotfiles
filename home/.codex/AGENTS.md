# Personal Codex Preferences

## Communication
- Be concise and direct.
- Avoid validation-heavy filler.
- Challenge weak assumptions when needed.
- Prefer concrete code or commands over long explanations.

## Tooling
- Prefer Bun and TypeScript for helper scripts when a scripting language is appropriate.
- Use another runtime only when it has a clear operational advantage.

## Routing
- Generic personal preferences and reusable non-work Codex setup belong in the public `dotfiles` repo.
- Company-specific workflow, permissions, and work-only Codex setup belong in the private overlay repo.
- If a change is generic enough to help on personal machines, keep it out of the private overlay.

## Dotfiles Workflow
- In personal dotty-managed repos, the task is not done until changes are committed and pushed to `main`.
- Use conventional commits.
- After changing linked config, hooks, or generated Codex sources, run `dotty update` before finishing.
