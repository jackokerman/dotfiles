---
name: typescript-style
description: Use for TypeScript or TSX work that needs guidance on API shape, function signatures, exports, strict typing, and lint-safe escape hatches.
---

# TypeScript Style

Use this skill for generic TypeScript and TSX work. Keep React-specific rendering and hooks guidance in `react-patterns`, layout guidance in `css-layout`, and project-specific workflow guidance in the appropriate overlay skill when needed.

## API Shape And Types

- Prefer `type` over `interface` unless you need `extends`, declaration merging, or the surrounding code already relies on interfaces.
- Prefer named exports over default exports unless the local module pattern is already established.
- When an API has several related inputs, prefer a typed options object over a long positional parameter list.
- Keep shared types close to the module that owns them. Extract only when they are reused or part of a public contract.

## Functions And Parameters

- Prefer named function declarations for exported functions and module-level helpers when the surrounding API allows it.
- When a function takes an object parameter, destructure it at the boundary when that makes the contract clearer. This applies to React props and typed options objects.
- Use inline defaults at the boundary when they clarify the contract more than a fallback chain in the body.

## Type Safety And Escapes

- Do not use `any`. Exhaust `unknown`, generics, narrowing, overloads, or declaration files first. If you still believe `any` is necessary, surface that explicitly before adding it.
- Treat external or untrusted data as `unknown` at the boundary, then narrow it deliberately.
- For optional values, prefer explicit strict checks such as `=== undefined` or `!== undefined` over loose null checks.
- If an inline `eslint-disable` is necessary, add a short comment explaining why the escape hatch is safe.
