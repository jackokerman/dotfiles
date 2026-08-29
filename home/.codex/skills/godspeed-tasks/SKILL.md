---
name: godspeed-tasks
description: Manage Godspeed tasks with flat GTD. Use when capturing, finding, prioritizing, labeling, completing, or triaging tasks, lists, smart lists, or the native Inbox.
---

# Godspeed Tasks

## Workflow

Use `godspeed-gtd` for GTD workflows and `godspeed` for exact resource operations or API diagnostics. Run `godspeed-gtd --help` for syntax. Invoke the CLI directly; it reads the shared per-machine credential file.

Use `GODSPEED_API_TOKEN` only as an explicit automation or debugging override. If credentials are missing, direct the user to `godspeed auth login`; never start an interactive prompt or source shell startup files.

Treat GTD lists as state, labels as categories or areas, smart-list order as category priority, and task/subtask structure as projects. Resolve the one active native Inbox by `list_type: "inbox"`. Resolve active top-level Next Actions and Someday lists by canonicalized display name; resolve optional Today and category smart lists at the top level. Discover IDs at runtime and ignore archived name collisions.

For an existing-task lookup, list tasks from the active Next Actions and Someday source lists and filter titles and notes locally. Do not use `snapshot`; it is broader and can stall.

## Task Capture

- When the user supplies the GTD state and does not request a category or relative placement, run `task create` directly and verify with `task get`. Do not call `lists`, `labels`, or `snapshot`; those broad reads cannot change the result.
- For a known category or area, discover its label and matching smart list, inspect only its relevant Next Actions and Someday roots, infer state and relative priority from the supplied context, then create and position the task. Report the chosen state, position, and short rationale.
- Use `inbox` only when the category, state, or placement remains materially ambiguous.

## Priority Lookups

For category-priority requests, stay in the current repository scope but read live Godspeed state. Load [Priority order](references/priority-order.md) and return the first active root plus its GTD state.

## Mutation Safety

- Use the API through the CLI; never mutate local Godspeed storage.
- Execute explicit, objective writes on explicit targets directly. Capture ambiguous-priority tasks in `inbox` rather than guessing another state.
- Require preview or approval before bulk, heuristic, subjective, or inferred categorization. The end-to-end single-task capture above is authorized by the explicit capture request; apply bulk labels only to explicit reviewed task IDs.
- Complete tasks through `godspeed-gtd task complete`, which completes and clears them by default. Use `--keep-uncleared` only when the completed task should remain visible with a strikethrough; direct task patches can report success without completing the task.
- Let the CLI manage request throttling and transient retries. Do not add sleeps, retry loops, or batch workarounds around authenticated commands.
- Discover labels at runtime. Create a missing label only when explicitly requested. Keep personal category names, matching rules, and smart-list definitions out of tracked config.
- Use `godspeed-gtd task ensure-children` to create or reconcile an ordered child set beneath an existing parent. Give each child a stable key unique within that parent, and retry the same command after interruption; do not orchestrate separate task creation and reparenting loops.
- Use `godspeed-gtd task reparent` for hierarchy corrections so the parent list and adjacent source-order boundary are derived atomically; do not combine manual cross-list moves with smart-list-visible neighbors.
- Treat `/lists`, source-list task records, and the app as the reliable smart-list verification surfaces; task queries by smart-list ID can return empty results despite valid membership.
- Extend `godspeed-js` and its tests when a workflow is missing. Prefer tracked CLI/client probes over ad hoc scripts or desktop-bundle inspection.

## Inbox Triage

For Inbox triage, load [Inbox triage](references/inbox-triage.md) and recommend exactly one outcome per task.
