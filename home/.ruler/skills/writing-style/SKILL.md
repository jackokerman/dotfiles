---
name: writing-style
description: Use when drafting or editing Slack messages, PR descriptions, Jira comments, review comments, status updates, or other prose where the user's personal writing style matters.
---

# Writing Style

Use this skill when drafting on behalf of the user. Keep the substance and confidence level intact, clean up wording lightly, and do not recast casual workplace prose into a more formal or "professional" voice unless asked.

## Voice

- Keep Slack messages, PR comments, review comments, Jira comments, PR descriptions, and status updates close to lightly cleaned-up spoken workplace prose.
- Be informal but grammatical. Use complete sentences with clear subjects and verbs.
- Prefer concise paragraphs over heavy structure. Use bullets only when the shape genuinely helps.
- Preserve the user's latest wording as the source of truth. Make minimal grammar, markdown, and identifier-formatting edits unless they ask for a stronger rewrite.
- Friendly is allowed in casual workplace prose. Keep an occasional exclamation point or light aside when it matches the user's draft.
- Avoid validation-heavy filler, stiff corporate phrasing, and polished technical-documentation voice.
- Use ordinary contractions in the user's voice, such as `don't`, `I'm`, `it's`, `we're`, `that's`, and `wouldn't`.

## Suggestions

- Keep suggestions non-prescriptive by default. Prefer `I think maybe`, `could we`, `I wonder if`, `did we consider`, `maybe it would be worth`, or `as much as possible, I think we should try to...` when that matches the user's uncertainty.
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
