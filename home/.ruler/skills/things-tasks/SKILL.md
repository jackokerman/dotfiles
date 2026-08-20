---
name: things-tasks
description: Manage local tasks in Things 3 on macOS. Use when a local Things database needs task capture, listing, updates, completion, deletion, or Inbox triage.
---

# Things Tasks

## Workflow

Use the bundled JXA helper through Things' supported macOS automation surface:

```bash
osascript -l JavaScript "$HOME/.codex/skills/things-tasks/scripts/things-tasks.js" status
osascript -l JavaScript "$HOME/.codex/skills/things-tasks/scripts/things-tasks.js" snapshot
```

Treat the local Things database as work-only. Use Things' built-in Inbox, Anytime, and Someday lists as task state; do not recreate them as areas, projects, tags, or custom lists. Use projects for multi-step outcomes and tags only for real categories.

An explicit request to capture one work task authorizes `task create`. Default ambiguous captures to Inbox. Inspect the current snapshot before inferring another state, project, or relative priority.

## Commands

```bash
things_script="$HOME/.codex/skills/things-tasks/scripts/things-tasks.js"
osascript -l JavaScript "$things_script" snapshot
osascript -l JavaScript "$things_script" task get --id <id>
osascript -l JavaScript "$things_script" task create --state inbox --title <title> [--project-id <id>] [--notes <text>] [--start <YYYY-MM-DD>] [--due <YYYY-MM-DD>] [--tag <name> ...]
osascript -l JavaScript "$things_script" task update --id <id> [--title <title>] [--notes <text>] [--state inbox|anytime|someday] [--start <YYYY-MM-DD>] [--due <YYYY-MM-DD>] [--tag <name> ...]
osascript -l JavaScript "$things_script" task complete --id <id>
osascript -l JavaScript "$things_script" task delete --id <id>
osascript -l JavaScript "$things_script" project create --state anytime --title <title> [--notes <text>] [--tag <name> ...]
```

The helper also supports `areas`, `projects`, `tags`, `project get`, `project complete`, and `project delete`. Run it without arguments for full usage.

## Mutation Safety

- Never enable Things Cloud or read Things' private database. Use the local app and its automation dictionary.
- Resolve task IDs through `snapshot` or `task get`; do not select a mutation target by title alone.
- Require preview or approval before bulk, heuristic, or subjective changes. The helper intentionally exposes only single-task mutations.
- Delete only on an explicit request. Completion is not deletion.
- Do not put personal tasks in this Things database.
