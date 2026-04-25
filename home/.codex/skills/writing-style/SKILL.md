---
name: writing-style
description: Use for general writing tasks such as drafting or editing Slack messages, PR descriptions, Jira comments, review comments, status updates, or other prose where the user's personal writing style matters.
---

# Writing Style

Use this skill when drafting text on behalf of the user. Keep the substance intact and make the writing clearer, shorter, and more natural without sanding off intent or confidence level.

## Defaults

- Be informal but not too casual.
- Write complete sentences with subjects and verbs. Do not drop the subject for brevity.
- Be concise and direct, but do not compress text into fragments.
- Prefer conversational prose over heavy bulleting. Use lists only when the structure materially helps.
- Preserve the user's intended level of certainty. Do not overstate, soften, or pad claims unless the user asks.

## Technical Identifiers

- Wrap exact technical identifiers in backticks when the surface supports markdown. This includes file paths, commands, feature flags, package names, component names, hooks, functions, classes, and literal prop or field names.
- Do not treat issue or ticket IDs as code identifiers. When the surface supports hyperlinks, prefer semantic links like `[ABC-123: Short title](...)` or `[ABC-123](...)` over backticks.
- Skip backticks for generic concepts rather than exact identifiers, and skip them on plain-text surfaces such as commit subjects or PR titles.
- Use the full identifier instead of shorthand when precision matters.

## Formatting

- Prefer prose over bullet-heavy formatting by default.
- When the surface supports hyperlinks, prefer descriptive linked text inside the sentence instead of dropping naked URLs into the prose.
- Use a standalone link only when the link itself should be the focal artifact, such as a PR or doc the reader should open next.

## Tone

- Avoid validation-heavy filler.
- Avoid stiff corporate phrasing.
- In collaborative suggestions or review comments, prefer `we` over `you` when natural.
- Casual does not mean sloppy. Keep the writing readable and grammatical.

## Vocabulary And Punctuation

- Use `landed` for individual PRs or small changes. Reserve `shipped` for larger launches or product rollouts.
- Avoid em dashes and en dashes. Use commas, parentheses, or separate sentences instead.
- End list items with periods when they are complete sentences.

## Quick Examples

- Good: `I want to confirm that I'm not missing any requirements.`
- Bad: `Want to confirm not missing any requirements.`
- Good: `It looks like we'd benefit from a shared approach.`
- Bad: `Looks like we'd benefit from a shared approach.`
- Good: `We could drop the \`state\` property here.`
- Bad: `Could drop the \`state\` property here.`

## Final Check

- Does every sentence still have a clear subject and verb?
- Did I keep the user's actual meaning and level of certainty?
- Did I use backticks for technical identifiers where they help?
- Did I avoid em dashes, filler, and overcompression?
- Would this sound natural in Slack, a PR, a review comment, or a short status update?
