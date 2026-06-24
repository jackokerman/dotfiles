# Audit Details

## Tool Adoption And Helper Extraction

For agent/tooling workflow adoption plans, look for repeated clarification around off-the-shelf versus custom structure, artifact ownership, global versus repo-local install scope, multi-machine support, opt-in and rollback behavior, day-to-day commands, and concrete verification.

For helper extraction or new public-repo plans, explicitly settle publication privacy, reachable Git history, install/update ownership, dirty-worktree handling for setup commands, rollback, and downstream rollout before implementation.

Before treating a tool-adoption plan as settled, verify tool availability, provisioning source, and package-manager ownership across each relevant machine class.

Treat package-manager cleanup, prune, uninstall, and sync modes that remove untracked tools as destructive. Before running them, inspect local skip env vars, later dotty-chain ownership, version-manager shims, and existing tool paths; prefer install-only repair unless removal was explicitly requested.

Treat those as planning-quality friction, not just implementation details.

When a workflow already has a tracked helper or client, prefer extending that helper and its tests over teaching Codex more ad hoc fallback commands. Treat raw API probes and runtime bundle inspection as last-resort discovery steps, then capture the confirmed contract back into the helper immediately.

When a repo-local helper grows its own runtime, dependency, verification, or release-cadence needs, evaluate extracting it into a standalone repo or package instead of continuing to expand dotfiles. Favor extraction when the helper is likely to back multiple surfaces such as a CLI, Raycast extension, or other automation entrypoints.

## Measurement Ladder

- Light: static `plugin-eval analyze` and `plugin-eval explain-budget` reports.
- Medium: define two or three pressure scenarios that should pass after the steering change and fail or require correction before it.
- Heavy: initialize and run `plugin-eval` benchmarks only with explicit approval, because they create `.plugin-eval/` artifacts and run real Codex sessions.
- When comparing alternatives, prefer blind before/after comparison and keep the simpler version if outcomes are equivalent.

## Transcript Lookup

Default to the current visible session. Do not read stored Codex sessions unless the user explicitly asks for previous, latest, or historical session context.

When explicit lookup is useful, run the tracked transcript helper:

```bash
codex-session-snippets --latest
codex-session-snippets --thread <thread-id> --query "why did you"
```

Use helper output as evidence, not as a replacement for judgment. Pull only the relevant snippets into context and avoid dumping full transcripts.

## Good Updates

- Add one sentence to a workflow skill after the same correction happened twice.
- Add a workflow-adoption checklist when planning repeatedly missed install scope, artifact ownership, reversibility, or day-to-day usage questions before implementation.
- Move a generic preference from an overlay into the base dotfiles repo when it is reusable outside work.
- Add a short routing rule when agents repeatedly edit generated `~/.codex` state instead of tracked sources.
- Split a large skill by moving examples or detailed procedure into a reference file when `plugin-eval` shows excessive invoke budget and the detail is not needed on every use.
- Recommend extracting a helper from dotfiles when its tests, dependencies, or release needs create repo-wide drag that is unrelated to most dotfiles changes.
- Add pressure scenarios before changing a high-impact skill whose purpose is behavioral compliance rather than static reference lookup.
- Decline to edit config when the correction is specific to one task or already covered by existing instructions.

## Response Shape

For config-improvement analysis, use this shape:

1. Friction observed.
2. Durable rule, if any.
3. Target location.
4. Proposed edit or applied change.
5. Validation and follow-up workflow.
6. Tool-use audit and token-saving opportunities.
