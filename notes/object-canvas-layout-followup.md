# ObjectCanvas layout follow-up

Context: a stacked work PR simplified the `ObjectCanvasLayout` content panel
enough to fix the immediate `ErrorBoundary` UUID/lint issue, but the layout
still has accumulated mobile, compact, and desktop branching that should be
cleaned up separately.

## Current shape

- `isMobile` and `isCompact` are separate booleans, but they really encode one
  layout mode.
- Mobile has a meaningfully different UX: tabs, mobile action bar, no desktop
  header, and a direct `ObjectPreview`.
- Compact and desktop both need the `ObjectCanvasContentPanel`; they are
  mutually exclusive branches today, so the panel is not duplicated at runtime,
  but the JSX placement is duplicated.
- Compact and mobile both have a sliding nav/form edit surface, but their
  surrounding chrome differs.

## Follow-up direction

1. Replace the parallel layout booleans with an explicit mode:

   ```ts
   type ObjectCanvasLayoutMode = 'mobile' | 'compact' | 'desktop';
   ```

2. Derive intentful booleans from that mode:

   ```ts
   const isMobileLayout = layoutMode === 'mobile';
   const shouldRenderContentPanel =
     layoutMode !== 'mobile' &&
     panelLayout.activePanels.some((panel) => panel.key === 'preview');
   ```

3. Render `ObjectCanvasContentPanel` once for the non-mobile modes instead of
   once in the compact branch and once in the desktop branch.

4. After the mode split is clear, consider extracting the bigger pieces:

   - `MobileCanvasLayout`
   - `CompactEditPanel`
   - `DesktopEditPanels`
   - possibly a shared sliding nav/form shell for the mobile and compact edit
     surfaces

## Caution

Avoid starting with early returns in `ObjectCanvasLayout` unless the shared
shell is extracted first. The current shared shell includes the dialog wrapper,
`canvasRef`, debug controls, `Form`, `ObjectCanvasCacheProvider`,
`ActionsProvider`, and the non-mobile header. Early returns before extracting
that shell would likely reintroduce duplication.
