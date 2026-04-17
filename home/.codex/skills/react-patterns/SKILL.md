---
name: react-patterns
description: Use for React or frontend work that needs guidance on component boundaries, hooks, context, rendering, testing, and modern React defaults.
---

# React Patterns

Use this skill for clearly React or frontend work. These are opinionated defaults, not laws. Package-local docs, neighboring files, and stronger framework conventions win.

## Workflow

- Start by reading nearby components, hooks, tests, and package docs before applying generic guidance.
- Prefer refactors that reduce invalid states, branching, and incidental complexity over clever abstractions.
- Name components, hooks, and helpers by domain intent. Prefer short, direct names and avoid `effective`, `resolved`, `computed`, and `final` unless they mark a real distinction.
- Keep the code shape consistent inside a module. Do not mix unrelated styles without a reason.

## Components And APIs

- Prefer function components and named function declarations for exported components and hooks.
- Treat high prop count as a design smell. Pass one typed domain object when several values travel together, but do not hide unrelated values in a generic options bag.
- Keep leaf components boring. Parents decide what to render; children render resolved props.
- Prefer composition over mode flags or internal branching. If branches represent different workflows or shapes, split components.
- Move pure helpers outside the component. If extracted markup grows its own branches, mapping, or state, make it a named component or hook.
- Extract repeated JSX into a named component when it clarifies structure, but do not add wrappers that only rename markup.
- Keep public APIs narrow. Resolve impossible states at the boundary and let the rest of the tree trust the types instead of adding defensive handling deeper in the tree.

## Hooks, State, And Encapsulation

- Once a concern has related state, handlers, derived values, and effects, encapsulate it in a custom hook.
- A concern does not need local state to justify a hook. If a component gathers related external hooks, derived values, and handlers for one responsibility, extract a small local hook when that makes the component read more like orchestration.
- Custom hooks should expose a small intentional API. Return the operations the UI needs, not an implementation dump.
- Prefer plain helper functions for pure branching or data-shaping logic. Reach for a custom hook when the extraction composes hooks, state, refs, or effects.
- Component bodies should read like orchestration: get data, call domain hooks, render UI.
- Resolve defaults and fallback chains at the boundary instead of scattering them through the tree.
- Keep state minimal. Derive what you can during render.
- Keep state close to where it is used. Lift it only when multiple consumers need the same source of truth.
- Use reducers when behavior is driven by explicit transitions or many related events.
- Reach for external client-state libraries only when local state, context, and reducers no longer model the problem cleanly.
- Treat encapsulation as a readability tool. Do not hide domain logic so aggressively that testing and reasoning get harder.

## Effects And Synchronization

- Use `useEffect` only for synchronization with systems outside React: subscriptions, timers, browser APIs, analytics, storage, URL state, network lifecycles, or third-party widgets.
- Never use `useEffect` to derive state or render data. Do not mirror props into state or handle work in an effect that belongs in render or an event handler.
- Before adding an effect, check whether the logic belongs in render, a handler, a reducer, or a key-based reset.
- For new internal abstractions, prefer custom hooks over HOCs or render-prop wrappers unless the surrounding library already dictates the pattern.

## Context And Shared State

- Use context for shared subtree state, not as the default answer to prop drilling.
- Scope providers as narrowly as possible.
- Export a provider and a `useX` hook. Callers should not touch the raw context object.
- Prefer no default context value. Throw a clear error when the hook is used outside its provider.
- Split contexts by responsibility or change frequency. Avoid omnibus app-wide context objects.
- Keep server state out of bespoke context when the real need is caching, invalidation, or request lifecycle management. Prefer framework loaders or a dedicated server-state library.
- Fetch data near the component that owns the responsibility for displaying or mutating it unless the framework has a stronger route-level pattern.

```tsx
const SessionContext = createContext<SessionContextValue | undefined>(undefined)

export function useSession() {
  const value = useContext(SessionContext)
  if (value === undefined) {
    throw new Error('useSession must be used within SessionProvider')
  }
  return value
}
```

## Rendering And Structure

- Prefer early returns to nested ternaries. Never nest ternaries in JSX.
- Avoid accidental `0` or empty-string rendering. When the left side of `&&` is not already boolean, coerce it or use a ternary.
- Do not keep large conditional or derivation blocks above `return`. Simplify them or extract a pure helper, local hook, or component.
- Do not park large JSX fragments in `const content = ...` style variables. Use early returns, a helper, or a named component instead.
- In component files, prefer the main exported component before hoisted helper functions.
- Below the main component, prefer top-down ordering from higher-level local hooks to the lower-level helpers they call.
- Prefer stable local adapters around third-party components when you want to normalize APIs, centralize styling, or keep swap cost low.
- Group larger apps by route, feature, or domain rather than `components`, `containers`, and `utils` buckets.
- Create shared UI or common modules only for true cross-cutting primitives.
- Start a component in a single file. Move it to its own folder once it owns tests, styles, or subcomponents.

## Performance

- Do not optimize prematurely. Measure before trading readability for speed.
- Bundle size and network work usually matter more than callback identity churn.
- Do not reach for `useMemo` or `useCallback` by default.
- Memoize only for measured expensive work, stable identity requirements, or an established local convention.
- Use `useEffectEvent` when an effect needs the latest callback or values without forcing resubscription on every render.
- Use `startTransition` for non-urgent updates that should not block input responsiveness.
- Use `useDeferredValue` when expensive derived rendering should lag behind fast-changing input.
- Use modern React performance APIs to simplify code and preserve responsiveness, not as decorative optimization.

## Testing

- Test behavior and user outcomes, not implementation details.
- Prefer a few meaningful tests over snapshot-heavy or mock-heavy coverage.
- Cover default rendering, state transitions, events, edge cases, and failure paths when behavior changes.
- Write integration tests for flows where the interaction between components is the real risk.
