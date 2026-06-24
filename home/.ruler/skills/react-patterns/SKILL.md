---
name: react-patterns
description: Use when React or frontend work needs guidance on cleanup and simplification, component boundaries, hooks, context, rendering, testing, or modern React defaults.
---

# React Patterns

Use this skill for clearly React or frontend work, including cleanup or simplification passes that should make existing code smaller, clearer, and more idiomatic without changing behavior. These are opinionated defaults, not laws. Package-local docs, neighboring files, and stronger framework conventions win.

## Workflow

- Start by reading nearby components, hooks, tests, and package docs before applying generic guidance.
- Prefer the repo's established import style, component shape, naming, test style, and framework conventions over generic React advice.
- Keep changes focused on the current behavior. Do not add customization props, escape hatches, alternate flows, speculative abstractions, or broad rewrites unless a current caller needs them.
- Prefer refactors that reduce invalid states, branching, and incidental complexity over clever abstractions.
- Name components, hooks, and helpers by domain intent. Prefer short, direct names and avoid vague qualifiers such as `effective`, `resolved`, `computed`, and `final` unless they mark a real distinction.
- Keep the code shape consistent inside a module. Do not mix unrelated styles without a reason.
- When implementation details matter, load `references/react-defaults.md` and apply only the sections relevant to the change.

## Loaded Defaults

- Components: prefer function components, narrow typed props, composition over mode flags, boring leaf components, and extraction by responsibility rather than line count.
- Hooks: extract a custom hook when related state, external hooks, derived values, handlers, refs, or effects form one concern; keep the hook API intentional and colocated until reuse or boundaries justify promotion.
- State: keep state minimal and close to its owner, derive during render when possible, lift only for shared ownership, and pass intentful handlers instead of raw setters by default.
- Effects: use `useEffect` only for synchronization with systems outside React. Do not mirror props into state or derive render data in an effect.
- Context: use context for shared subtree state, not as the default answer to prop drilling. Scope providers narrowly and expose a provider plus a `useX` hook.
- Rendering: prefer early returns, named helpers/components, and boolean-safe conditionals. Avoid nested ternaries, large JSX variables, JSX-valued render helpers for substantial subtrees, and large derivation blocks above `return`.
- Performance: measure before trading readability for speed. Reach for memoization or concurrent APIs only for measured expensive work, stable identity requirements, responsiveness, or established local convention.
- Testing: test behavior and user outcomes. Prefer meaningful assertions and async queries such as `findBy*` over snapshots, implementation details, or broad `waitFor` blocks.

## Reference Use

Load `references/react-defaults.md` when:

- Refactoring component boundaries, hook extraction, context, effects, rendering structure, or React tests.
- Reviewing React code for cleanup opportunities or risk.
- Choosing between React patterns where the compact defaults above are not enough.
- Writing or explaining examples.

Do not load the reference for tiny naming, import-style, or direct-answer tasks where nearby code already decides the outcome.
