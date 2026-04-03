# Codex Nightfly Samples

Open these files in Codex to check whether the `nightfly` theme is active and balanced:

- `nightfly-demo.ts` exercises comments, keywords, class names, functions, numbers, strings, template literals, regexes, and punctuation.
- `nightfly-demo.md` shows markdown headings, emphasis, lists, blockquotes, inline code, and fenced code blocks.
- `nightfly-demo.json` makes it easy to inspect string, number, boolean, and `null` colors.
- `nightfly-demo.sh` gives you shell comments, variables, strings, conditionals, and command substitutions.
- `nightfly-demo.diff` is the direct check for added/removed hunk coloring and whether Codex is tinting the full line background.

If the theme is loaded correctly, the overall background should stay deep navy, functions should read bright blue, classes should read green, strings should read warm amber, and keywords/operators should lean violet.

For diffs, this theme now explicitly sets `markup.inserted` and `markup.deleted` backgrounds to the base Nightfly background. If added or removed lines still show a tinted block background in Codex, that tint is likely coming from Codex's diff UI rather than the TextMate file.
