---
name: css-layout
description: Generic frontend styling and layout guidance for CSS, style objects, utility classes, and layout props. Use when working on spacing, sizing, positioning, overflow, stacking, responsive layout, or visual containment where the problem is not framework-specific.
---

# CSS Layout

Use this skill for generic styling and layout work. Keep framework-specific rendering, state, and component guidance in the matching framework skill.

## Layout And Sizing

- Prefer DOM structure, flow layout, and alignment primitives before reaching for absolute positioning.
- Prefer content-driven sizing and min/max constraints over fixed `width` and `height`.
- Use fixed dimensions only for explicit hit targets, icon frames, media crops, or externally specified sizes.
- When fixed sizing is needed, start with the smallest plausible set of properties. Do not add matching `min*`, `max*`, or flex constraints unless they are individually necessary for the observed behavior.
- Prefer gap, padding, and alignment primitives over margin choreography when the surrounding system supports them.
- Check narrow widths before freezing a layout around desktop assumptions.

## Stacking And Overlays

- Prefer DOM order and local stacking contexts over ad hoc `z-index`.
- Before adding `z-index`, identify which ancestor already establishes a stacking context and whether sibling order already solves the problem.
- When `z-index` is necessary, pair it with an intentional layer boundary such as `isolation: isolate` or an existing local stacking context. Keep the scope local.
- Do not introduce high or magic `z-index` values without tracing the competing layers first.

## Overflow And Containment

- Treat `overflow: hidden` as behavior, not decoration. Check clipping, focus rings, sticky elements, and menus before using it.
- Use containment and clipping only when they are part of the layout contract.
- If a visual effect needs to escape a clipped parent, prefer fixing the parent structure over escalating `z-index`.

## Workflow

- Read the local component and neighboring styles first; existing layout conventions win.
- Preserve existing base styles when possible and layer targeted overrides on top. Prefer changing only the few properties that affect the behavior over rewriting or forking a large style object.
- Add layout properties incrementally and reason about what each one changes. Avoid a shotgun bundle of likely fixes; keep only the properties that prove necessary.
- Prefer the smallest structural change that removes the need for a layer hack.
- Keep generic styling rules here rather than piling them into framework-specific skills.
