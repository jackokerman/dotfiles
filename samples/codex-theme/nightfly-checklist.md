# Theme Checklist

Open these in Codex after restart/resume:

- `nightfly-demo.ts`
- `nightfly-demo.diff`
- `nightfly-real.diff`
- `diff-before.ts`
- `diff-after.ts`

What to check:

- The editor background should read as deep navy, not plain black.
- Functions should be bright blue.
- Class names should be green.
- Strings should be amber.
- In diffs, added and removed lines should be easy to distinguish, but the full-line background should not feel loud or fluorescent.

Interpretation:

- If `nightfly-demo.ts` looks right, the TextMate syntax theme is active.
- If `nightfly-real.diff` still has a strong green block background, Codex is probably applying its own diff UI colors on top of the syntax theme.
