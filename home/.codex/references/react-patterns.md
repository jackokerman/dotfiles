# React Patterns

Use this reference for clearly React or frontend work. These are opinionated defaults, not laws. If the local codebase has a stronger documented pattern, follow it.

## Component Boundaries
- Keep leaf components boring. Parents decide what to render; children render resolved props.
- Prefer composition over mode flags. If branches represent different shapes or workflows, split components.
- Keep components small enough that state, rendering, and event flow fit in one read.
- Name components and hooks by domain intent, not by implementation details.

## Encapsulation
- Once a concern has related state, handlers, and effects, encapsulate it in a custom hook.
- Custom hooks should expose a small intentional API. Favor domain names over bags of unrelated primitives.
- Component bodies should read like wiring: get data, call domain hooks, render UI.
- Resolve defaults and fallback chains at the boundary instead of scattering them through the tree.

## Context
- Use context for shared subtree state, not as a default answer to prop drilling.
- Scope providers as narrowly as possible.
- Export a provider and a `useX` hook. Callers should not touch the raw context object.
- Prefer no default context value. Throw a clear error when the hook is used outside its provider.
- Split contexts by responsibility or change frequency. Avoid omnibus app-wide context objects.

## State And Effects
- Keep state minimal. Derive anything you can during render.
- Use reducers when the behavior is driven by explicit transitions or many related events.
- Use `useEffect` only for synchronization with systems outside React: subscriptions, timers, browser APIs, analytics, storage, URL state, network lifecycles, or third-party widgets.
- Do not use effects to mirror props into state, derive render data, or handle work that belongs in an event handler.
- Before adding an effect, check whether the logic belongs in render, a handler, a reducer, or a key-based reset.

## Memoization
- Do not reach for `useMemo` or `useCallback` by default.
- Memoize only for measured expensive work, stable identity requirements, or an established local convention.
- Prefer simpler code over speculative rerender optimization.

## Structure And APIs
- Move pure helpers outside components. Keep closures only when they truly need component state.
- Pass objects when values form one domain concept. Avoid long primitive prop lists.
- Keep public APIs narrow. Fewer inputs usually mean fewer invalid states.
- Resolve impossible states at the boundary and let the rest of the tree trust the types.
- Avoid nested ternaries. Use early returns or split components when conditional rendering stops being obvious.

## Testing
- Test behavior and user outcomes, not implementation details.
- Prefer a few meaningful tests over snapshot-heavy or mock-heavy coverage.
- Cover state transitions, edge cases, and failure paths when behavior changes.
