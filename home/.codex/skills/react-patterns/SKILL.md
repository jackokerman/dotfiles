---
name: react-patterns
description: Use for React or frontend work that needs guidance on component boundaries, hooks, context, rendering, testing, and modern React defaults.
---

# React Patterns

Use this skill for clearly React or frontend work. These are opinionated defaults, not laws. Package-local docs, neighboring files, and stronger framework conventions win.

## Workflow

- Start by reading nearby components, hooks, tests, and package docs before applying generic guidance.
- Prefer refactors that reduce invalid states, branching, and incidental complexity over clever abstractions.
- Name components, hooks, and helpers by domain intent rather than implementation details.
- Keep the code shape consistent inside a module. Do not mix unrelated styles without a reason.

## Components And APIs

- Prefer function components and named function declarations for exported components and hooks.
- Destructure props at the boundary. Use inline defaults when they clarify the contract.
- Treat high prop count as a design smell. Pass one typed domain object when several values travel together, but do not hide unrelated values in a generic options bag.
- Keep leaf components boring. Parents decide what to render; children render resolved props.
- Prefer composition over mode flags. If branches represent different workflows or shapes, split components.
- Move pure helpers outside the component. If extracted markup grows its own branches, mapping, or state, make it a named component or hook.
- Keep public APIs narrow. Resolve impossible states at the boundary and let the rest of the tree trust the types.

## Hooks, State, And Encapsulation

- Once a concern has related state, handlers, derived values, and effects, encapsulate it in a custom hook.
- Custom hooks should expose a small intentional API. Return the operations the UI needs, not an implementation dump.
- Component bodies should read like orchestration: get data, call domain hooks, render UI.
- Resolve defaults and fallback chains at the boundary instead of scattering them through the tree.
- Keep state minimal. Derive what you can during render.
- Keep state close to where it is used. Lift it only when multiple consumers need the same source of truth.
- Use reducers when behavior is driven by explicit transitions or many related events.
- Reach for external client-state libraries only when local state, context, and reducers no longer model the problem cleanly.
- Treat encapsulation as a readability tool. Do not hide domain logic so aggressively that testing and reasoning get harder.

## Effects And Synchronization

- Use `useEffect` only for synchronization with systems outside React: subscriptions, timers, browser APIs, analytics, storage, URL state, network lifecycles, or third-party widgets.
- Do not use effects to mirror props into state, derive render data, or handle work that belongs in an event handler.
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

- Avoid nested ternaries. Use early returns, named variables, or split components when conditional rendering stops being obvious.
- Avoid accidental `0` or empty-string rendering. When the left side of `&&` is not already boolean, coerce it or use a ternary.
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
