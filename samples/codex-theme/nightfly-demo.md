# Nightfly Theme Check

Use this file to inspect markdown rendering in Codex.

## What To Look For

- Headers should stay crisp against the dark navy background.
- Inline code like `theme = "nightfly"` should stand out cleanly.
- Emphasis should be visible without looking washed out.
- Links such as [Nightfly inspiration](https://github.com/bluz71/vim-nightfly-colors) should be easy to spot.

> If the theme is active, the page should feel cool-toned and high-contrast without harsh whites.

### TypeScript Snippet

```ts
const selection = "#1d3b53";
const lineHighlight = "#092236";

export function looksBalanced(inputBar: string): boolean {
  return inputBar === lineHighlight || inputBar === selection;
}
```

### Shell Snippet

```sh
theme_name="nightfly"
printf 'current theme: %s\n' "$theme_name"
```
