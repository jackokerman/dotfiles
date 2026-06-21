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

## Execution Workflow
- For non-trivial implementation work, translate the request into the smallest verifiable outcome before editing.
- When a request has materially different interpretations, state the choice or ask before editing instead of silently taking the broadest interpretation.
- For local machine, shell, or environment debugging, remove or disable the upstream source first. Add a tracked startup workaround only after reproducing the need in a fresh process and confirming the source fix is insufficient.
- For bug fixes or behavior changes, prefer a focused reproduction or failing test first, then make it pass when practical.
- When a command, browser auth flow, or external tool requires user interaction, state the needed action explicitly and stop polling or retrying until the user confirms it is complete.
- When debugging an external flow, distinguish clearly between “I need your intervention now” and “I’m still fixing this locally” so the user does not have to infer which state you are in.
- Before pushing, re-check `git status --short --branch` and the commits ahead of the upstream branch. If unexpected unpushed commits or unrelated dirty files are present, report them and confirm the push scope instead of silently including concurrent work.
- Before finishing, run the smallest verification that covers the change and report what was and was not verified.
- For loud but routine verification commands, redirect output to a temp log and inspect or show the log only on failure. Use live output when diagnosing a failing command, monitoring meaningful progress, or when the user asks to see the full output.

## Tooling
- Prefer Bun and TypeScript for helper scripts when a scripting language is appropriate.
- Use another runtime only when it has a clear operational advantage.
- For Raycast Script Commands, check the official Raycast Script Commands docs and `raycast/script-commands` examples before changing metadata, output modes, or UI behavior. Choose modes by documented semantics: `fullOutput` for long-running/log output, `compact` or `silent` for simple last-line results, and `inline` for dashboard/status items with `refreshTime`; Extension API functions such as `closeMainWindow` are not available inside Bash Script Commands.

## Research Workflow
- For questions about tool behavior, configuration, library or framework semantics, APIs, or documented workflows, prefer deterministic verification over inference.
- Check the strongest available sources first: official docs, local CLI help, tracked config, local types, project usages, tests, or repo sources.
- For file and text discovery, prefer `rg` tools directly. Use `rg --hidden --files` for hidden dotfiles/config trees instead of raw `find`, and use `rg '<pattern>'` instead of `grep`; local hooks may block slower raw search commands and waste retries.
- When a plan depends on a public tool's limitation, missing feature, workaround, or adoption path, check the upstream issue and PR tracker before concluding the path is unsupported or recommending custom tooling.
- When the user provides a code permalink, file path, or line range, inspect that exact target before answering or broadening to surrounding context.
- In large repositories, start searches from the narrowest known path and identifiers, especially when an error already provides a file, line, symbol, or test name. Avoid broad searches for common terms until scoped searches fail.
- For commit-only or review-only Git tasks, start with `git status --short` and the relevant `git diff`; do not scan the repo for candidate files when the modified path is already known.
- Use official documentation as the primary source of truth for public product, library, framework, and API behavior.
- If the docs are unclear or incomplete and source code is available, inspect the relevant implementation, schema, types, examples, or tests before answering.
- When adopting a tool with install profiles, feature tiers, or optional integrations, verify the selected surface exposes the specific commands and files the workflow will rely on.
- Be explicit about what was confirmed from docs, source, or local usage and what remains uncertain. Avoid conjecture when verification is possible.

## Tool Adoption Workflow
- When adopting or configuring a new development tool, start with the smallest useful workflow that preserves the tool's core value. Keep optional automation, extra artifacts, and broad integrations off by default until repeated use shows they are worth the added ceremony.
- Prefer a reversible, documented default path before adding custom wrappers or helper scripts. Add custom tooling only after the off-the-shelf workflow still causes repeated friction.

## Routing
- Generic personal preferences and reusable non-work Codex setup belong in the public `dotfiles` repo.
- Later configuration layers own their own workflow, permissions, and Codex setup.
- If a change is generic enough to help on personal machines, keep it out of the private overlay.

## Frontend Workflow
- For clearly React work, use the native `react-patterns` skill before substantial edits.
- For clearly TypeScript or TSX work, use the native `typescript-style` skill before substantial edits.
- For clearly CSS, layout, spacing, sizing, overflow, positioning, or stacking work, use the native `css-layout` skill before substantial edits.
- Keep reusable frontend guidance in tracked portable skills under `home/.ruler/skills/`, not in `AGENTS.md`.
- Do not apply this React guidance to non-frontend tasks.

## Godspeed Workflow
- For Godspeed inbox triage, Godspeed task planning, or requests to organize the work or personal inbox, use the native `godspeed-tasks` skill.
- Use the child `📥 Inbox` lists under `🏢 Work` and `🏡 Personal`, not the top-level default inbox.
- Use the Godspeed API through `GODSPEED_API_TOKEN` for task mutation. Keep public repo guidance generic: do not track personal category names, matching rules, or smart-list definitions here.
- Allow direct writes for explicit objective updates. Require preview or approval before bulk, heuristic, or subjective categorization changes.

## Neovim Workflow
- For personal Neovim config changes, plugin selection, keymap design, or requests to grow the editor setup incrementally, use the native `nvim-config-coach` skill before substantial edits.
- Keep the generic Neovim workflow guidance in tracked portable skills under `home/.ruler/skills/`, not in `AGENTS.md`.

## Codex Config Workflow
- For requests to improve Codex behavior, convert session corrections into durable steering, inspect previous Codex sessions for repeated friction, or decide where Codex config belongs in the dotty chain, use the native `codex-config-coach` skill.
- After several turns of user correction around drafting style, review phrasing, implementation style, or workflow, proactively use `codex-config-coach` before finishing to decide whether a small durable steering update belongs in config.
- Keep generic reusable Codex steering in this repo. Route private, machine-specific, or overlay-specific guidance to the later dotty-chain repo that owns it.
- Keep always-loaded `AGENTS.md` guidance thin: durable routing, safety, and universal behavior belong here; detailed workflow procedure belongs in skills or deferred reference files.
- For generated skill outputs under `~/.codex/skills/` or `~/.claude/skills/`, use the managed index in that skills directory to find the tracked source. Generic portable skills are sourced from `home/.ruler/skills/<name>/`; Codex-native skills such as `codex-config-coach` remain sourced from `home/.codex/skills/<name>/`.

## Dotfiles Workflow
- In personal dotty-managed repos, the task is not done until changes are committed and pushed to `main`.
- Use conventional commits.
- After changing linked config, hooks, or generated Codex sources, run `dotty update` before finishing.
