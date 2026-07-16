---
name: godspeed-tasks
description: Manage Godspeed tasks through the mirrored Work/Personal GTD workflow. Use when Codex needs list or label discovery, inbox or active-task summaries, task capture or completion, labeling, smart lists, or inbox triage through godspeed-gtd.
---

# Godspeed Tasks

## Workflow

Use `godspeed-gtd` for the opinionated workflow and `godspeed` for generic API diagnostics or exact resource operations. Run `godspeed-gtd --help` for command syntax.

Prefer Bun env-file injection for machine-local credentials:

```bash
bun --env-file "$HOME/.config/godspeed/tasks.env" "$(command -v godspeed-gtd)" lists
```

An exported `GODSPEED_API_TOKEN` is also valid. Do not source shell startup files unless fixing auth plumbing.

Treat folders as contexts, GTD lists as state, labels as categories or areas, and task/subtask structure as projects. Resolve the `📥 Inbox`, `⚡ Next Actions`, and `🌱 Someday` children dynamically under `🏢 Work` and `🏡 Personal`; ignore the root Godspeed Inbox. Keep scopes separate unless the user explicitly requests both.

## Mutation Safety

- Use the API through the CLI; never mutate local Godspeed storage.
- Execute explicit, objective writes on explicit targets directly. Capture ambiguous-priority tasks in `inbox` rather than guessing another state.
- Require preview or approval before bulk, heuristic, subjective, or inferred categorization. Apply bulk labels only to explicit reviewed task IDs.
- Complete tasks through `godspeed-gtd task complete`, which completes and clears them by default. Use `--keep-uncleared` only when the completed task should remain visible with a strikethrough; direct task patches can report success without completing the task.
- Discover labels at runtime. Create a missing label only when explicitly requested. Keep personal category names, matching rules, and smart-list definitions out of tracked config.
- Treat `/lists` and the app as the reliable smart-list verification surfaces; task queries by smart-list ID can return empty results despite valid membership.
- Extend `godspeed-js` and its tests when a workflow is missing. Prefer tracked CLI/client probes over ad hoc scripts or desktop-bundle inspection.

## Inbox Triage

Use the normalized inbox snapshot and recommend exactly one outcome per task:

- `candidate_for_completion`
- `move_to_next_actions`
- `move_to_someday`
- `stay_in_inbox`

Use `candidate_for_completion` only with strong evidence that the task is done, superseded, or no longer actionable. Gather local evidence only when `localEvidenceEligible` is true. Keep checks narrow and non-mutating with tools such as `rg`, file-existence checks, and scoped Git status or history. Do not do broad web research; if evidence is inconclusive, use a normal non-completion outcome.
