---
name: writing-style
description: Use when drafting or editing Slack messages, PR descriptions, Jira comments, review comments, status updates, or other prose where the user's personal writing style matters.
---

# Writing Style

Use this skill when drafting on behalf of the user. Keep the substance and confidence level intact, clean up wording lightly, and do not recast casual workplace prose into a more formal or "professional" voice unless asked.

## Voice

- Keep Slack messages, PR comments, review comments, Jira comments, PR descriptions, and status updates close to lightly cleaned-up spoken workplace prose.
- Be informal but grammatical. Keep sentences simple and spoken instead of polishing them into formal workplace prose.
- Preserve the user's latest wording as the source of truth. Make minimal grammar, markdown, and identifier-formatting edits unless they ask for a stronger rewrite.
- When the user provides rough wording, line-edit it instead of replacing it with a cleaner draft. Preserve its sentence shape and casual phrasing when they remain understandable.
- Default to friendly, relaxed workplace language. Keep an occasional exclamation point, conversational opener, or light aside when it matches the user's draft.
- Prefer ordinary words and direct verbs. Skip formal connective phrases when a shorter transition, or no transition, works.
- Avoid validation-heavy filler, stiff corporate phrasing, and polished technical-documentation voice.
- Use ordinary contractions in the user's voice, such as `don't`, `I'm`, `it's`, `we're`, `that's`, and `wouldn't`.

## Structure

- Match the structure to how the reader will use the text. Keep conversational messages light, but optimize runbooks, handoffs, plans, and operational docs for scanning.
- Use ordered lists for compact sequences and bullets for flat sets of options, criteria, checklist items, mappings, or parallel facts. Avoid nesting ordered and unordered lists when the rendered output matters.
- Write bullets as independent items. Use periods for complete sentences and no punctuation for short fragments. Avoid semicolon-linked lists and a terminal `and`.
- When workflow steps need commands, explanations, or their own checklists, prefer short parallel subheadings such as `Step 1: Start the migration` and keep any bullets under them flat.
- Do not force a list around one idea. Keep introductory and closing prose short around structured content.

## Suggestions

- Keep suggestions non-prescriptive by default. Prefer `I think maybe`, `could we`, `I wonder if`, `did we consider`, `maybe it would be worth`, or `as much as possible, I think we should try to...` when that matches the user's uncertainty.
- Do not turn a callout or observation into a request. If the user only wants to flag context, do not add an action, owner, remedy, question, or invitation to pick up the work.
- Avoid stronger phrasing like `I'd prefer`, `we should`, or `we need to` unless the user clearly wants firmness.
- In collaborative suggestions, prefer `we` over `you` when natural.
- Preserve uncertainty. Do not overstate, soften, or pad claims unless the user asks.

## Markdown And Identifiers

- Wrap exact technical identifiers in backticks on markdown-capable surfaces: files, paths, commands, env vars, packages, components, hooks, functions, flags, exact operators like `??`, and literal prop or field names.
- Do not backtick generic concepts, plain issue IDs, or plain-text surfaces such as commit messages.
- Prefer descriptive links over naked URLs when the surface supports markdown.
- Avoid artificial hard line breaks in prose.

## Vocabulary

- Use `landed` for individual PRs or small changes. Reserve `shipped` for larger launches.
- Avoid phrases the user has rejected, such as `sanity check` or `re-land`, unless the user provides them.
- Avoid em dashes and en dashes. Use commas, parentheses, or separate sentences instead.

## Final Pass

Before returning a draft, check that it still sounds like the user, keeps their certainty level, uses natural contractions, and avoids turning a casual note into a formal memo.
