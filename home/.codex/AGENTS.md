# Personal Codex Preferences

## Communication
- Be concise and direct.
- Be informal but not too casual. Write complete sentences with grammatical subjects and verbs, even in casual drafting like Slack messages, PR descriptions, review comments, or short status updates.
- Avoid validation-heavy filler.
- Challenge weak assumptions when needed.
- Prefer concrete code or commands over long explanations.

## Writing Workflow
- For drafting-heavy writing tasks such as Slack messages, PR descriptions, Jira comments, review comments, or status updates, use the native `writing-style` skill before substantial drafting.
- For reusable Slack paste workflows where the message is already drafted and the goal is rich-text clipboard copy or direct paste into a focused composer, use the native `slack-clipboard` skill. Prefer authenticated Slack tools when the user wants actual delivery.
- Keep universal writing invariants that should always apply in `AGENTS.md`. Keep richer examples and drafting guidance in the `writing-style` skill.
- On markdown-capable surfaces, wrap exact technical identifiers in backticks. Use this for literal code-facing names such as files, paths, commands, components, hooks, functions, flags, operators, and packages. Skip generic concepts, issue or ticket IDs that should be linked semantically, and plain-text surfaces such as commit messages. PR titles and descriptions support markdown, so use backticks there when they improve precision.

## Engineering Style
- Default to the simplest implementation that fully solves the stated problem.
- Do not add abstractions, fallback paths, configuration knobs, or future-proofing unless the current requirement needs them.
- Avoid speculative defensive coding. Add guards, retries, parsing, normalization, or recovery logic only for a concrete failure mode, explicit requirement, or established codebase pattern.
- Do not add features, alternate flows, or edge-case handling that were not requested.
- Prefer fixing the actual boundary where data is consumed instead of pre-validating or transforming inputs earlier "just in case."
- Keep the happy path readable and direct. If extra complexity is necessary, make the reason concrete.
- Prefer strict equality checks over loose `==` or `!=` comparisons. Use explicit `=== null` and `=== undefined` checks when nullish handling matters.
- Prefer early returns and straightforward conditional blocks over non-trivial ternaries. Simple boolean checks such as `if (!value)` and short `&&` conditions are fine when they read clearly.
- Avoid deeply nested conditionals. When branching starts to nest, use guard clauses, a small helper, or a named boolean to keep the control flow easy to scan.
- Add concise multi-line JSDoc for exported functions, hooks, components, and types when it improves editor hints or clarifies a non-obvious contract.

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

## Godspeed Workflow
- For Godspeed inbox triage, Godspeed task planning, or requests to organize the work or personal inbox, use the native `godspeed-tasks` skill.
- Keep Godspeed triage read-only by default. Use the child `📥 Inbox` lists under `🏢 Work` and `🏡 Personal`, not the top-level default inbox.

## Neovim Workflow
- For personal Neovim config changes, plugin selection, keymap design, or requests to grow the editor setup incrementally, use the native `nvim-config-coach` skill before substantial edits.
- Keep the generic Neovim workflow guidance in tracked Codex skills under `home/.codex/skills/`, not in `AGENTS.md`.

## Codex Config Workflow
- For requests to improve Codex behavior, convert session corrections into durable steering, inspect previous Codex sessions for repeated friction, or decide where Codex config belongs in the dotty chain, use the native `codex-config-coach` skill.
- After several turns of user correction around drafting style, review phrasing, implementation style, or workflow, proactively use `codex-config-coach` before finishing to decide whether a small durable steering update belongs in config.
- Keep generic reusable Codex steering in this repo. Route private, machine-specific, or overlay-specific guidance to the later dotty-chain repo that owns it.

## Dotfiles Workflow
- In personal dotty-managed repos, the task is not done until changes are committed and pushed to `main`.
- Use conventional commits.
- After changing linked config, hooks, or generated Codex sources, run `dotty update` before finishing.
