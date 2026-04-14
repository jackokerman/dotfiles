# React Patterns

Use this reference for clearly React or frontend work. These are opinionated defaults, not laws. If the local codebase has a stronger documented pattern, follow it.

## Framing
- Prefer function components. Class components mostly remain for legacy code or error boundaries.
- Think in responsibilities, not smart vs dumb labels or a global containers architecture.
- Keep leaf components boring. Parents decide what to render; children render resolved props.
- Prefer composition over mode flags. If branches represent different shapes or workflows, split components.
- Keep components small enough that state, rendering, and event flow fit in one read.
- Name components and hooks by domain intent, not by implementation details.
- Prefer a consistent component shape within a codebase or module: naming, helper placement, and export style should not drift without a reason.

## Components
- Prefer named function declarations for exported components and hooks so stacks, devtools, and grep stay clear.
- Destructure props at the boundary. Use inline defaults for optional props when it improves readability; avoid `defaultProps` on function components.
- Treat high prop count as a design smell, not a quota. If several values form one domain concept, pass a typed object instead of a long primitive list.
- Do not hide unrelated values in a generic "options" bag just to make the prop list shorter.
- Move pure helpers outside components. Keep closures only when they truly need component state.
- If extracted markup needs its own branching, mapping, or state, make it a named component or hook instead of a nested render function.
- Prefer config-driven lists, navigation, and repeated UI over hardcoded repetitive markup.
- Keep list rendering inline only when displaying the list is the component's main job. Otherwise extract a list or item component.
- Use comments sparingly to explain domain rules or surprising UI branches, not obvious markup.
- Use targeted error boundaries around independently useful subtrees or unstable third-party widgets, not only at the app shell.

## Hooks And State
- Once a concern has related state, handlers, and effects, encapsulate it in a custom hook.
- Custom hooks should expose a small intentional API. Favor domain names over bags of unrelated primitives.
- Component bodies should read like wiring: get data, call domain hooks, render UI.
- Resolve defaults and fallback chains at the boundary instead of scattering them through the tree.
- Keep state minimal. Derive anything you can during render.
- Keep state close to where it is used. Lift it only when multiple consumers need the same source of truth.
- Use reducers when the behavior is driven by explicit transitions or many related events.
- Reach for external client-state libraries only when local state, context, and reducers stop modeling the problem cleanly.
- Use `useEffect` only for synchronization with systems outside React: subscriptions, timers, browser APIs, analytics, storage, URL state, network lifecycles, or third-party widgets.
- Do not use effects to mirror props into state, derive render data, or handle work that belongs in an event handler.
- Before adding an effect, check whether the logic belongs in render, a handler, a reducer, or a key-based reset.
- For new internal abstractions, prefer custom hooks over HOCs or render-prop wrappers unless the surrounding library already dictates the pattern.

## Context And Server State
- Use context for shared subtree state, not as a default answer to prop drilling.
- Scope providers as narrowly as possible.
- Export a provider and a `useX` hook. Callers should not touch the raw context object.
- Prefer no default context value. Throw a clear error when the hook is used outside its provider.
- Split contexts by responsibility or change frequency. Avoid omnibus app-wide context objects.
- Use a dedicated server-state solution when the app has real caching, invalidation, or request lifecycle needs.
- Prefer framework-native loaders or a library like TanStack Query over hand-rolled loading, retry, and cache state.
- Fetch data near the component that owns the responsibility for displaying or mutating it unless the framework has a stronger route-level pattern.

## Rendering And APIs
- Keep public APIs narrow. Fewer inputs usually mean fewer invalid states.
- Resolve impossible states at the boundary and let the rest of the tree trust the types.
- Avoid nested ternaries. Use early returns, named variables, or split components when conditional rendering stops being obvious.
- Avoid accidental `0` or empty-string rendering. When the left side of `&&` is not already boolean, coerce it or use a ternary.
- Prefer explicit state names and branches over squeezing multiple concerns into one expression.
- Prefer stable local adapters around third-party components when you want to normalize APIs, centralize styling, or keep swap cost low.

## Structure
- Group larger apps by route, feature, or domain rather than `components`, `containers`, and `utils` top-level buckets.
- Create shared UI or common modules only for true cross-cutting primitives. Do not dump feature-specific code into a vague shared folder.
- Prefer repo-supported absolute imports or path aliases for shared modules. Do not invent aliasing ad hoc.
- Start a component in a single file. Move it to its own folder once it owns tests, styles, or subcomponents.
- Keep styles close to the component, but follow the local styling system. Do not impose CSS-in-JS as a blanket rule.
- Component ownership of styles matters more than the specific styling tool.

## Performance
- Do not optimize prematurely. Measure before trading readability for speed.
- Bundle size and network work usually matter more than callback identity churn.
- Split code by route or feature when the platform supports it, and defer heavy rarely used code.
- Do not reach for `useMemo` or `useCallback` by default.
- Memoize only for measured expensive work, stable identity requirements, or an established local convention.
- If a fixed array or object is crossing a memoized boundary and causes measured churn, hoist or memoize it intentionally.
- Prefer simpler code over speculative rerender optimization.

## Testing
- Test behavior and user outcomes, not implementation details.
- Prefer a few meaningful tests over snapshot-heavy or mock-heavy coverage.
- Treat snapshots as a weak sanity check, not primary evidence that UI behavior is correct.
- Cover default rendering, state transitions, events, edge cases, and failure paths when behavior changes.
- Write integration tests for flows where the interaction between components is the real risk.
