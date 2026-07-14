---
name: godspeed-tasks
description: Generic Godspeed list and label discovery, inbox triage, and API-backed task organization for a mirrored GTD setup with work and personal folders. Use when Codex needs to inspect Godspeed lists, summarize inbox or active tasks, or apply explicit task updates through the Godspeed API without tracking personal taxonomy in the repo.
---

# Godspeed Tasks

## Overview

Use this skill for Godspeed work under the mirrored `🏢 Work` and `🏡 Personal` folders. The public repo owns only the generic mechanics and organization model:

- folders are top-level contexts,
- GTD lists are state,
- labels are categories or areas,
- projects stay in task and subtask structure.

Do not track personal category names, keyword taxonomies, or smart-list definitions in this repo. Discover labels and categories at runtime through the API and the current prompt.

## Authentication

Prefer Bun env-file injection over sourcing shell startup files in one-off commands. Keep machine-local Godspeed credentials in a dedicated dotenv file such as `~/.config/godspeed/tasks.env`, then run the helper with:

```bash
bun --env-file "$HOME/.config/godspeed/tasks.env" "$(command -v godspeed-gtd)" lists
```

Falling back to an already-exported `GODSPEED_API_TOKEN` is fine. Do not source `~/.zshenv.local` unless you are fixing auth plumbing itself.

## Core Commands

Use the installed `godspeed-gtd` workflow helper from the private `godspeed-js` checkout. Keep `godspeed` for generic API diagnostics and exact resource operations.

```bash
godspeed-gtd lists
godspeed-gtd labels
godspeed-gtd inbox --scope personal
godspeed-gtd snapshot --scope work
```

For explicit objective writes:

```bash
godspeed-gtd task create --folder personal --state next-actions --title "Review the migration follow-up" --label server --due 2026-06-23
godspeed-gtd task complete --task-id <task-id>
godspeed-gtd label ensure --name server
godspeed-gtd label add --name server --task-id <task-id>
godspeed-gtd label remove --name server --task-id <task-id>
```

For heuristic or bulk categorization:

```bash
godspeed-gtd bulk-label preview --label server --scope personal --contains docker --contains torrent
godspeed-gtd bulk-label apply --label server --task-id <task-id> --task-id <task-id>
```

For smart-list planning:

```bash
godspeed-gtd smart-list plan --folder personal --label server
godspeed-gtd smart-list ensure --folder personal --label server --name "Server"
```

Smart-list verification note:
- Do not assume `GET /tasks?list_id=<smart-list-id>` reflects smart-list membership. In this setup the API can return an empty task array even for existing smart lists like `Today`. Verify smart-list creation from `/lists`, and treat in-app rendering as the reliable membership check unless the API behavior changes.

## Discovery Rules

- Ignore the top-level default Godspeed Inbox. Use the child `📥 Inbox` lists under `🏢 Work` and `🏡 Personal`.
- Keep work and personal separate unless the user explicitly asks for cross-folder organization.
- Resolve folder children dynamically by name and type:
  - `📥 Inbox`
  - `⚡ Next Actions`
  - `🌱 Someday`
- Use the API as the write surface. Do not mutate local Godspeed storage directly.

## Mutation Rules

- Direct writes are fine for explicit, objective operations on explicit targets.
- For explicit follow-up capture, prefer `godspeed-gtd task create` over ad hoc raw API calls.
- For explicit completion, use `godspeed-gtd task complete`. Godspeed task completion uses the `/todo_items/bulk_update` transport; direct `/tasks/<id>` patches can return success while leaving the task incomplete.
- When capturing a new follow-up task and its priority is unclear, prefer `inbox` over guessing `next-actions` or `someday`. Let the user triage it during review.
- When a needed Godspeed workflow is missing from the helper, extend the private `godspeed-js` checkout and its tests before reaching for ad hoc Python or Node scripts.
- Prefer direct API observation through the tracked helper or Bun probes over reverse engineering the desktop app bundle. Treat local bundle inspection as a last resort for undocumented behavior, and capture any confirmed contract back into the helper immediately.
- Require a preview or approval step before bulk, heuristic, or subjective categorization changes.
- When a category label already exists, discover it dynamically. When it does not exist and the user explicitly asked for it, create it through the API.
- Use `--due YYYY-MM-DD` for date-only reminders. The helper stores that as a timeless due date.
- Keep runtime criteria in the current session. Do not persist personal label names or matching rules into tracked repo config.

## Inbox Triage

For inbox-review requests, keep using the normalized inbox snapshot and recommend exactly one outcome per task:

- `candidate_for_completion`
- `move_to_next_actions`
- `move_to_someday`
- `stay_in_inbox`

Use `candidate_for_completion` only when strong local evidence suggests the task is already done, superseded, or no longer actionable.

## Local Evidence Pass

- Run local evidence gathering only when the helper marks a task as `localEvidenceEligible`.
- Keep the pass quick and non-mutating. Preferred commands:
  - `rg`
  - `rg --files`
  - `find`
  - `ls`
  - `test -e`
  - `sed -n`
  - `git status --short`
  - `git log --oneline`
  - `git grep`
- Do not do broad web research as part of routine inbox triage.
- If the evidence pass is inconclusive, fall back to normal triage and do not use `candidate_for_completion`.
