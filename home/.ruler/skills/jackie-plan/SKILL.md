---
name: jackie-plan
description: Use when saving, capturing, resuming, checkpointing, listing, or updating durable plans and follow-ups for coding-agent work.
---

# Jackie Plan

Use `jp` for durable plan memory. Do not hand-create or hand-edit Jackie Plan
artifacts.

## Automatic Triggers

Use this skill when the user asks to save, capture, track, resume, list,
checkpoint, pause, or complete a plan. Also use it when a follow-up emerges
during work and should be persisted for a later session.

## Workflow

- Create a new plan with `jp start --title "..." --body -`.
- Capture a follow-up with `jp capture --title "..." --source-plan <id> --body -`.
- Resume context with `jp show <id>` or `jp show <id> --json`.
- Save a compact handoff with `jp checkpoint --plan <id> --summary -`.
- Add verbose support material with `jp context add --plan <id> --body -`.
- Use `jp list --status inbox,active` to find open work.
- If routing is ambiguous, ask the user before writing.

`PLAN.md` is the canonical human-facing document. `SUMMARY.md` is the compact
resume handoff. `CONTEXT.md` is optional support material; anything required to
continue must also be reflected in `PLAN.md` or `SUMMARY.md`.
