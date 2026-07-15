---
name: writing-style
description: Use when drafting or editing Slack messages, PR descriptions, Jira comments, review comments, status updates, or other prose where the user's personal writing style matters.
---

# Writing Style

Use this skill when drafting text on behalf of the user. Keep the substance intact and make the writing clearer, shorter, and more natural without sanding off intent or confidence level.

## Defaults

- Be informal but not too casual.
- Write complete sentences with subjects and verbs. Do not drop the subject for brevity.
- Be concise and direct, but do not compress text into fragments.
- Prefer conversational prose over heavy bulleting. Use lists only when the structure materially helps.
- Preserve the user's intended level of certainty. Do not overstate, soften, or pad claims unless the user asks.
- When the user iterates aloud on phrasing, treat their latest wording as the source of truth. Return one lightly cleaned-up version, and avoid adding new labels, framing, or structure unless they asked for it.

## Workplace Prose Voice

- For Slack messages, PR descriptions, PR comments, Jira comments, review comments, and review requests, keep the final draft close to lightly cleaned-up spoken workplace prose.
- Prefer personal, first-person phrasing when the user is speaking for themselves, such as `I don't love this`, `from what I can tell`, and `I'd be happy to be proven wrong`.
- Do not make PR comments or Slack messages sound like polished technical documentation unless the user asks for that tone.
- Avoid phrases the user has rejected, such as `sanity check` or `re-land`, unless the user provides them.
- When deeper style calibration is needed, collect approved examples and rejected rewrites before adding more durable rules. Do not infer a broad voice model from one draft alone.

## Technical Identifiers

- Wrap exact technical identifiers in backticks when the surface supports markdown. This includes file paths, commands, feature flags, package names, component names, hooks, functions, classes, exact operators such as `??`, and literal prop or field names.
- Do not treat issue or ticket IDs as code identifiers. When the surface supports hyperlinks, prefer semantic linked text such as the ticket ID plus short title over backticks.
- Skip backticks for generic concepts rather than exact identifiers, and skip them on plain-text surfaces such as commit messages. PR titles support markdown, so use backticks there too when they improve precision.
- Use the full identifier instead of shorthand when precision matters.

## Formatting

- Prefer prose over bullet-heavy formatting by default.
- When the surface supports hyperlinks, prefer descriptive linked text inside the sentence instead of dropping naked URLs into the prose.
- When drafting for a markdown-capable surface and mentioning a Slack channel, link the channel name if the channel URL is known or can be cheaply verified. Use plain `#channel-name` only when the URL is unknown or the target surface does not support links.
- Use a standalone link only when the link itself should be the focal artifact, such as a PR or doc the reader should open next.
- For Google Docs or rich-text document surfaces created through markdown/import tools, prefer flat bullets and subheaders over nested bullet lists; rich-text importers can mangle indentation. Use subheaders for link/pointer groups, and avoid repeated bold lead-in labels at the start of every bullet unless the user explicitly asks for that structure.
- For shared or public-facing audiences, avoid mentioning private notes, local trackers, workflow artifacts, or internal process details unless the reader has that context or the user asks to include it.
- For technical decision-request messages, lead with the concrete decision needed, then add only the context needed to answer it. When helpful, link exact PRs, files, symbols, or source lines, and offer compact options such as "A, B, or something else" instead of ending with several open-ended questions.

## Status Updates

- Include the work, artifacts, decisions, blockers, and next steps that the audience can use. Omit meta-process, tooling, or automation details unless the audience needs to act on them.

## Tone

- Avoid validation-heavy filler.
- Avoid stiff corporate phrasing.
- Use ordinary contractions in the user's voice, especially for Slack messages, comments, and conversational drafts. Prefer `don't`, `I'm`, `it's`, `we're`, `that's`, and `wouldn't` over expanded forms unless the surface is formal, legal, or needs extra clarity.
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
- Did I use natural contractions where the user would use them?
- Did I use backticks for technical identifiers where they help?
- Did I avoid em dashes, filler, and overcompression?
- Would this sound natural in Slack, a PR, a review comment, or a short status update?
