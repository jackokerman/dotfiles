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
- In diffs, added and removed lines should have subtle Nightfly-tinted backgrounds rather than no background at all.
- Added lines should read teal-green, removed lines should read muted red, and changed regions should lean slate blue.

Interpretation:

- If `nightfly-demo.ts` looks right, the TextMate syntax theme is active.
- If `nightfly-real.diff` shows those subtle backgrounds, Codex is honoring the TextMate diff scopes as intended.
