# React Defaults

Detailed React defaults for `react-patterns`. Apply only the sections relevant to the current change. Nearby code, package docs, and framework conventions still win.

## Components And APIs

- Prefer function components and named function declarations for exported components and hooks.
- Destructure props in the signature when that keeps the boundary clear. Put boundary defaults there too; avoid `defaultProps` on function components.
- Treat high prop count as a design smell. Pass a typed domain object when values travel together, but do not hide unrelated values in a generic options bag.
- Keep leaf components boring and usually stateless. Parents choose what to render; children render resolved props and emit events.
- Prefer composition over mode flags or internal branching. Split components when branches represent different workflows, shapes, or responsibilities.
- Move pure helpers outside the component. If extracted markup grows branches, mapping, or state, make it a capitalized component or a hook instead of a `getFoo()` render helper.
- Use configuration data for repeated navigation, filters, menus, tabs, or other near-identical UI.
- Extract repeated JSX or complex list rendering into a named component when it clarifies structure. Do not add wrappers that only rename markup.
- Keep public APIs narrow. Resolve impossible states at the boundary and let the rest of the tree trust the types.

## Hooks, State, And Encapsulation

- Extract a custom hook when one concern owns related state, external hooks, derived values, handlers, refs, or effects.
- Single-use hooks are valid when they keep a component focused. Prefer a colocated `useX` hook before promoting shared code.
- Custom hooks should expose the operations the UI needs, not an implementation dump.
- Prefer plain helper functions for pure branching or data shaping. Use hooks when the extraction composes hooks, state, refs, or effects.
- Component bodies should read like orchestration: get data, call domain hooks, render UI.
- Resolve defaults and fallback chains at the boundary instead of scattering them through the tree.
- Keep state minimal and close to where it is used. Derive during render when possible, and lift only when multiple consumers need one source of truth.
- Pass intentful handlers such as `onClose`, `onSave`, or `onToggle` instead of raw state setters by default.
- Let the nearest responsible component own validation, mutation flow, and form orchestration. Leaf primitives should stay dumb.
- Use reducers for explicit transitions or many related events. Reach for external client-state libraries only when local state, context, and reducers no longer model the problem cleanly.

## Effects And Synchronization

- Use `useEffect` only for synchronization with systems outside React: subscriptions, timers, browser APIs, analytics, storage, URL state, network lifecycles, or third-party widgets.
- Never use `useEffect` to derive state or render data. Before adding an effect, check whether the logic belongs in render, a handler, a reducer, or a key-based reset.
- For subscriptions with a current snapshot, prefer `useSyncExternalStore` over an effect plus mirrored local state.
- Do not copy props or memoized values into state. Derive during render, reset with a `key`, update in the source-changing handler, or use React's guarded previous-render state pattern only when previous input is truly needed.
- Use `useLayoutEffect` only for imperative DOM, measurement, focus, or widget updates that must happen before paint.
- Keep `requestAnimationFrame` effects for work that intentionally waits for a paint or library commit.
- Prefer custom hooks over HOCs or render props for new internal abstractions unless a surrounding library dictates otherwise.

## Context And Shared State

- Use context for shared subtree state, not as the default answer to prop drilling. Scope providers narrowly.
- Export a provider and a `useX` hook. Callers should not touch the raw context object.
- Prefer no default context value. Throw a clear error when the hook is used outside its provider, or use a project helper that does this.
- Split contexts by responsibility or change frequency. Avoid omnibus app-wide context objects.
- Keep server state out of bespoke context when the real need is caching, invalidation, or request lifecycle management. Prefer framework loaders or a dedicated server-state library.
- Fetch data near the component that owns displaying or mutating it unless the framework has a stronger route-level pattern.

## Rendering And Structure

- Prefer early returns to nested ternaries. Never nest ternaries in JSX.
- Avoid accidental `0` or empty-string rendering. Coerce non-boolean `&&` conditions or use a ternary.
- Do not keep large conditional, derivation, or JSX blocks above `return`. Simplify them or extract a helper, hook, or component.
- When content needs an optional shell, prefer a small wrapper component with `children` over duplicating the subtree or assigning JSX to a local value.
- Use JSX comments only for non-obvious product, domain, or accessibility constraints.
- In component files, put the main exported component first, then local hooks and helpers in top-down order.
- Use error boundaries at route or independently useful widget boundaries. Do not wrap every component mechanically.
- Use stable local adapters around third-party components to normalize APIs, centralize styling, or keep swap cost low.
- Group larger apps by route, feature, or domain rather than generic `components`, `containers`, and `utils` buckets.
- Create shared UI or common modules only for true cross-cutting primitives. Start a component in one file; move it to a folder once it owns tests, styles, or subcomponents.

## Performance

- Do not optimize prematurely. Measure before trading readability for speed.
- Bundle size and network work usually matter more than callback identity churn.
- Do not reach for `useMemo` or `useCallback` by default. Memoize only for measured expensive work, stable identity requirements, or established local convention.
- Use `useEffectEvent`, `startTransition`, and `useDeferredValue` to simplify code or preserve responsiveness, not as decorative optimization.

## Testing

- Test behavior and user outcomes, not implementation details.
- Prefer meaningful assertions over snapshots, broad mocks, or coverage that only preserves markup shape.
- Cover default rendering, state transitions, events, edge cases, and failure paths when behavior changes.
- Write integration tests when component interaction is the real risk.
- For async DOM appearance, prefer `findBy*` queries. When `waitFor` is needed, wait for one concrete assertion; do not use empty callbacks or bundle multiple assertions.
