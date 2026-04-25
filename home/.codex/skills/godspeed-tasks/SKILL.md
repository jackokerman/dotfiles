---
name: godspeed-tasks
description: Read-only Godspeed inbox triage and list discovery for a mirrored GTD setup with work and personal folders. Use when Codex needs to inspect Godspeed lists, summarize the work or personal inbox, recommend moving items to next actions or someday, or surface candidate-for-completion tasks based on quick local evidence.
---

# Godspeed Tasks

## Overview

Use this skill to inspect Godspeed and triage the child inboxes under `🏢 Work` and `🏡 Personal`. Keep the workflow read-only in v1: do not call Godspeed write endpoints and do not mutate tracked files while investigating whether a task is already done.

## Workflow

1. Load the Godspeed token from `~/.codex/env.local` if the shell does not already have it:

```bash
source "$HOME/.codex/env.local"
```

2. Discover the mirrored list structure before triaging anything:

```bash
bun run scripts/godspeed-tasks.ts discover-lists
```

3. Fetch a normalized inbox snapshot for the requested scope:

```bash
bun run scripts/godspeed-tasks.ts inbox-snapshot --scope work
bun run scripts/godspeed-tasks.ts inbox-snapshot --scope personal
bun run scripts/godspeed-tasks.ts inbox-snapshot --scope all
```

4. Recommend exactly one outcome for each inbox task:
- `candidate_for_completion`
- `move_to_next_actions`
- `move_to_someday`
- `stay_in_inbox`

## Discovery Rules

- Ignore the top-level default Godspeed Inbox. Only use the child `📥 Inbox` lists under `🏢 Work` and `🏡 Personal`.
- Keep work and personal separate. Do not recommend cross-folder moves in v1.
- Resolve these child lists dynamically by name and type under each folder:
  - `📥 Inbox`
  - `⚡ Next Actions`
  - `🌱 Someday`
- Treat `Today` as out of scope for v1 triage, even if a smart list exists.

## Triage Rules

- Use `candidate_for_completion` only when strong local evidence suggests the task is already done, superseded, or no longer actionable.
- Use `move_to_next_actions` for concrete, active tasks that belong in the current working set.
- Use `move_to_someday` for valid tasks that are not active enough to stay in the working set.
- Use `stay_in_inbox` for ambiguous, compound, or underspecified items, and for anything that still needs clarification.
- Prefer `stay_in_inbox` over a weak or speculative recommendation.

## Local Evidence Pass

- Run local evidence gathering only when the helper marks a task as `localEvidenceEligible`.
- Keep the evidence pass quick and non-mutating. Preferred commands:
  - `rg`
  - `rg --files`
  - `find`
  - `ls`
  - `test -e`
  - `sed -n`
  - `git status --short`
  - `git log --oneline`
  - `git grep`
- Do not do broad web research as part of inbox triage.
- Do not edit files, call Godspeed write endpoints, or run open-ended investigation loops.
- If the evidence pass is inconclusive, fall back to normal triage and do not use `candidate_for_completion`.

## Output Shape

- Split the report into `Work` and `Personal`.
- Within each folder, use these sections in this order:
  - `Candidate for Completion`
  - `Move to Next Actions`
  - `Move to Someday`
  - `Stay in Inbox`
- Include for each task:
  - title
  - Godspeed task ID
  - one short recommendation
  - one short rationale
  - an evidence note only if a local evidence pass actually ran

## Limits

- Keep v1 read-only.
- Do not suggest due dates, start dates, metadata edits, or agent-execution tags in v1.
- Do not mark tasks complete automatically. If the user wants actual writes later, treat that as a separate workflow.
