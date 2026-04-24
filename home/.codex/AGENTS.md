# Personal Codex Preferences

## Communication
- Be concise and direct.
- Be informal but not too casual. Write complete sentences with grammatical subjects and verbs, even in casual drafting like Slack messages, PR descriptions, review comments, or short status updates.
- Avoid validation-heavy filler.
- Challenge weak assumptions when needed.
- Prefer concrete code or commands over long explanations.

## Writing Workflow
- For drafting-heavy writing tasks such as Slack messages, PR descriptions, Jira comments, review comments, or status updates, use the native `writing-style` skill before substantial drafting.
- Keep universal writing invariants that should always apply in `AGENTS.md`. Keep richer examples and drafting guidance in the `writing-style` skill.

## Engineering Style
- Default to the simplest implementation that fully solves the stated problem.
- Do not add abstractions, fallback paths, configuration knobs, or future-proofing unless the current requirement needs them.
- Avoid speculative defensive coding. Add guards, retries, parsing, normalization, or recovery logic only for a concrete failure mode, explicit requirement, or established codebase pattern.
- Do not add features, alternate flows, or edge-case handling that were not requested.
- Prefer fixing the actual boundary where data is consumed instead of pre-validating or transforming inputs earlier "just in case."
- Keep the happy path readable and direct. If extra complexity is necessary, make the reason concrete.

## Tooling
- Prefer Bun and TypeScript for helper scripts when a scripting language is appropriate.
- Use another runtime only when it has a clear operational advantage.

## Research Workflow
- For questions about tool behavior, configuration, library or framework semantics, APIs, or documented workflows, prefer deterministic verification over inference.
- Check the strongest available sources first: official docs, local CLI help, tracked config, local types, project usages, tests, or repo sources.
- Use official documentation as the primary source of truth for public product, library, framework, and API behavior.
- If the docs are unclear or incomplete and source code is available, inspect the relevant implementation, schema, types, examples, or tests before answering.
- Be explicit about what was confirmed from docs, source, or local usage and what remains uncertain. Avoid conjecture when verification is possible.

## Routing
- Generic personal preferences and reusable non-work Codex setup belong in the public `dotfiles` repo.
- Company-specific workflow, permissions, and work-only Codex setup belong in the private overlay repo.
- If a change is generic enough to help on personal machines, keep it out of the private overlay.

## Frontend Workflow
- For clearly React work, use the native `react-patterns` skill before substantial edits.
- For clearly TypeScript or TSX work, use the native `typescript-style` skill before substantial edits.
- For clearly CSS, layout, spacing, sizing, overflow, positioning, or stacking work, use the native `css-layout` skill before substantial edits.
- Keep reusable frontend guidance in tracked Codex skills under `home/.codex/skills/`, not in `AGENTS.md`.
- Do not apply this React guidance to non-frontend tasks.

## Dotfiles Workflow
- In personal dotty-managed repos, the task is not done until changes are committed and pushed to `main`.
- Use conventional commits.
- After changing linked config, hooks, or generated Codex sources, run `dotty update` before finishing.
