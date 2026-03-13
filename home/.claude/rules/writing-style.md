# Writing style

## Technical terms

Wrap technical identifiers in backticks for clarity. Always use the full identifier, never abbreviate or use informal shorthand (e.g., write `MY_APP_SKIP_COMPINIT`, not "SKIP_COMPINIT"):
- Feature flag names: `enable_dark_mode`
- File paths: `src/config/features.yaml`
- Function/class names: `ConfigParser`
- CLI commands: `npm run deploy`

Examples:
- Good: "Add `enable_dark_mode` feature flag"
- Bad: "Add enable_dark_mode feature flag"

## Formatting

Prefer conversational prose over heavy list/dash formatting. Write naturally and use formatting sparingly, only when it genuinely aids clarity (like code blocks for code examples).

Use proper markdown headings for sections. Never use bold text as a pseudo-heading (e.g., `**Step 1:**` should be `#### Step 1:`). When lists are necessary, don't bold the first phrase as a label or header.

## Tone

Be informal but not too casual. Avoid stiff or overly formal phrasing, but don't sacrifice clarity for brevity.

## Sentence structure

Write complete sentences with subjects and verbs. The tone can be informal, but don't omit grammatical subjects, even in casual drafting like PR descriptions, Slack messages, PR review comments, or short status updates. When making suggestions (e.g., in PR reviews), prefer "we" over "you" for a more collaborative tone.

- Good: "The service failed to connect. It retried three times before timing out."
- Bad: "Failed to connect. Retried three times before timing out."
- Good: "I'm curious what everyone else has been doing."
- Bad: "Curious what everyone else has been doing."
- Good: "It feels like we'd benefit from a shared approach."
- Bad: "Feels like we'd benefit from a shared approach."
- Good: "We could drop the `state` property here."
- Bad: "Could drop the `state` property here."
- Good: "It looks like there are some merge conflicts."
- Bad: "Looks like there are some merge conflicts."
- Good: "I left a couple of comments below."
- Bad: "Left a couple of comments below."
- Good: "I found your past review comment."
- Bad: "Found your past review comment."

## Vocabulary

Use "landed" for individual PRs or small changes. Reserve "shipped" for larger features or launches.

## Punctuation

Avoid em dashes and en dashes. Use commas, parentheses, or separate sentences instead.

- Good: "Addressed your comments and responded to questions"
- Bad: "Addressed your comments - responded to questions"

End list items with periods when they are complete sentences.
