---
name: typescript-style
description: Use for TypeScript or TSX work that needs guidance on API shape, function signatures, exported contracts, documentation, strict typing, and lint-safe escape hatches.
---

# TypeScript Style

Use this skill for generic TypeScript and TSX work. Keep React-specific rendering and hooks guidance in `react-patterns`, layout guidance in `css-layout`, and project-specific workflow guidance in the appropriate overlay skill when needed.

## Code Shape And Defaults

- Prefer plain functions and typed objects over classes unless the surrounding code already uses class-heavy patterns.
- Prefer small focused functions. Use guard clauses and early returns to flatten control flow instead of nesting conditionals when a branch can exit early.
- Prefer `const` by default and `let` only when reassignment is part of the logic.
- Prefer template literals over string concatenation when dynamic values are involved.

## API Shape And Types

- Prefer `type` over `interface` unless you need `extends`, declaration merging, or the surrounding code already relies on interfaces.
- Prefer named exports over default exports unless the local module pattern is already established.
- When an API has more than one or two related inputs, prefer a typed options object over a long positional parameter list.
- Keep shared types close to the module that owns them. Extract only when they are reused or part of a public contract.
- For helpers, accept the smallest structural type that expresses what they need. Do not require a full generated object or a broad union when a narrower object shape is enough.
- For React components, extract props into a named `FooProps` type instead of inlining a large object type in the component signature.

## Functions And Parameters

- Prefer named function declarations for exported functions and module-level helpers when the surrounding API allows it.
- When a function takes an object parameter, destructure it at the boundary when that makes the contract clearer. This applies to React props and typed options objects.
- Use inline defaults at the boundary when they clarify the contract more than a fallback chain in the body.

## Documentation

- Add JSDoc descriptions to exported functions, hooks, and types when they define a module contract or non-obvious behavior.
- When documenting functions or types, use JSDoc block comments (`/** ... */`) instead of line comments.
- Skip `@param` and `@returns` tags unless a specific tool requires them. The TypeScript signature already carries that information.
- Document nested object fields inline on the type when that is the clearest place to explain them.
- Focus documentation on exported and non-obvious code. Do not blanket-comment trivial local helpers.

## Type Safety And Escapes

- Do not use `any`. Exhaust `unknown`, generics, narrowing, overloads, or declaration files first. If you still believe `any` is necessary, surface that explicitly before adding it.
- Treat external or untrusted data as `unknown` at the boundary, then narrow it deliberately.
- For optional values, prefer explicit strict checks such as `=== undefined` or `!== undefined` over loose null checks.
- Prefer optional chaining and nullish coalescing when they make fallback logic clearer.
- If an inline `eslint-disable` is necessary, add a short comment explaining why the escape hatch is safe.
- If several nearby lines need the same rule disabled, prefer a single file-level disable with a clear explanation over repeated identical `eslint-disable-next-line` comments.
