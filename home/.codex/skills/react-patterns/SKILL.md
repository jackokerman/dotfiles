---
name: react-patterns
description: Use for React or frontend work that needs guidance on component boundaries, hooks, context, rendering, testing, and modern React defaults.
---

# React Patterns

Use this skill for clearly React or frontend work. These are opinionated defaults, not laws. Package-local docs, neighboring files, and stronger framework conventions win.

## Workflow

- Start by reading nearby components, hooks, tests, and package docs before applying generic guidance.
- Prefer the repo's established import style. When path aliases or package entrypoints exist, use them instead of deep relative traversals, but do not churn unrelated imports just to normalize style.
- Prefer refactors that reduce invalid states, branching, and incidental complexity over clever abstractions.
- Name components, hooks, and helpers by domain intent. Prefer short, direct names and avoid `effective`, `resolved`, `computed`, and `final` unless they mark a real distinction.
- Keep the code shape consistent inside a module. Do not mix unrelated styles without a reason.

## Components And APIs

- Prefer function components and named function declarations for exported components and hooks.
- Destructure props in the component signature unless keeping the object whole is materially clearer. Put default values in the signature when a default belongs to the component boundary; do not use `defaultProps` on function components.
- Treat high prop count as a design smell. Pass one typed domain object when several values travel together, but do not hide unrelated values in a generic options bag.
- Keep leaf components boring and usually stateless. Parents decide what to render; children render resolved props and emit events.
- Prefer composition over mode flags or internal branching. If branches represent different workflows or shapes, split components.
- Move pure helpers outside the component. If extracted markup grows its own branches, mapping, or state, make it a named component or hook.
- Use configuration data for repeated navigation, filters, menus, tabs, or other near-identical UI instead of hardcoding markup in multiple places.
- Extract repeated JSX or complex list rendering into a named component when it clarifies structure. Keep a mapping inline only when rendering that list is the component's main responsibility, and do not add wrappers that only rename markup.
- Split components by responsibility, not line count. If loops, branches, or auxiliary state make the main render path hard to scan, extract a named component, helper, or hook.
- Keep public APIs narrow. Resolve impossible states at the boundary and let the rest of the tree trust the types instead of adding defensive handling deeper in the tree.

## Hooks, State, And Encapsulation

- Once a concern has related state, handlers, derived values, and effects, encapsulate it in a custom hook.
- Do not wait for reuse before extracting a hook. Single-use hooks are valid when they keep a component focused and make setup logic easier to scan.
- A concern does not need local state to justify a hook. If a component gathers related external hooks, derived values, and handlers for one responsibility, extract a small local hook when that makes the component read more like orchestration.
- Prefer a small colocated `useX` hook over letting one component accumulate a long setup section where everything is tied together. When setup wiring starts competing with the render path, split by concern.
- Custom hooks should expose a small intentional API. Return the operations the UI needs, not an implementation dump.
- Prefer plain helper functions for pure branching or data-shaping logic. Reach for a custom hook when the extraction composes hooks, state, refs, or effects.
- Component bodies should read like orchestration: get data, call domain hooks, render UI.
- Keep encapsulation local first. Start with a hook beside the component or in the same file, and only promote it to shared code when reuse or module boundaries justify it.
- Resolve defaults and fallback chains at the boundary instead of scattering them through the tree.
- Keep state minimal. Derive what you can during render.
- Keep state close to where it is used. Lift it only when multiple consumers need the same source of truth.
- Let the nearest responsible component own validation, mutation flow, and form orchestration. Reusable inputs, buttons, and other leaf primitives should stay dumb.
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
- Use a short JSX comment only when a branch or block encodes non-obvious product, domain, or accessibility constraints. Do not narrate straightforward markup.
- In component files, prefer the main exported component before hoisted helper functions.
- Below the main component, prefer top-down ordering from higher-level local hooks to the lower-level helpers they call.
- Use error boundaries at route or independently useful widget seams when one failing surface should not blank the rest of the UI. Do not wrap every component mechanically.
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
