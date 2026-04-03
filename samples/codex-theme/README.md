# Codex Nightfly Samples

Open these files in Codex to check whether the `nightfly` theme is active and balanced:

- `nightfly-demo.ts` exercises comments, keywords, class names, functions, numbers, strings, template literals, regexes, and punctuation.
- `nightfly-demo.md` shows markdown headings, emphasis, lists, blockquotes, inline code, and fenced code blocks.
- `nightfly-demo.json` makes it easy to inspect string, number, boolean, and `null` colors.
- `nightfly-demo.sh` gives you shell comments, variables, strings, conditionals, and command substitutions.
- `nightfly-demo.diff` is the direct check for added/removed hunk coloring and whether Codex is tinting the full line background.
- `nightfly-real.diff` is generated from `diff-before.ts` and `diff-after.ts`, so it uses a literal unified diff instead of handwritten sample text.
- `nightfly-checklist.md` is the quick inspection sheet after restart/resume.

If the theme is loaded correctly, the overall background should stay deep navy, functions should read bright blue, classes should read green, strings should read warm amber, and keywords/operators should lean violet.

For diffs, this theme follows the upstream Vim Nightfly repo rather than the local VS Code experiment. Added lines use `#2a4e57` with Nightfly green text, removed lines use `#4e3030` with Nightfly red text from the upstream `nightfly-opencode` extra, and changed regions use the core Vim Nightfly blue family with a `#2c3043` background and `#87bcff` text.
