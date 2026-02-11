# TypeScript Style

## General Principles
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

## Syntax Preferences
- Use `const` by default, `let` only when reassignment is needed
- Prefer named exports over default exports
- Use template literals over string concatenation
- Prefer optional chaining (`?.`) and nullish coalescing (`??`)

## Type Safety
- Enable TypeScript strict mode
- Never use `any` - it defeats the purpose of TypeScript. Use `unknown` and narrow the type
- Prefer `type` over `interface`
- Prefer type inference where obvious, explicit types for function signatures

## JSDoc Comments
- Add JSDoc descriptions to exported functions and types
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

## File Organization
- Start implementing in a single file; don't preemptively create files
- Extract only when: file gets too large, or code needs reuse elsewhere
- Avoid hasty abstractions - duplication is cheaper than wrong abstraction

## Naming
- camelCase for variables and functions
- PascalCase for types and classes
- SCREAMING_SNAKE_CASE for constants

## Error Handling
- Prefer explicit error handling over try/catch where possible
- Use Result/Either patterns for expected failures
- Reserve exceptions for unexpected errors
