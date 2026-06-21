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

Load `GODSPEED_API_TOKEN` from the shell when needed. This dotfiles setup keeps machine-local env vars in `~/.zshenv.local`:

```bash
[[ -f "$HOME/.zshenv.local" ]] && source "$HOME/.zshenv.local"
```

## Core Commands

Use the tracked helper directly:

```bash
bun home/.ruler/skills/godspeed-tasks/scripts/godspeed-tasks.ts discover-lists
bun home/.ruler/skills/godspeed-tasks/scripts/godspeed-tasks.ts discover-labels
bun home/.ruler/skills/godspeed-tasks/scripts/godspeed-tasks.ts inbox-snapshot --scope personal
bun home/.ruler/skills/godspeed-tasks/scripts/godspeed-tasks.ts task-snapshot --scope work
```

For explicit objective writes:

```bash
bun home/.ruler/skills/godspeed-tasks/scripts/godspeed-tasks.ts ensure-label --name server
bun home/.ruler/skills/godspeed-tasks/scripts/godspeed-tasks.ts set-task-labels --add-label server --task-id <task-id>
bun home/.ruler/skills/godspeed-tasks/scripts/godspeed-tasks.ts remove-task-labels --remove-label server --task-id <task-id>
```

For heuristic or bulk categorization:

```bash
bun home/.ruler/skills/godspeed-tasks/scripts/godspeed-tasks.ts preview-bulk-labeling --label server --scope personal --contains docker --contains torrent
bun home/.ruler/skills/godspeed-tasks/scripts/godspeed-tasks.ts apply-bulk-labeling --label server --task-id <task-id> --task-id <task-id>
```

For smart-list planning:

```bash
bun home/.ruler/skills/godspeed-tasks/scripts/godspeed-tasks.ts smart-list-plan --folder personal --label server
bun home/.ruler/skills/godspeed-tasks/scripts/godspeed-tasks.ts ensure-smart-list --folder personal --label server --smart-list-name "Server"
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
- Require a preview or approval step before bulk, heuristic, or subjective categorization changes.
- When a category label already exists, discover it dynamically. When it does not exist and the user explicitly asked for it, create it through the API.
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
