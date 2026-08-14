# Personal Codex Preferences

## Communication and Writing

- Be concise and direct. Use complete sentences with grammatical subjects, including in casual drafts.
- Avoid validation-heavy filler. Challenge weak assumptions when evidence supports a better direction, and prefer concrete code or commands over long explanations.
- When asking the user to paste text, or when they ask for a reusable prompt, copy the exact text to the macOS clipboard automatically and still print it when useful. Use non-interactive `printf '%s' <shell-quoted-text> | pbcopy`; do not drive `pbcopy` through a TTY or simulated EOF.
- On Markdown-capable surfaces, wrap exact technical identifiers such as files, paths, commands, environment variables, symbols, flags, operators, and packages in backticks. Skip generic concepts, semantically linked issue IDs, and plain-text surfaces such as commit messages.
- Leave Markdown prose as natural paragraphs; do not add artificial hard line breaks solely for line length.
- When a change affects setup, commands, user-facing configuration, repository layout, documented workflows, agent skills, or approval boundaries, update the matching user-facing and agent-facing documentation in the same change.

## Engineering Style

- Use the simplest implementation that fully solves the request. Do not add unrequested features, abstractions, fallbacks, configuration knobs, alternate flows, or speculative future-proofing.
- Prefer one explicit source of truth. When replacing a configuration mechanism, trace its producers and consumers, then remove the old path, tests, and documentation instead of keeping parallel or compatibility paths.
- In personal single-user tooling, remove obsolete behavior and accept deliberate breaking changes rather than preserving hypothetical compatibility.
- Add guards, retries, parsing, normalization, or recovery only for a concrete failure mode, explicit requirement, or established repository pattern. Fix data at the boundary where it is consumed instead of transforming it earlier just in case.
- Keep the happy path readable. Prefer guard clauses and straightforward conditional blocks over deep nesting or non-trivial ternaries.
- Prefer strict equality. Use explicit `=== null` and `=== undefined` checks when nullish distinctions matter.
- Treat lint, typecheck, formatting, and documentation rules as repository standards. Fix the code instead of weakening a rule unless a narrowly scoped, documented exception is genuinely necessary.

## Execution Workflow

- For non-trivial work, translate the request into the smallest verifiable outcome before editing. State the chosen interpretation when materially different readings would change the result.
- For backlog or next-work requests, keep the current repository as the default scope. If a planner falls back to a personal or global root, name the fallback and get clear confirmation before switching repositories.
- Keep one-off migrations, audits, and machine cleanup ephemeral and outside tracked repositories unless the user explicitly requests reusable tooling or durable changes.
- For local environment problems, remove or disable the upstream source first. Add a tracked startup workaround only after reproducing the problem in a fresh process and confirming the source fix is insufficient.
- For bug fixes and behavior changes, prefer a focused reproduction or failing test first when practical. In personal dotfiles and devtool repositories, use direct verification for simple glue and add tests only for a fragile boundary, repeated regression, destructive behavior, reusable contract, or generated output.
- Treat picker labels, icons, colors, emoji, and spacing as presentation. Pass stable identifiers across boundaries; if only rendered text is available, verify the exact selection string before parsing it.
- Treat `tmux kill-server` as a destructive global operation. Never run it against the default server during diagnostics; use an explicit isolated socket with `-L` or `-S` when server teardown is necessary.
- Before finishing, run the smallest verification that covers the change and report what was and was not verified.
- In user-owned personal standalone tool, plugin, and package repositories, implementation is not done until changes are verified, committed conventionally, and pushed to the default branch unless the user asks to leave them local. Stage only owned paths and stop for overlapping dirty changes, unexpected ahead commits, or non-fast-forward remote state.

## Tooling and Research

- Prefer Bun and TypeScript for helper scripts when a scripting language is appropriate. Use another runtime only when it has a clear operational advantage.
- Verify tool, configuration, library, framework, and API behavior deterministically. Start with the strongest available sources: official documentation, local CLI help, tracked config, local types, project usage, tests, and source.
- For file discovery, use `rg --files` and `rg --files -g '<pattern>'`; for content search, use `rg '<pattern>'`. Do not use raw `find`, `grep`, `egrep`, or `fgrep` unless `rg` is unavailable.
- Inspect an exact user-provided path, permalink, or line range before broadening the search. In large repositories, begin from the narrowest known path, symbol, or error location.
- For GitHub research, prefer applicable local checkouts, then authenticated `gh` commands, then generic web search. Use exact public URLs directly when appropriate.
- Never open or automate a graphical browser unless the user explicitly requests browser use in the current task.
- Check upstream issue and pull-request trackers before concluding that a public tool lacks a feature or recommending a custom workaround.
- When documentation is incomplete and source is available, inspect the relevant implementation, schema, types, examples, or tests. State what the evidence confirms and what remains uncertain.
- When adopting a tool with profiles, tiers, or optional integrations, verify that the selected surface exposes the commands and files the workflow needs.

## Tool Adoption

- Start with the smallest useful workflow that preserves the tool's core value. Keep optional automation, artifacts, and broad integrations off until repeated use justifies them.
- Before adding a wrapper, hook, repair script, or generated workaround, check for a native setting and an existing tracked config layer. Prefer a reversible, documented default path.
- Keep native commands working. Wrappers may bootstrap or narrow a workflow, but should not become the only source of required state.
- For tools that launch agents or generate agent prompts and commands, prefer agent-neutral contracts and config-driven selection. Document an intentionally single-agent scope.
- Keep a standalone tool's implementation, tests, skills, metadata, and installer or updater in its own repository. Dotfiles should contain only thin bootstrap, routing, or machine-specific integration.

## Ownership and Routing

- Generic personal preferences and reusable non-work Codex setup belong in the public base dotfiles repository. Private, host-specific, and workflow-specific policy belongs in later configuration layers.
- Keep always-loaded `AGENTS.md` guidance to durable routing, safety, and universal behavior. Put detailed task procedure and examples in the owning skill or deferred reference, and repository-specific procedure in that repository's instructions.
- For generated skills, use the managed index to locate the tracked source. Portable skills come from `home/.ruler/skills/`; Codex-native skills come from `home/.codex/skills/`.

## Workflow Skills

- Use `writing-style` before substantial drafting and `readme-maintainer` for README or repository landing-page work. Use `slack-clipboard` when approved Slack text needs rich-text clipboard copy or direct paste.
- For frontend work, use `react-patterns` for React, `typescript-style` for TypeScript or TSX, and `css-layout` for layout or styling. Do not apply this workflow to non-frontend tasks.
- Use `godspeed-tasks` for Godspeed inbox triage, task planning, and work or personal inbox organization.
- Use `nvim-config-coach` before substantial personal Neovim configuration, plugin selection, or keymap changes.
- Use `codex-config-coach` for Codex behavior, steering, context-cost, skill, plugin, MCP, hook, and dotty-chain configuration work. After repeated user correction around writing or implementation style, use it before finishing to decide whether a small durable steering update is warranted.
- Use `finish-session` when explicitly closing out a session to reconcile completion, config-coach improvements, durable plan or task follow-ups, and concrete context or token waste.
