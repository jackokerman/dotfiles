---
name: typescript-style
description: Style guide for writing TypeScript and TSX code. Invoke when creating or editing .ts, .tsx, .mts, .cts files.
user-invocable: false
---

# TypeScript style

## General principles
- Prefer functional patterns over classes
- Use early returns to reduce nesting
- Keep functions small and focused

## Functions
- Prefer function declarations over function expressions (`function foo()` over `const foo = ()`)
  - Declarations are hoisted, allowing main components at top with helpers below
  - Exception: use arrow functions when returning functions from hooks or factories
  ```typescript
  // Preferred - arrow function for returned callback
  function useObjectCreator() {
    return useCallback(
      (options: CreateOptions) => {
        // ...
      },
      [deps]
    );
  }

  // Also fine - arrow for inline return values
  function createHandler(config: Config) {
    return (event: Event) => handleEvent(event, config);
  }
  ```
- Destructure object parameters in the function signature (not in the body)
  - Applies to React component props and any function taking an options object
  ```typescript
  // Preferred - destructure in signature
  function UserCard({ name, email, avatar }: UserCardProps) { ... }
  function fetchData({ url, retries }: FetchOptions) { ... }

  // Avoid - destructure in body
  function UserCard(props: UserCardProps) {
    const { name, email, avatar } = props;
    ...
  }
  ```
- Extract React component props into a named type (e.g., `FooProps`) rather than inlining them in the function signature. Keeps signatures readable and makes the type reusable and documentable with JSDoc.
- Prefer object parameters over positional arguments when there are more than 1-2 params
  - Makes adding optional parameters easy without updating all call sites
  - Pairs well with typed objects that have JSDoc descriptions
  ```typescript
  // Preferred - easy to extend, self-documenting at call site
  function createWidget({ id, label, category }: CreateWidgetOptions) { ... }
  createWidget({ id: "w_123", label: "Sprocket", category: "tools" })

  // Avoid for 3+ params - hard to extend, unclear at call site
  function createWidget(id: string, label: string, category: string) { ... }
  ```

## Syntax preferences
- Use `const` by default, `let` only when reassignment is needed
- Prefer named exports over default exports
- Use template literals over string concatenation
- Prefer optional chaining (`?.`) and nullish coalescing (`??`)
- Use strict equality (`!== undefined`) instead of loose null checks (`!= null`) for optional fields
- Always use braces for conditional bodies, even single-line ones

## CSS-in-JS
- Write styles inline on the element. Don't extract single-use CSS into module-level constants.
- When styles need to be shared across elements, prefer the framework's compositional APIs (e.g., Sail's `createView` with variants, `createViewConfig`) over standalone `css()` constants.

## Type safety
- Enable TypeScript strict mode
- Prefer `type` over `interface` unless the type is used for inheritance (e.g., `extends`)
- Prefer type inference where obvious, explicit types for function signatures

### The `any` type is forbidden

Never use `any`. This is a hard rule, not a suggestion.

**Before writing `any` in any context, you MUST stop and ask the user.** Do not proceed with implementation, commits, or PRs that include `any`. Instead:

1. Explain why you believe `any` might be necessary
2. Show what alternatives you considered (`unknown`, generics, type narrowing, conditional types)
3. Wait for explicit approval before proceeding

Common situations where `any` seems tempting but isn't needed:
- External API responses → use `unknown` and validate/narrow
- Generic containers → use proper generics with constraints
- Complex unions → use discriminated unions or branded types
- Third-party libs without types → write declaration files or use `@types/*`
- Callback parameters → use proper function signatures with generics

## ESLint disable comments
- When disabling an ESLint rule inline, always include a comment explaining why the disable is necessary and why it's safe. The explanation should help a reviewer understand the decision without needing to look up the rule.
  ```typescript
  // structuredClone is available in all supported runtimes (Node 17+,
  // modern browsers) but the lib typings lag behind.
  // eslint-disable-next-line @typescript-eslint/no-unsafe-call
  const copy = structuredClone(original);
  ```

## JSDoc comments
- Add JSDoc descriptions to exported functions and types
- When describing any function (including file-local helpers), use JSDoc format (`/** ... */`) rather than `//` line comments
- Skip `@param` and `@returns` tags - TypeScript types handle that
- Prefer multi-line format for readability:
  ```typescript
  /**
   * Fetches widget data and normalizes it for display.
   *
   * widgetId -
   *   The unique identifier, supports both UUID and legacy numeric IDs.
   *
   * options.includeArchived -
   *   Set true for admin views that show archived items.
   */
  export function fetchWidget(widgetId: string, options: FetchOptions): Promise<Widget>
  ```
- Add descriptions to type definitions; document nested fields inline:
  ```typescript
  /**
   * Configuration for the widget processing pipeline.
   */
  type WidgetConfig = {
    /**
     * Base URL for the widget service.
     * Use localhost in development.
     */
    baseUrl: string;
    /**
     * Retry attempts before failing.
     * Defaults to 3.
     */
    maxRetries?: number;
  }
  ```
- Focus documentation on exported items; internal code only if complex

## File organization
- Start implementing in a single file; don't preemptively create files
- Extract only when: file gets too large, or code needs reuse elsewhere
- Avoid hasty abstractions - duplication is cheaper than wrong abstraction

## Naming
- camelCase for variables and functions
- PascalCase for types and classes
- SCREAMING_SNAKE_CASE for constants

## Error handling
- Prefer explicit error handling over try/catch where possible
- Use Result/Either patterns for expected failures
- Reserve exceptions for unexpected errors
